package com.adam.shen.core

import org.json.JSONObject
import java.io.File

/**
 * بيلف المفاتيح بمفتاح مربوط بالجهاز (Android Keystore). على أندرويد: [com.adam.shen.AndroidKeyWrapper].
 * في التيستات: [SoftwareKeyWrapper].
 */
interface KeyWrapper {
    fun wrap(plain: ByteArray): ByteArray

    /** بيرمي [CoreError] (`KEYSTORE`) لو مفتاح الجهاز مش موجود أو اتغيّر. */
    fun unwrap(box: ByteArray): ByteArray

    /** يمسح مفتاح الجهاز (لما المستخدم يمسح كل البيانات). */
    fun reset()
}

/** للتيستات بس: مفتاح في الذاكرة بدل الـ Keystore. */
class SoftwareKeyWrapper(private var key: ByteArray = Bytes.random(32)) : KeyWrapper {
    override fun wrap(plain: ByteArray) = Aead.seal(key, plain, "test-wrapper")

    override fun unwrap(box: ByteArray) = try {
        Aead.open(key, box, "test-wrapper")
    } catch (e: CoreError) {
        throw CoreError(Err.KEYSTORE)
    }

    override fun reset() {
        key = Bytes.random(32)
    }
}

/**
 * الخزنة: "المفتاح الرئيسي" (32 بايت عشوائي) محمي بطبقتين:
 *  1. Argon2id(كلمة السر الرئيسية) ← AES-GCM
 *  2. وفوقها مفتاح الجهاز (Keystore، StrongBox لو موجود)
 * يعني اللي يسحب ملفات التطبيق محتاج الجهاز نفسه **و** كلمة السر.
 *
 * كل الملفات التانية متشفّرة بـ AES-256-GCM بمفاتيح مشتقة من هنا (شوف [Store]).
 */
