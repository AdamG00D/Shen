package com.adam.shen.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.util.Date

class PgpTest {
    private val pgp = Pgp()

    private fun key(algo: KeyAlgo = KeyAlgo.CV25519, pass: String? = "correct horse", uid: String = "Alice <alice@example.org>") =
        pgp.generate(uid, pass, algo, Date(System.currentTimeMillis() + 365L * 24 * 3600 * 1000))

    private fun expectErr(code: Err, block: () -> Unit) {
        try {
            block()
            fail("expected $code")
        } catch (e: CoreError) {
            assertEquals(code, e.code)
        }
    }

    private fun encrypt(data: ByteArray, to: List<org.bouncycastle.openpgp.api.OpenPGPCertificate>, signer: org.bouncycastle.openpgp.api.OpenPGPKey? = null, pass: String? = null, armor: Boolean = true): ByteArray {
        val out = ByteArrayOutputStream()
        pgp.encrypt(ByteArrayInputStream(data), out, to, signer, pass, armor, null)
        return out.toByteArray()
    }

    @Test
    fun generatesUsableKeysOfEveryKind() {
        for (algo in listOf(KeyAlgo.CV25519, KeyAlgo.V6)) {
            val k = key(algo)
            val s = pgp.summary(k)
            assertEquals(true, s["secret"])
            assertEquals("protected $algo", true, s["protected"])
            assertEquals("canEncrypt $algo", true, s["canEncrypt"])
            assertEquals("canSign $algo", true, s["canSign"])
            assertEquals(if (algo == KeyAlgo.V6) 6 else 4, s["version"])
            assertEquals("Alice <alice@example.org>", s["primaryUid"])
            assertNotNull(s["expires"])
            assertEquals(3, (s["subkeys"] as List<*>).size)
        }
    }

    @Test
    fun everySubkeyHasItsOwnSalt() {
        // كل مفتاح فرعي محمي بـ salt لوحده (شوف Pgp.generate)
        for (algo in KeyAlgo.values()) {
            if (algo != KeyAlgo.CV25519) continue // RSA بطيء في التيست، وv6 بيستخدم AEAD
            val salts = key(algo).pgpSecretKeyRing.secretKeys.asSequence().map { Bytes.hex(it.s2K.iv) }.toList()
            assertEquals("$algo", salts.size, salts.toSet().size)
        }
    }

    @Test
    fun armorRoundTripAndPublicPart() {
        val k = key()
        val parsed = pgp.parseKey(pgp.armor(k).toByteArray())
        assertEquals(pgp.fingerprint(k), pgp.fingerprint(parsed))
        val pub = pgp.parseCert(pgp.armor(pgp.publicPart(k)).toByteArray())
        assertFalse(pub.isSecretKey)
        assertFalse(pgp.armor(pgp.publicPart(k)).contains("PRIVATE"))
    }

    @Test
    fun garbageIsBadData() {
        expectErr(Err.BAD_DATA) { pgp.parse("hello".toByteArray()) }
        expectErr(Err.BAD_DATA) { pgp.parse(ByteArray(0)) }
        expectErr(Err.BAD_DATA) { pgp.parse("-----BEGIN PGP PUBLIC KEY BLOCK-----\n\nAAAA\n-----END PGP PUBLIC KEY BLOCK-----".toByteArray()) }
    }

    @Test
    fun encryptDecryptWithSignature() {
        val alice = key()
        val bob = key(uid = "Bob <bob@example.org>", pass = "bob pass 123")
        val msg = "سلام يا بوب — secret".toByteArray()
        val ct = encrypt(msg, listOf(pgp.publicPart(bob)), alice, "correct horse")
        assertTrue(String(ct).startsWith("-----BEGIN PGP MESSAGE-----"))

        val info = pgp.inspect(ByteArrayInputStream(ct))
        assertTrue(info.encrypted)
        assertFalse(info.passwordEncrypted)

        val out = ByteArrayOutputStream()
        val r = pgp.decrypt(ByteArrayInputStream(ct), out, listOf(bob to "bob pass 123"), null, listOf(pgp.publicPart(alice)))
        assertTrue(msg.contentEquals(out.toByteArray()))
        assertEquals(1, r.signatures.size)
        assertEquals(SigStatus.GOOD, r.signatures[0].status)
        assertEquals(pgp.fingerprint(alice), r.signatures[0].fp)
        assertEquals(pgp.fingerprint(bob), r.decryptedWith)
    }

    @Test
    fun signatureFromUnknownKeyIsReportedAsUnknown() {
        val alice = key()
        val bob = key(pass = null)
        val ct = encrypt("hi".toByteArray(), listOf(pgp.publicPart(bob)), alice, "correct horse")
        val r = pgp.decrypt(ByteArrayInputStream(ct), ByteArrayOutputStream(), listOf(bob to null), null, emptyList())
        assertEquals(SigStatus.UNKNOWN_KEY, r.signatures.single().status)
    }

    @Test
    fun wrongKeyOrPassphraseFails() {
        val alice = key()
        val eve = key(pass = "eve's pass")
        val ct = encrypt("x".toByteArray(), listOf(pgp.publicPart(alice)))
        expectErr(Err.NO_KEY) { pgp.decrypt(ByteArrayInputStream(ct), ByteArrayOutputStream(), listOf(eve to "eve's pass"), null, emptyList()) }
        expectErr(Err.WRONG_PASSWORD) { pgp.decrypt(ByteArrayInputStream(ct), ByteArrayOutputStream(), listOf(alice to "nope"), null, emptyList()) }
    }

