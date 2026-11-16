package com.adam.shen.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

/** ملفات عادية بدل content:// في التيستات. */
class FileStreams : Streams {
    override fun open(uri: String) = File(uri).inputStream()
    override fun create(uri: String) = File(uri).outputStream()
    override fun delete(uri: String) {
        File(uri).delete()
    }
}

@Suppress("UNCHECKED_CAST")
class ApiTest {
    @get:Rule
    val tmp = TemporaryFolder()

    private var clock = System.currentTimeMillis()
    private val wrapper = SoftwareKeyWrapper()

    private fun api(dir: File = File(tmp.root, "vault"), w: KeyWrapper = wrapper) =
        Api(Vault(dir, w, KdfStrength.FAST) { clock }, FileStreams(), KdfStrength.FAST) { clock }

    private fun Api.c(method: String, vararg args: Pair<String, Any?>): Any? = call(method, mapOf(*args))

    private fun expectErr(code: Err, block: () -> Unit) {
        try {
            block()
            fail("expected $code")
        } catch (e: CoreError) {
            assertEquals(code, e.code)
        }
    }

    private fun Api.active(): String = (c("profiles") as List<Map<String, Any?>>).first { it["active"] == true }["id"] as String

    private fun Api.newKey(profile: String, name: String, pass: String? = "key passphrase"): String =
        (c("generateKey", "profile" to profile, "name" to name, "email" to "${name.lowercase().replace(' ', '.')}@example.org", "passphrase" to pass) as Map<String, Any?>)["fp"] as String

    @Test
    fun fullFlow() {
        val a = api()
        assertEquals(false, (a.c("status") as Map<*, *>)["exists"])
        expectErr(Err.LOCKED) { a.c("profiles") }
        a.c("setup", "password" to "master password", "profileName" to "Personal", "color" to 1)
        val personal = a.active()
        val alice = a.newKey(personal, "Alice")
        val keys = a.c("keys", "profile" to personal) as List<Map<String, Any?>>
        assertEquals(alice, keys.single()["fp"])
        assertEquals(true, keys.single()["default"])
        assertEquals(true, keys.single()["hasRevocation"])

        // جهة اتصال: بوب عنده شِن على موبايل تاني
        val bobApi = api(File(tmp.root, "bob"), SoftwareKeyWrapper())
        bobApi.c("setup", "password" to "bob master pw", "profileName" to "Bob", "color" to 0)
        val bobProfile = bobApi.active()
        val bob = bobApi.newKey(bobProfile, "Bob", pass = null)
        val bobPublic = bobApi.c("exportPublic", "profile" to bobProfile, "fps" to listOf(bob)) as String
        assertFalse(bobPublic.contains("PRIVATE"))

        val preview = a.c("previewImport", "profile" to personal, "data" to bobPublic) as List<Map<String, Any?>>
        assertNull(preview.single()["existing"])
        assertEquals(mapOf("added" to 1, "updated" to 0, "unchanged" to 0), a.c("importKeys", "profile" to personal, "data" to bobPublic, "scope" to "profile"))
        assertEquals(mapOf("added" to 0, "updated" to 0, "unchanged" to 1), a.c("importKeys", "profile" to personal, "data" to bobPublic, "scope" to "profile"))

        // أشفّر لبوب وأوقّع
        assertEquals(true, a.c("needsPassphrase", "profile" to personal, "fp" to alice))
        val ct = a.c("encryptText", "profile" to personal, "text" to "أهلاً يا بوب", "recipients" to listOf(bob), "signWith" to alice, "passphrase" to "key passphrase") as String
        // بوب لسه ميعرفش أليس: التوقيع "مفتاح مش معروف"
        val inspect = bobApi.c("inspect", "profile" to bobProfile, "data" to ct) as Map<String, Any?>
        assertEquals("encrypted", inspect["kind"])
        assertTrue((inspect["recipients"] as List<Map<String, Any?>>).any { it["fp"] == bob })
        val dec = bobApi.c("decryptText", "profile" to bobProfile, "data" to ct) as Map<String, Any?>
        assertEquals("أهلاً يا بوب", dec["text"])
        val sig = (dec["signatures"] as List<Map<String, Any?>>).single()
        assertEquals("UNKNOWN_KEY", sig["status"])

        // بوب يضيف أليس ويتأكد منها ← توقيع سليم ومتأكد منه
        val alicePublic = a.c("exportPublic", "profile" to personal, "fps" to listOf(alice)) as String
        bobApi.c("importKeys", "profile" to bobProfile, "data" to alicePublic, "scope" to "profile")
        bobApi.c("setContactVerified", "profile" to bobProfile, "fp" to alice, "verified" to true)
        val dec2 = bobApi.c("decryptText", "profile" to bobProfile, "data" to ct) as Map<String, Any?>
        val sig2 = (dec2["signatures"] as List<Map<String, Any?>>).single()
        assertEquals("GOOD", sig2["status"])
        assertEquals(true, sig2["verified"])
        assertEquals("Alice <alice@example.org>", sig2["name"])

        // أليس شفّرت لنفسها كمان (افتراضي) فتقدر تقرا رسالتها
        expectErr(Err.NO_KEY) { a.c("decryptText", "profile" to personal, "data" to ct) }
        val mine = a.c("decryptText", "profile" to personal, "data" to ct, "keyFp" to alice, "passphrase" to "key passphrase") as Map<String, Any?>
        assertEquals("أهلاً يا بوب", mine["text"])
        expectErr(Err.WRONG_PASSWORD) { a.c("decryptText", "profile" to personal, "data" to ct, "keyFp" to alice, "passphrase" to "wrong") }
    }

