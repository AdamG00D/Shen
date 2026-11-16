package com.adam.shen.core

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

class VaultStoreTest {
    @get:Rule
    val tmp = TemporaryFolder()

    private var clock = 1_000_000L
    private val wrapper = SoftwareKeyWrapper()

    private fun vault(dir: File = tmp.root, w: KeyWrapper = wrapper) = Vault(dir, w, KdfStrength.FAST) { clock }

    private fun expectErr(code: Err, block: () -> Unit): CoreError {
        try {
            block()
        } catch (e: CoreError) {
            assertEquals(code, e.code)
            return e
        }
        fail("expected $code")
        throw AssertionError()
    }

    @Test
    fun createUnlockLock() {
        val v = vault()
        expectErr(Err.INVALID) { v.create("short") }
        v.create("master password")
        assertTrue(v.isUnlocked)
        val mk = v.masterKey().copyOf()
        v.lock()
        assertFalse(v.isUnlocked)
        expectErr(Err.LOCKED) { v.masterKey() }

        val v2 = vault()
        expectErr(Err.WRONG_PASSWORD) { v2.unlock("master passwort") }
        v2.unlock("master password")
        assertArrayEquals(mk, v2.masterKey())
    }

    @Test
    fun noSecretsInPlainFiles() {
        val v = vault()
        v.create("master password")
        val s = Store(v, KdfStrength.FAST)
        s.load()
        val p = s.createProfile("Personal", 1, null)
        s.data(p.id).contacts += ContactEntry("ABCD", "SECRET-MARKER-123".toByteArray(), false, 0)
        s.saveProfileData(p.id)
        tmp.root.walkTopDown().filter { it.isFile }.forEach { f ->
            val text = String(f.readBytes(), Charsets.ISO_8859_1)
            assertFalse(f.name, text.contains("SECRET-MARKER"))
            assertFalse(f.name, text.contains("Personal"))
            assertFalse(f.name, text.contains("master password"))
        }
    }

    @Test
    fun deviceKeyIsRequired() {
        vault().create("master password")
        // نفس الملفات على جهاز تاني (مفتاح Keystore مختلف) مبتتفتحش حتى بكلمة السر الصح
        expectErr(Err.KEYSTORE) { vault(w = SoftwareKeyWrapper()).unlock("master password") }
    }

    @Test
    fun bruteForceIsSlowedDown() {
        vault().create("master password")
        val v = vault()
        repeat(4) { expectErr(Err.WRONG_PASSWORD) { v.unlock("wrong password") } }
        val e = expectErr(Err.WRONG_PASSWORD) { v.unlock("wrong password") }
        assertEquals(30_000L, e.waitMs)
        // حتى كلمة السر الصح متتقبلش قبل ما المدة تخلص
        expectErr(Err.LOCKED_OUT) { v.unlock("master password") }
        clock += 30_001
        expectErr(Err.WRONG_PASSWORD) { v.unlock("wrong password") }
        expectErr(Err.LOCKED_OUT) { v.unlock("master password") }
        clock += 60_001
        v.unlock("master password")
        // بعد النجاح العداد بيرجع صفر
        v.lock()
        expectErr(Err.WRONG_PASSWORD) { v.unlock("wrong password") }
        v.unlock("master password")
        assertEquals(15 * 60_000L, Vault.delayFor(50))
    }

    @Test
    fun changePasswordAndBiometricKey() {
        val v = vault()
        v.create("master password")
        val mk = v.masterKey().copyOf()
        expectErr(Err.WRONG_PASSWORD) { v.changePassword("nope nope", "new master pw") }
        v.changePassword("master password", "new master pw")
        v.lock()
        expectErr(Err.WRONG_PASSWORD) { vault().unlock("master password") }
        val v2 = vault()
        v2.unlock("new master pw")
        assertArrayEquals(mk, v2.masterKey())

        v2.lock()
        expectErr(Err.WRONG_PASSWORD) { v2.unlockWithMasterKey(ByteArray(32)) }
        v2.unlockWithMasterKey(mk)
        assertTrue(v2.isUnlocked)
        assertNull(v2.bioBlob)
        v2.bioBlob = "abc"
        assertEquals("abc", vault().bioBlob)
    }

