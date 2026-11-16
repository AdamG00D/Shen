package com.adam.shen.core

import org.bouncycastle.crypto.generators.Argon2BytesGenerator
import org.bouncycastle.crypto.params.Argon2Parameters
import org.json.JSONObject
import java.security.MessageDigest
import java.security.SecureRandom
import java.text.Normalizer
import java.util.Base64
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/** أدوات بايتات صغيرة. */
object Bytes {
    private val rng = SecureRandom()

    fun random(n: Int): ByteArray = ByteArray(n).also { rng.nextBytes(it) }

    /** معرّف عشوائي (16 حرف hex). */
    fun randomId(): String = hex(random(8))

    fun wipe(b: ByteArray?) {
        b?.fill(0)
    }

    fun wipe(c: CharArray?) {
        c?.fill('\u0000')
    }

    /** مقارنة ثابتة الزمن. */
    fun equal(a: ByteArray, b: ByteArray): Boolean = MessageDigest.isEqual(a, b)

    fun b64(b: ByteArray): String = Base64.getEncoder().encodeToString(b)

    fun unb64(s: String): ByteArray = Base64.getDecoder().decode(s)

    fun hex(b: ByteArray): String = buildString(b.size * 2) {
        for (x in b) {
            append(HEX[(x.toInt() shr 4) and 0xF])
            append(HEX[x.toInt() and 0xF])
        }
    }

    fun sha256(b: ByteArray): ByteArray = MessageDigest.getInstance("SHA-256").digest(b)

    private val HEX = "0123456789ABCDEF".toCharArray()
}

/**
 * AES-256-GCM: الناتج = nonce (12) ‖ ciphertext ‖ tag (16).
 * الـ [aad] بيربط الصندوق بمكانه (ملف / بروفايل) عشان محدش يبدّل ملف بملف.
 */
object Aead {
    private const val NONCE = 12
    private const val TAG_BITS = 128

    fun seal(key: ByteArray, plain: ByteArray, aad: String): ByteArray {
        require(key.size == 32) { "key must be 32 bytes" }
        val nonce = Bytes.random(NONCE)
        val c = Cipher.getInstance("AES/GCM/NoPadding")
        c.init(Cipher.ENCRYPT_MODE, SecretKeySpec(key, "AES"), GCMParameterSpec(TAG_BITS, nonce))
        c.updateAAD(aad.toByteArray(Charsets.UTF_8))
        return nonce + c.doFinal(plain)
    }

    /** بيرمي [CoreError] (`BAD_DATA`) لو المفتاح غلط أو البيانات اتلعب فيها. */
    fun open(key: ByteArray, box: ByteArray, aad: String): ByteArray {
        require(key.size == 32) { "key must be 32 bytes" }
        if (box.size < NONCE + 16) throw CoreError(Err.BAD_DATA)
        return try {
            val c = Cipher.getInstance("AES/GCM/NoPadding")
            c.init(Cipher.DECRYPT_MODE, SecretKeySpec(key, "AES"), GCMParameterSpec(TAG_BITS, box, 0, NONCE))
            c.updateAAD(aad.toByteArray(Charsets.UTF_8))
            c.doFinal(box, NONCE, box.size - NONCE)
        } catch (e: AEADBadTagException) {
            throw CoreError(Err.BAD_DATA)
        } catch (e: javax.crypto.BadPaddingException) {
            throw CoreError(Err.BAD_DATA)
        }
    }
}

/** معاملات Argon2id (بتتخزن جنب الملح عشان نقدر نقوّيها بعدين من غير ما نكسر القديم). */
data class KdfParams(val memKiB: Int, val iterations: Int, val parallelism: Int, val salt: ByteArray) {
    fun toJson(): JSONObject = JSONObject()
        .put("alg", "argon2id")
        .put("m", memKiB)
        .put("t", iterations)
        .put("p", parallelism)
        .put("salt", Bytes.b64(salt))

    companion object {
        fun fromJson(o: JSONObject): KdfParams {
            if (o.optString("alg") != "argon2id") throw CoreError(Err.BAD_DATA)
            val p = KdfParams(o.getInt("m"), o.getInt("t"), o.getInt("p"), Bytes.unb64(o.getString("salt")))
            // ملف متلعب فيه ممكن يطلب ذاكرة مهولة ويوقّع التطبيق
            if (p.memKiB !in 8 * 1024..1024 * 1024 || p.iterations !in 1..20 || p.parallelism !in 1..8 ||
                p.salt.size !in 16..64
            ) {
                throw CoreError(Err.BAD_DATA)
            }
            return p
        }
    }

    override fun equals(other: Any?) = other is KdfParams && memKiB == other.memKiB &&
        iterations == other.iterations && parallelism == other.parallelism && salt.contentEquals(other.salt)

    override fun hashCode() = salt.contentHashCode()
}

/** القوة الافتراضية لاشتقاق المفاتيح من كلمات السر. التيستات بتستخدم [FAST]. */
data class KdfStrength(val memKiB: Int, val iterations: Int, val parallelism: Int) {
    fun fresh() = KdfParams(memKiB, iterations, parallelism, Bytes.random(16))

    companion object {
        /** 64 MiB، 3 دورات (أقوى من الحد الأدنى في توصيات OWASP). */
        val STANDARD = KdfStrength(64 * 1024, 3, 1)
        val FAST = KdfStrength(8 * 1024, 1, 1)
    }
}

object Kdf {
    /** يحوّل كلمة السر لـ NFC عشان نفس الكلمة تدي نفس المفتاح من أي كيبورد. */
    fun normalize(password: String): CharArray = Normalizer.normalize(password, Normalizer.Form.NFC).toCharArray()

    fun argon2id(password: CharArray, p: KdfParams): ByteArray {
        val params = Argon2Parameters.Builder(Argon2Parameters.ARGON2_id)
            .withVersion(Argon2Parameters.ARGON2_VERSION_13)
            .withIterations(p.iterations)
            .withMemoryAsKB(p.memKiB)
            .withParallelism(p.parallelism)
            .withSalt(p.salt)
            .build()
        val gen = Argon2BytesGenerator()
        gen.init(params)
        val out = ByteArray(32)
        gen.generateBytes(password, out)
        return out
    }
}