    @Test
    fun contactsArePerProfileUnlessShared() {
        val a = api()
        a.c("setup", "password" to "master password", "profileName" to "Personal", "color" to 1)
        val personal = a.active()
        val work = a.c("createProfile", "name" to "Work", "color" to 2) as String
        val other = Api(Vault(File(tmp.root, "o"), SoftwareKeyWrapper(), KdfStrength.FAST), FileStreams(), KdfStrength.FAST)
        other.c("setup", "password" to "other master", "profileName" to "x", "color" to 0)
        val op = other.active()
        val carol = other.newKey(op, "Carol", null)
        val dave = other.newKey(op, "Dave", null)
        val carolPub = other.c("exportPublic", "profile" to op, "fps" to listOf(carol)) as String
        val davePub = other.c("exportPublic", "profile" to op, "fps" to listOf(dave)) as String

        a.c("importKeys", "profile" to personal, "data" to carolPub, "scope" to "profile")
        a.c("importKeys", "profile" to personal, "data" to davePub, "scope" to "shared")
        fun names(p: String) = (a.c("contacts", "profile" to p) as List<Map<String, Any?>>).map { it["fp"] to it["scope"] }.toSet()
        assertEquals(setOf(carol to "profile", dave to "shared"), names(personal))
        // الشغل شايف المشترك بس
        assertEquals(setOf(dave to "shared"), names(work))
        expectErr(Err.NOT_FOUND) {
            a.c("encryptText", "profile" to work, "text" to "x", "recipients" to listOf(carol), "self" to false)
        }

        a.c("setContactScope", "profile" to personal, "fp" to carol, "scope" to "shared")
        assertEquals(setOf(carol to "shared", dave to "shared"), names(work))
        a.c("setContactScope", "profile" to work, "fp" to dave, "scope" to "profile")
        assertEquals(setOf(carol to "shared"), names(personal))
        assertEquals(setOf(carol to "shared", dave to "profile"), names(work))

        // بعد إعادة الفتح كل حاجة في مكانها
        a.c("lock")
        a.c("unlock", "password" to "master password")
        assertEquals(setOf(carol to "shared", dave to "profile"), names(work))
    }

    @Test
    fun lockedProfileIsInvisibleUntilUnlocked() {
        val a = api()
        a.c("setup", "password" to "master password", "profileName" to "Personal", "color" to 1)
        val work = a.c("createProfile", "name" to "Work", "color" to 2, "password" to "work secret") as String
        val k = a.newKey(work, "Worker")
        a.c("lock")
        a.c("unlock", "password" to "master password")
        val p = (a.c("profiles") as List<Map<String, Any?>>).first { it["id"] == work }
        assertEquals(false, p["open"])
        assertNull(p["keys"])
        expectErr(Err.PROFILE_LOCKED) { a.c("keys", "profile" to work) }
        expectErr(Err.WRONG_PASSWORD) { a.c("unlockProfile", "id" to work, "password" to "master password") }
        a.c("unlockProfile", "id" to work, "password" to "work secret")
        assertEquals(k, (a.c("keys", "profile" to work) as List<Map<String, Any?>>).single()["fp"])
    }