    @Test
    fun tamperedFileIsRejected() {
        val v = vault()
        v.create("master password")
        v.write("x.bin", "aad-1", v.masterKey(), "hello".toByteArray())
        assertEquals("hello", String(v.read("x.bin", "aad-1", v.masterKey())!!))
        // نفس الملف بـ AAD تاني (مثلاً ملف بروفايل اتنقل مكان بروفايل تاني)
        expectErr(Err.BAD_DATA) { v.read("x.bin", "aad-2", v.masterKey()) }
        val f = File(tmp.root, "x.bin")
        val b = f.readBytes()
        b[b.size - 1] = (b[b.size - 1].toInt() xor 1).toByte()
        f.writeBytes(b)
        expectErr(Err.BAD_DATA) { v.read("x.bin", "aad-1", v.masterKey()) }
    }

    @Test
    fun profilesAreIsolatedAndPersist() {
        val v = vault()
        v.create("master password")
        val s = Store(v, KdfStrength.FAST)
        s.load()
        val personal = s.createProfile("شخصي", 1, null)
        val work = s.createProfile("Work", 2, "work password")
        assertEquals(personal.id, s.activeId)
        s.data(personal.id).contacts += ContactEntry("P1", byteArrayOf(1), false, 0)
        s.data(work.id).contacts += ContactEntry("W1", byteArrayOf(2), true, 0)
        s.shared() += ContactEntry("S1", byteArrayOf(3), true, 0)
        s.saveProfileData(personal.id)
        s.saveProfileData(work.id)
        s.saveShared()
        s.setActive(work.id)

        // تشغيل جديد
        v.lock()
        s.close()
        val v2 = vault()
        v2.unlock("master password")
        val s2 = Store(v2, KdfStrength.FAST)
        s2.load()
        assertEquals(work.id, s2.activeId)
        assertEquals(listOf("P1"), s2.data(personal.id).contacts.map { it.fp })
        assertEquals(listOf("S1"), s2.shared().map { it.fp })
        // بروفايل الشغل مقفول لحد ما كلمة سره تتكتب
        expectErr(Err.PROFILE_LOCKED) { s2.data(work.id) }
        expectErr(Err.WRONG_PASSWORD) { s2.unlockProfile(work.id, "personal password") }
        s2.unlockProfile(work.id, "work password")
        assertEquals(listOf("W1"), s2.data(work.id).contacts.map { it.fp })
        assertTrue(s2.data(work.id).contacts[0].verified)

        s2.lockProfile(work.id)
        expectErr(Err.PROFILE_LOCKED) { s2.data(work.id) }
        s2.unlockProfile(work.id, "work password")
        s2.setProfilePassword(work.id, null)
        s2.close()
        s2.load()
        assertEquals(listOf("W1"), s2.data(work.id).contacts.map { it.fp })

        expectErr(Err.INVALID) { s2.createProfile("   ", 0, null) }
        s2.deleteProfile(work.id)
        expectErr(Err.NOT_FOUND) { s2.data(work.id) }
        expectErr(Err.INVALID) { s2.deleteProfile(personal.id) }
        assertFalse(File(tmp.root, "p/${work.id}.bin").exists())
    }

    @Test
    fun swappingProfileFilesIsDetected() {
        val v = vault()
        v.create("master password")
        val s = Store(v, KdfStrength.FAST)
        s.load()
        val a = s.createProfile("A", 0, null)
        val b = s.createProfile("B", 0, null)
        s.saveProfileData(a.id)
        s.saveProfileData(b.id)
        File(tmp.root, "p/${a.id}.bin").copyTo(File(tmp.root, "p/${b.id}.bin"), overwrite = true)
        expectErr(Err.BAD_DATA) { s.load() }
    }

    @Test
    fun destroyWipesEverything() {
        val v = vault()
        v.create("master password")
        v.destroy()
        assertFalse(v.exists)
        assertFalse(tmp.root.exists() && tmp.root.listFiles()!!.isNotEmpty())
    }
}