class Vault(
    val dir: File,
    private val wrapper: KeyWrapper,
    private val strength: KdfStrength = KdfStrength.STANDARD,
    private val now: () -> Long = System::currentTimeMillis,
) {
    private val headerFile = File(dir, "vault.json")
    private var mk: ByteArray? = null

    val exists: Boolean get() = headerFile.exists()
    val isUnlocked: Boolean get() = mk != null

    /** المفتاح الرئيسي (مش نسخة — متمسحوش). */
    fun masterKey(): ByteArray = mk ?: throw CoreError(Err.LOCKED)

    fun create(password: String) {
        if (exists) throw CoreError(Err.EXISTS)
        checkPassword(password)
        dir.mkdirs()
        val key = Bytes.random(32)
        val h = JSONObject().put("v", 1)
        wrapWithPassword(h, key, password)
        h.put("check", Bytes.b64(Aead.seal(key, CHECK, AAD_CHECK)))
        saveHeader(h)
        mk = key
    }

    fun unlock(password: String) {
        val h = loadHeader()
        val wait = h.optLong("until", 0) - now()
        if (wait > 0) throw CoreError(Err.LOCKED_OUT, wait)
        val key = openWithPassword(h, password)
        if (key == null) {
            registerFailure(h)
            throw CoreError(Err.WRONG_PASSWORD, waitAfterFailure(h))
        }
        verifyCheck(h, key)
        if (h.optInt("fail", 0) != 0) {
            h.put("fail", 0).put("until", 0)
            saveHeader(h)
        }
        mk?.let(Bytes::wipe)
        mk = key
    }

    /** فتح بالبصمة: الطبقة الأندرويد فكّت المفتاح الرئيسي بمفتاح Keystore مربوط بالبصمة. */
    fun unlockWithMasterKey(key: ByteArray) {
        val h = loadHeader()
        if (key.size != 32) throw CoreError(Err.WRONG_PASSWORD)
        verifyCheck(h, key)
        mk?.let(Bytes::wipe)
        mk = key.copyOf()
    }

    fun lock() {
        mk?.let(Bytes::wipe)
        mk = null
    }

    fun verifyPassword(password: String): Boolean {
        val h = loadHeader()
        val key = openWithPassword(h, password) ?: return false
        Bytes.wipe(key)
        return true
    }

    fun changePassword(old: String, new: String) {
        val key = masterKey()
        checkPassword(new)
        val h = loadHeader()
        val check = openWithPassword(h, old) ?: throw CoreError(Err.WRONG_PASSWORD)
        Bytes.wipe(check)
        wrapWithPassword(h, key, new)
        saveHeader(h)
    }

    /** المفتاح الرئيسي متشفّر بمفتاح البصمة (null = البصمة مش مفعّلة). */
    var bioBlob: String?
        get() = loadHeader().optString("bio", "").ifEmpty { null }
        set(value) {
            val h = loadHeader()
            if (value == null) h.remove("bio") else h.put("bio", value)
            saveHeader(h)
        }

    /** يمسح كل حاجة (الملفات + مفتاح الجهاز). */
    fun destroy() {
        lock()
        dir.deleteRecursively()
        try {
            wrapper.reset()
        } catch (_: Exception) {
        }
    }

    // ---------------- ملفات متشفّرة ----------------

    /** كتابة آمنة: ملف مؤقت وبعدين rename (لو الموبايل فصل في النص الملف القديم بيفضل سليم). */
    fun write(name: String, aad: String, key: ByteArray, data: ByteArray) {
        val f = File(dir, name)
        f.parentFile?.mkdirs()
        val tmp = File(f.path + ".tmp")
        tmp.outputStream().use {
            it.write(Aead.seal(key, data, aad))
            it.fd.sync()
        }
        if (!tmp.renameTo(f)) throw CoreError(Err.IO)
    }

    /** null = الملف مش موجود. بيرمي `BAD_DATA` لو الملف بايظ أو اتلعب فيه. */
    fun read(name: String, aad: String, key: ByteArray): ByteArray? {
        val f = File(dir, name)
        if (!f.exists()) return null
        return Aead.open(key, f.readBytes(), aad)
    }

    fun delete(name: String) {
        File(dir, name).delete()
    }

    // ---------------- داخلي ----------------

    private fun checkPassword(password: String) {
        if (password.length < MIN_PASSWORD || password.length > 1024) throw CoreError(Err.INVALID)
    }

    private fun wrapWithPassword(h: JSONObject, key: ByteArray, password: String) {
        val kdf = strength.fresh()
        val pw = Kdf.normalize(password)
        val kek = Kdf.argon2id(pw, kdf)
        Bytes.wipe(pw)
        val inner = Aead.seal(kek, key, AAD_MK)
        Bytes.wipe(kek)
        h.put("kdf", kdf.toJson()).put("mk", Bytes.b64(wrapper.wrap(inner)))
    }

    /** null = كلمة السر غلط. */
    private fun openWithPassword(h: JSONObject, password: String): ByteArray? {
        val inner = try {
            wrapper.unwrap(Bytes.unb64(h.getString("mk")))
        } catch (e: CoreError) {
            throw e
        } catch (e: Exception) {
            throw CoreError(Err.KEYSTORE)
        }
        val kdf = KdfParams.fromJson(h.getJSONObject("kdf"))
        val pw = Kdf.normalize(password)
        val kek = Kdf.argon2id(pw, kdf)
        Bytes.wipe(pw)
        return try {
            Aead.open(kek, inner, AAD_MK)
        } catch (e: CoreError) {
            null
        } finally {
            Bytes.wipe(kek)
        }
    }

    private fun verifyCheck(h: JSONObject, key: ByteArray) {
        val ok = try {
            Bytes.equal(Aead.open(key, Bytes.unb64(h.getString("check")), AAD_CHECK), CHECK)
        } catch (e: CoreError) {
            false
        }
        if (!ok) throw CoreError(Err.WRONG_PASSWORD)
    }

    private fun registerFailure(h: JSONObject) {
        val n = h.optInt("fail", 0) + 1
        h.put("fail", n)
        val wait = delayFor(n)
        if (wait > 0) h.put("until", now() + wait)
        saveHeader(h)
    }

    private fun waitAfterFailure(h: JSONObject) = maxOf(0L, h.optLong("until", 0) - now())

    private fun loadHeader(): JSONObject {
        if (!headerFile.exists()) throw CoreError(Err.NOT_FOUND)
        return try {
            JSONObject(headerFile.readText())
        } catch (e: Exception) {
            throw CoreError(Err.BAD_DATA)
        }
    }

    private fun saveHeader(h: JSONObject) {
        dir.mkdirs()
        val tmp = File(headerFile.path + ".tmp")
        tmp.outputStream().use {
            it.write(h.toString().toByteArray(Charsets.UTF_8))
            it.fd.sync()
        }
        if (!tmp.renameTo(headerFile)) throw CoreError(Err.IO)
    }

    companion object {
        const val MIN_PASSWORD = 8
        private val CHECK = "shen-vault-ok".toByteArray()
        private const val AAD_MK = "shen/master-key/v1"
        private const val AAD_CHECK = "shen/check/v1"

        /** أول 4 محاولات غلط من غير انتظار، وبعدين 30 ث وبتتضاعف لحد 15 دقيقة. */
        fun delayFor(failures: Int): Long {
            if (failures < 5) return 0
            val shift = minOf(failures - 5, 5)
            return minOf(30_000L shl shift, 15 * 60_000L)
        }
    }
}