    @Test
    fun passphraseCache() {
        val a = api()
        a.c("setup", "password" to "master password", "profileName" to "P", "color" to 1)
        val p = a.active()
        val k = a.newKey(p, "Alice")
        a.c("signText", "profile" to p, "text" to "x", "keyFp" to k, "passphrase" to "key passphrase")
        // الحفظ المؤقت مقفول افتراضياً
        assertEquals(true, a.c("needsPassphrase", "profile" to p, "fp" to k))
        a.c("setPassCache", "minutes" to 5)
        a.c("signText", "profile" to p, "text" to "x", "keyFp" to k, "passphrase" to "key passphrase")
        assertEquals(false, a.c("needsPassphrase", "profile" to p, "fp" to k))
        assertNotNull(a.c("signText", "profile" to p, "text" to "x", "keyFp" to k))
        clock += 5 * 60_000 + 1
        assertEquals(true, a.c("needsPassphrase", "profile" to p, "fp" to k))
        // القفل بيمسح الكاش
        a.c("signText", "profile" to p, "text" to "x", "keyFp" to k, "passphrase" to "key passphrase")
        a.c("lock")
        a.c("unlock", "password" to "master password")
        assertEquals(true, a.c("needsPassphrase", "profile" to p, "fp" to k))
    }

    @Test
    fun keyManagementNeedsMasterPassword() {
        val a = api()
        a.c("setup", "password" to "master password", "profileName" to "P", "color" to 1)
        val p = a.active()
        val k = a.newKey(p, "Alice")
        expectErr(Err.WRONG_PASSWORD) { a.c("exportSecret", "profile" to p, "fp" to k, "password" to "nope nope") }
        val secret = a.c("exportSecret", "profile" to p, "fp" to k, "password" to "master password") as String
        assertTrue(secret.contains("PRIVATE KEY"))
        val rev = a.c("revocationCert", "profile" to p, "fp" to k, "password" to "master password") as String
        assertTrue(rev.contains("PUBLIC KEY"))
        expectErr(Err.WRONG_PASSWORD) { a.c("deleteKey", "profile" to p, "fp" to k, "password" to "nope nope") }
        a.c("deleteKey", "profile" to p, "fp" to k, "password" to "master password")
        assertTrue((a.c("keys", "profile" to p) as List<*>).isEmpty())
        // نرجّعه بالاستيراد
        assertEquals(1, (a.c("importKeys", "profile" to p, "data" to secret, "scope" to "profile") as Map<*, *>)["added"])
        assertEquals(true, (a.c("keys", "profile" to p) as List<Map<String, Any?>>).single()["secret"])
    }

    @Test
    fun badUserIdsAreRejected() {
        val a = api()
        a.c("setup", "password" to "master password", "profileName" to "P", "color" to 1)
        val p = a.active()
        for ((n, e) in listOf("" to "", "A <b>" to "a@b.c", "A" to "not-an-email", "A\u0000B" to "a@b.c")) {
            expectErr(Err.INVALID) { a.c("generateKey", "profile" to p, "name" to n, "email" to e, "passphrase" to "xxxxxxxx") }
        }
    }

    @Test
    fun filesAndTamperedOutputIsDeleted() {
        val a = api()
        a.c("setup", "password" to "master password", "profileName" to "P", "color" to 1)
        val p = a.active()
        val k = a.newKey(p, "Alice", pass = null)
        val plain = File(tmp.root, "doc.bin").apply { writeBytes(ByteArray(300_000) { (it % 251).toByte() }) }
        val enc = File(tmp.root, "doc.bin.pgp")
        a.c("encryptFile", "profile" to p, "in" to plain.path, "out" to enc.path, "recipients" to listOf(k), "fileName" to "doc.bin")
        val dec = File(tmp.root, "doc.out")
        val r = a.c("decryptFile", "profile" to p, "in" to enc.path, "out" to dec.path) as Map<String, Any?>
        assertEquals("doc.bin", r["fileName"])
        assertTrue(plain.readBytes().contentEquals(dec.readBytes()))

        val bytes = enc.readBytes()
        bytes[bytes.size / 2] = (bytes[bytes.size / 2].toInt() xor 0x20).toByte()
        val bad = File(tmp.root, "bad.pgp").apply { writeBytes(bytes) }
        val badOut = File(tmp.root, "bad.out")
        try {
            a.c("decryptFile", "profile" to p, "in" to bad.path, "out" to badOut.path)
            fail("tampered file decrypted")
        } catch (e: CoreError) {
            assertTrue(e.code == Err.INTEGRITY || e.code == Err.BAD_DATA)
        }
        assertFalse("partial plaintext must be deleted", badOut.exists())

        val sig = File(tmp.root, "doc.sig")
        a.c("signFile", "profile" to p, "in" to plain.path, "out" to sig.path, "keyFp" to k)
        val v = a.c("verifyFile", "profile" to p, "in" to plain.path, "sig" to sig.path) as List<Map<String, Any?>>
        assertEquals("GOOD", v.single()["status"])
        assertEquals(true, v.single()["mine"])
    }

