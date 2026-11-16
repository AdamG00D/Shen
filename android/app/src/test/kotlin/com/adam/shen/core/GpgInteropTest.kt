package com.adam.shen.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.Date
import java.util.concurrent.TimeUnit

/**
 * توافق مع GnuPG الحقيقي (نفس اللي جوه كيلوباترا): كل حاجة شِن بيعملها gpg يفهمها، والعكس.
 * بيتخطّى لوحده لو gpg مش موجود على الجهاز.
 */
class GpgInteropTest {
    @get:Rule
    val tmp = TemporaryFolder()

    private val pgp = Pgp()
    private lateinit var home: File

    @Before
    fun setUp() {
        assumeTrue("gpg not installed", gpgAvailable())
        home = tmp.newFolder("gnupg")
        home.setReadable(false, false)
        home.setReadable(true, true)
        home.setExecutable(true, true)
    }

    @After
    fun tearDown() {
        // gpg-agent اللي اشتغل للفولدر المؤقت
        if (::home.isInitialized) ProcessBuilder("gpgconf", "--homedir", home.path, "--kill", "all").start().waitFor(10, TimeUnit.SECONDS)
    }

    private fun gpgAvailable() = try {
        ProcessBuilder("gpg", "--version").start().waitFor(10, TimeUnit.SECONDS)
    } catch (e: Exception) {
        false
    }

    private class Result(val code: Int, val out: ByteArray, val err: String)

    private fun gpg(vararg args: String, input: ByteArray = ByteArray(0), pass: String? = null): Result {
        val cmd = mutableListOf("gpg", "--homedir", home.path, "--batch", "--yes", "--no-tty", "--status-fd", "2")
        if (pass != null) {
            val pf = File(tmp.root, "pass.txt").apply { writeText(pass) }
            cmd += listOf("--pinentry-mode", "loopback", "--passphrase-file", pf.path)
        }
        cmd += args
        val p = ProcessBuilder(cmd).start()
        val errBuf = ByteArrayOutputStream()
        val errThread = Thread { p.errorStream.copyTo(errBuf) }.apply { start() }
        p.outputStream.use { it.write(input) }
        val out = p.inputStream.readBytes()
        p.waitFor(60, TimeUnit.SECONDS)
        errThread.join()
        return Result(p.exitValue(), out, errBuf.toString())
    }

    private fun shenKey(pass: String) =
        pgp.generate("Shen User <shen@example.org>", pass, KeyAlgo.CV25519, Date(System.currentTimeMillis() + 86_400_000L * 365))

    @Test
    fun gpgDecryptsAndVerifiesWhatShenMakes() {
        val key = shenKey("shen pass")
        assertEquals(0, gpg("--import", input = pgp.armor(key).toByteArray(), pass = "shen pass").code)
        val msg = "مرحبا من شِن\nhello from Shen\n".toByteArray()

        val ct = ByteArrayOutputStream()
        pgp.encrypt(ByteArrayInputStream(msg), ct, listOf(pgp.publicPart(key)), key, "shen pass", armor = true, fileName = "note.txt")
        val dec = gpg("--decrypt", input = ct.toByteArray(), pass = "shen pass")
        assertEquals(dec.err, 0, dec.code)
        assertTrue(msg.contentEquals(dec.out))
        assertTrue(dec.err, dec.err.contains("GOODSIG"))

        val clear = ByteArrayOutputStream()
        pgp.sign(ByteArrayInputStream(msg), clear, key, "shen pass", SignMode.CLEAR, armor = true)
        val v1 = gpg("--verify", input = clear.toByteArray())
        assertTrue(v1.err, v1.err.contains("GOODSIG"))

        val detached = ByteArrayOutputStream()
        pgp.sign(ByteArrayInputStream(msg), detached, key, "shen pass", SignMode.DETACHED, armor = true)
        val sigFile = File(tmp.root, "m.sig").apply { writeBytes(detached.toByteArray()) }
        val dataFile = File(tmp.root, "m.txt").apply { writeBytes(msg) }
        val v2 = gpg("--verify", sigFile.path, dataFile.path)
        assertTrue(v2.err, v2.err.contains("GOODSIG"))

        val sym = ByteArrayOutputStream()
        pgp.encryptWithPassword(ByteArrayInputStream(msg), sym, "shared secret", armor = true, modern = false)
        val d3 = gpg("--decrypt", input = sym.toByteArray(), pass = "shared secret")
        assertEquals(d3.err, 0, d3.code)
        assertTrue(msg.contentEquals(d3.out))
    }

    @Test
    fun shenReadsWhatGpgMakes() {
        val gen = gpg("--quick-generate-key", "GPG User <gpg@example.org>", "ed25519", "sign,cert", "1y", pass = "gpg pass")
        assertEquals(gen.err, 0, gen.code)
        val fpr = gpg("--list-keys", "--with-colons").out.toString(Charsets.UTF_8).lines()
            .first { it.startsWith("fpr") }.split(":")[9]
        assertEquals(0, gpg("--quick-add-key", fpr, "cv25519", "encr", "1y", pass = "gpg pass").code)

        val pub = pgp.parseCert(gpg("--armor", "--export", fpr).out)
        assertEquals(fpr, pgp.fingerprint(pub))
        assertEquals(true, pgp.summary(pub)["canEncrypt"])
        val sec = pgp.parseKey(gpg("--armor", "--export-secret-keys", fpr, pass = "gpg pass").out)

        val msg = "from gpg".toByteArray()
        // gpg يشفّر ويوقّع لنفسه ← شِن يفك بالمفتاح السري اللي اتصدّر ويتحقق
        val ct = gpg("--armor", "--encrypt", "--sign", "-r", fpr, input = msg, pass = "gpg pass")
        assertEquals(ct.err, 0, ct.code)
        val out = ByteArrayOutputStream()
        val r = pgp.decrypt(ByteArrayInputStream(ct.out), out, listOf(sec to "gpg pass"), null, listOf(pub))
        assertTrue(msg.contentEquals(out.toByteArray()))
        assertEquals(SigStatus.GOOD, r.signatures.single().status)

        val clear = gpg("--clearsign", input = msg, pass = "gpg pass")
        val sigs = pgp.verify(ByteArrayInputStream(clear.out), ByteArrayOutputStream(), null, listOf(pub))
        assertEquals(SigStatus.GOOD, sigs.single().status)

        val det = gpg("--armor", "--detach-sign", input = msg, pass = "gpg pass")
        val sigs2 = pgp.verify(ByteArrayInputStream(msg), null, ByteArrayInputStream(det.out), listOf(pub))
        assertEquals(SigStatus.GOOD, sigs2.single().status)

        // شِن يشفّر لمفتاح gpg ← gpg يفك
        val ct2 = ByteArrayOutputStream()
        pgp.encrypt(ByteArrayInputStream(msg), ct2, listOf(pub), null, null, armor = true, fileName = null)
        val d = gpg("--decrypt", input = ct2.toByteArray(), pass = "gpg pass")
        assertEquals(d.err, 0, d.code)
        assertTrue(msg.contentEquals(d.out))

        // تشفير بكلمة سر من gpg
        val sym = gpg("--armor", "--symmetric", input = msg, pass = "pw from gpg")
        val o2 = ByteArrayOutputStream()
        pgp.decrypt(ByteArrayInputStream(sym.out), o2, emptyList(), "pw from gpg", emptyList())
        assertTrue(msg.contentEquals(o2.toByteArray()))
    }
}
