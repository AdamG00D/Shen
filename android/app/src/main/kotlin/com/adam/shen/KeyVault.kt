package com.adam.shen

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import com.adam.shen.core.CoreError
import com.adam.shen.core.Err
import com.adam.shen.core.KeyWrapper
import java.security.GeneralSecurityException
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

private fun keyStore(): KeyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }

/**
 * مفتاح AES-256 جوه Android Keystore (StrongBox لو الموبايل فيه) بيلف المفتاح الرئيسي للخزنة.
 * المفتاح ده مبيطلعش من الجهاز أبداً، فنسخ ملفات التطبيق لجهاز تاني مبيفيدش.
 */
class AndroidKeyWrapper : KeyWrapper {
    private val alias = "shen_vault"

    override fun wrap(plain: ByteArray): ByteArray {
        val key = existing() ?: create()
        val c = Cipher.getInstance("AES/GCM/NoPadding")
        c.init(Cipher.ENCRYPT_MODE, key)
        return c.iv + c.doFinal(plain)
    }

    override fun unwrap(box: ByteArray): ByteArray {
        val key = existing() ?: throw CoreError(Err.KEYSTORE)
        if (box.size < 12 + 16) throw CoreError(Err.KEYSTORE)
        return try {
            val c = Cipher.getInstance("AES/GCM/NoPadding")
            c.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, box, 0, 12))
            c.doFinal(box, 12, box.size - 12)
        } catch (e: GeneralSecurityException) {
            throw CoreError(Err.KEYSTORE)
        }
    }

    override fun reset() {
        runCatching { keyStore().deleteEntry(alias) }
    }

    private fun existing(): SecretKey? = keyStore().getKey(alias, null) as? SecretKey

    /** بنجرب الأقوى الأول: StrongBox + "الجهاز لازم يكون مفتوح"، وبعدين اللي أقل لو الموبايل مبيدعمش. */
    private fun create(): SecretKey {
        val attempts = listOf(true to true, true to false, false to true, false to false)
        for ((strongBox, unlocked) in attempts) {
            if (strongBox && Build.VERSION.SDK_INT < Build.VERSION_CODES.P) continue
            if (unlocked && Build.VERSION.SDK_INT < Build.VERSION_CODES.P) continue
            try {
                val gen = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
                gen.init(spec(strongBox, unlocked))
                val key = gen.generateKey()
                // نتأكد إنه شغال فعلاً (بعض الأجهزة بتعمل المفتاح وبعدين ترفض تستخدمه)
                val c = Cipher.getInstance("AES/GCM/NoPadding")
                c.init(Cipher.ENCRYPT_MODE, key)
                val box = c.iv + c.doFinal(ByteArray(8))
                val d = Cipher.getInstance("AES/GCM/NoPadding")
                d.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, box, 0, 12))
                d.doFinal(box, 12, box.size - 12)
                return key
            } catch (e: Exception) {
                runCatching { keyStore().deleteEntry(alias) }
            }
        }
        throw CoreError(Err.KEYSTORE)
    }

    private fun spec(strongBox: Boolean, unlocked: Boolean): KeyGenParameterSpec =
        KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .setRandomizedEncryptionRequired(true)
            .apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    if (strongBox) setIsStrongBoxBacked(true)
                    if (unlocked) setUnlockedDeviceRequired(true)
                }
            }
            .build()
}

/**
 * الفتح بالبصمة — **مربوط بالتشفير**: المفتاح الرئيسي متشفّر بمفتاح Keystore تاني مينفعش يتستخدم
 * غير بعد بصمة قوية (Class 3). يعني البصمة مش مجرد "آه / لأ"؛ من غيرها المفتاح نفسه مبيتفكش.
 * لو حد ضاف بصمة جديدة للموبايل المفتاح بيبوظ لوحده ولازم كلمة السر تاني.
 */
class BioUnlock(private val activity: FragmentActivity) {
    private val alias = "shen_bio"

    fun available(): Boolean =
        BiometricManager.from(activity).canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) ==
            BiometricManager.BIOMETRIC_SUCCESS

    /** مفتاح جديد كل مرة بنفعّل فيها البصمة. */
    fun encryptCipher(): Cipher {
        delete()
        val gen = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        gen.init(
            KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .setUserAuthenticationRequired(true)
                .setInvalidatedByBiometricEnrollment(true)
                .apply {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)
                    } else {
                        @Suppress("DEPRECATION")
                        setUserAuthenticationValidityDurationSeconds(-1)
                    }
                }
                .build(),
        )
        val c = Cipher.getInstance("AES/GCM/NoPadding")
        c.init(Cipher.ENCRYPT_MODE, gen.generateKey())
        return c
    }

    /** null = المفتاح مش موجود أو بقى مش صالح (بصمة جديدة اتضافت). */
    fun decryptCipher(iv: ByteArray): Cipher? {
        val key = keyStore().getKey(alias, null) as? SecretKey ?: return null
        return try {
            Cipher.getInstance("AES/GCM/NoPadding").apply { init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, iv)) }
        } catch (e: KeyPermanentlyInvalidatedException) {
            delete()
            null
        } catch (e: GeneralSecurityException) {
            null
        }
    }

    fun delete() {
        runCatching { keyStore().deleteEntry(alias) }
    }

    /** بيعرض نافذة البصمة. [done] بياخد الـ Cipher بعد ما اتفتح، أو null (اتلغى / فشل). */
    fun prompt(cipher: Cipher, title: String, subtitle: String, cancel: String, done: (Cipher?) -> Unit) {
        var answered = false
        fun answer(c: Cipher?) {
            if (answered) return
            answered = true
            done(c)
        }
        val prompt = BiometricPrompt(
            activity,
            ContextCompat.getMainExecutor(activity),
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) =
                    answer(result.cryptoObject?.cipher)

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) = answer(null)
            },
        )
        val info = BiometricPrompt.PromptInfo.Builder()
            .setTitle(title)
            .apply { if (subtitle.isNotEmpty()) setSubtitle(subtitle) }
            .setNegativeButtonText(cancel)
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            .setConfirmationRequired(false)
            .build()
        prompt.authenticate(info, BiometricPrompt.CryptoObject(cipher))
    }
}