    @Test
    fun backupRoundTrip() {
        val a = api()
        a.c("setup", "password" to "master password", "profileName" to "Personal", "color" to 1)
        val personal = a.active()
        val work = a.c("createProfile", "name" to "Work", "color" to 2) as String
        val k1 = a.newKey(personal, "Alice")
        val k2 = a.newKey(work, "Alice Work")
        val other = api(File(tmp.root, "o"), SoftwareKeyWrapper())
        other.c("setup", "password" to "other master", "profileName" to "x", "color" to 0)
        val carol = other.newKey(other.active(), "Carol", null)
        a.c("importKeys", "profile" to personal, "data" to other.c("exportPublic", "profile" to other.active(), "fps" to listOf(carol)), "scope" to "shared")
        a.c("setContactVerified", "profile" to personal, "fp" to carol, "verified" to true)

        val file = File(tmp.root, "all.shen")
        expectErr(Err.INVALID) { a.c("exportBackup", "password" to "short", "out" to file.path) }
        val res = a.c("exportBackup", "password" to "backup password", "out" to file.path) as Map<String, Any?>
        assertEquals(2, res["profiles"])
        assertEquals(2, res["keys"])
        assertFalse(String(file.readBytes(), Charsets.ISO_8859_1).contains("Alice"))

        // جهاز جديد
        val b = api(File(tmp.root, "new"), SoftwareKeyWrapper())
        b.c("setup", "password" to "new master pw", "profileName" to "Personal", "color" to 1)
        expectErr(Err.WRONG_PASSWORD) { b.c("previewBackup", "in" to file.path, "password" to "wrong password") }
        val pv = b.c("previewBackup", "in" to file.path, "password" to "backup password") as Map<String, Any?>
        assertEquals(1, pv["shared"])
        assertEquals(listOf(true, false), (pv["profiles"] as List<Map<String, Any?>>).map { it["exists"] })
        val imp = b.c("importBackup", "in" to file.path, "password" to "backup password") as Map<String, Any?>
        assertEquals(1, imp["profiles"])
        assertEquals(3, imp["added"])
        val profiles = b.c("profiles") as List<Map<String, Any?>>
        assertEquals(listOf("Personal", "Work"), profiles.map { it["name"] })
        val pid = profiles[0]["id"] as String
        val wid = profiles[1]["id"] as String
        assertEquals(k1, (b.c("keys", "profile" to pid) as List<Map<String, Any?>>).single()["fp"])
        assertEquals(k2, (b.c("keys", "profile" to wid) as List<Map<String, Any?>>).single()["fp"])
        val c = (b.c("contacts", "profile" to wid) as List<Map<String, Any?>>).single()
        assertEquals("shared", c["scope"])
        assertEquals(true, c["verified"])
        // المفتاح المستورد لسه بكلمة سره القديمة وشهادة الإلغاء رجعت
        assertEquals(true, b.c("checkKeyPassphrase", "profile" to pid, "fp" to k1, "passphrase" to "key passphrase"))
        assertNotNull(b.c("revocationCert", "profile" to pid, "fp" to k1, "password" to "new master pw"))
        // استيراد تاني = مفيش تكرار
        assertEquals(0, (b.c("importBackup", "in" to file.path, "password" to "backup password") as Map<*, *>)["added"])

        // ملف مش نسخة احتياطية
        val notBackup = File(tmp.root, "x.pgp")
        a.c("encryptFile", "profile" to personal, "in" to file.path, "out" to notBackup.path, "password" to "backup password")
        expectErr(Err.NOT_BACKUP) { b.c("previewBackup", "in" to notBackup.path, "password" to "backup password") }
        expectErr(Err.NOT_BACKUP) { b.c("previewBackup", "in" to File(tmp.root, "doc").apply { writeText("hello") }.path, "password" to "x") }
    }

    @Test
    fun hostileInputDoesNotCrash() {
        val a = api()
        a.c("setup", "password" to "master password", "profileName" to "P", "color" to 1)
        val p = a.active()
        val junk = listOf(
            ByteArray(0),
            "-----BEGIN PGP MESSAGE-----\n\n=====\n-----END PGP MESSAGE-----".toByteArray(),
            ByteArray(5000) { 0x8C.toByte() },
            ByteArray(5000) { (it * 31).toByte() },
            byteArrayOf(0xC1.toByte(), 0xFF.toByte(), 0xFF.toByte(), 0xFF.toByte(), 0xFF.toByte()),
        )
        for (j in junk) {
            for (m in listOf("previewImport", "decryptText", "verifyText", "inspect")) {
                try {
                    a.c(m, "profile" to p, "data" to j)
                } catch (e: CoreError) {
                    // أي كود تمام — المهم ميقعش
                }
            }
        }
        expectErr(Err.TOO_LARGE) { a.c("previewImport", "profile" to p, "data" to ByteArray(Api.MAX_IMPORT + 1)) }
    }
}