    @Test
    fun tamperedMessageIsRejected() {
        val alice = key(pass = null)
        val ct = encrypt(ByteArray(4000) { 7 }, listOf(pgp.publicPart(alice)), armor = false)
        // نقلب بايت في نص البيانات المتشفّرة
        val bad = ct.copyOf().also { it[it.size - 40] = (it[it.size - 40].toInt() xor 0x55).toByte() }
        try {
            pgp.decrypt(ByteArrayInputStream(bad), ByteArrayOutputStream(), listOf(alice to null), null, emptyList())
            fail("tampered message accepted")
        } catch (e: CoreError) {
            assertTrue(e.code == Err.INTEGRITY || e.code == Err.BAD_DATA)
        }
    }

    @Test
    fun allSignModesVerify() {
        val alice = key()
        val text = "line one\nline two\n".toByteArray()
        for (mode in SignMode.values()) {
            val out = ByteArrayOutputStream()
            pgp.sign(ByteArrayInputStream(text), out, alice, "correct horse", mode, armor = true)
            val sig = out.toByteArray()
            val res = if (mode == SignMode.DETACHED) {
                pgp.verify(ByteArrayInputStream(text), null, ByteArrayInputStream(sig), listOf(pgp.publicPart(alice)))
            } else {
                val plain = ByteArrayOutputStream()
                val r = pgp.verify(ByteArrayInputStream(sig), plain, null, listOf(pgp.publicPart(alice)))
                assertTrue("mode $mode", String(plain.toByteArray()).contains("line two"))
                r
            }
            assertEquals("mode $mode", SigStatus.GOOD, res.single().status)
        }
    }

    @Test
    fun modifiedDetachedSignatureIsBad() {
        val alice = key()
        val out = ByteArrayOutputStream()
        pgp.sign(ByteArrayInputStream("original".toByteArray()), out, alice, "correct horse", SignMode.DETACHED, true)
        val res = pgp.verify(ByteArrayInputStream("modified".toByteArray()), null, ByteArrayInputStream(out.toByteArray()), listOf(alice))
        assertEquals(SigStatus.BAD, res.single().status)
    }

    @Test
    fun passwordEncryptionModernAndCompat() {
        for (modern in listOf(true, false)) {
            val out = ByteArrayOutputStream()
            pgp.encryptWithPassword(ByteArrayInputStream("backup".toByteArray()), out, "pässwörd 123", armor = false, modern = modern)
            val info = pgp.inspect(ByteArrayInputStream(out.toByteArray()))
            assertTrue(info.passwordEncrypted)
            val plain = ByteArrayOutputStream()
            pgp.decrypt(ByteArrayInputStream(out.toByteArray()), plain, emptyList(), "pässwörd 123", emptyList())
            assertEquals("backup", String(plain.toByteArray()))
            // كلمة السر الغلط بتطلّع مفتاح عشوائي — نجرّب كتير عشان الحالات النادرة تظهر
            repeat(40) { i ->
                expectErr(Err.WRONG_PASSWORD) {
                    pgp.decrypt(ByteArrayInputStream(out.toByteArray()), ByteArrayOutputStream(), emptyList(), "wrong $i", emptyList())
                }
            }
        }
    }

    @Test
    fun keyEditing() {
        var k = key()
        expectErr(Err.WRONG_PASSWORD) { pgp.addUserId(k, "bad", "x <x@x>") }
        k = pgp.addUserId(k, "correct horse", "Alice Work <alice@work.example>")
        assertEquals(2, (pgp.summary(k)["uids"] as List<*>).size)

        k = pgp.setExpiry(k, "correct horse", null)
        assertEquals(null, pgp.summary(k)["expires"])

        k = pgp.changePassphrase(k, "correct horse", "new pass 456")
        assertFalse(pgp.checkPassphrase(k, "correct horse"))
        assertTrue(pgp.checkPassphrase(k, "new pass 456"))

        val rev = pgp.revocationCertificate(k, "new pass 456")
        val revoked = pgp.merge(pgp.publicPart(k), pgp.parseCert(rev.toByteArray()))
        assertEquals(true, pgp.summary(revoked)["revoked"])
        assertEquals(false, pgp.summary(revoked)["canEncrypt"])
        expectErr(Err.CANNOT_ENCRYPT) { encrypt("x".toByteArray(), listOf(revoked)) }
    }

    @Test
    fun certifyContact() {
        val me = key()
        val bob = pgp.publicPart(key(uid = "Bob <bob@example.org>"))
        val certified = pgp.certify(me, "correct horse", bob)
        assertEquals(pgp.fingerprint(bob), pgp.fingerprint(certified))
        assertTrue(certified.encoded.size > bob.encoded.size)
    }

    @Test
    fun decryptIntoLimitedBufferStopsBombs() {
        val alice = key(pass = null)
        // رسالة مضغوطة جاية من برا: 2 ميجا أصفار بتتضغط لكام كيلو
        val opts = org.pgpainless.encryption_signing.ProducerOptions.encrypt(
            org.pgpainless.encryption_signing.EncryptionOptions.get(pgp.api).addRecipient(pgp.publicPart(alice)),
        ).overrideCompressionAlgorithm(org.pgpainless.algorithm.CompressionAlgorithm.ZIP)
        val buf = ByteArrayOutputStream()
        pgp.api.generateMessage().onOutputStream(buf).withOptions(opts).use { it.write(ByteArray(2_000_000)) }
        val ct = buf.toByteArray()
        assertTrue("compressed", ct.size < 100_000)
        expectErr(Err.TOO_LARGE) {
            pgp.decrypt(ByteArrayInputStream(ct), LimitedBuffer(1_000_000), listOf(alice to null), null, emptyList())
        }
    }
}
