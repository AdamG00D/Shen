package com.adam.shen

import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import androidx.fragment.app.FragmentActivity
import com.adam.shen.core.Api
import com.adam.shen.core.Bytes
import com.adam.shen.core.CoreError
import com.adam.shen.core.Err
import com.adam.shen.core.Streams
import com.adam.shen.core.Vault
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileNotFoundException
import java.util.concurrent.Executors

/** ملفات المستخدم عن طريق الـ Storage Access Framework (content://) — مفيش نسخ مؤقتة جوه التطبيق. */
class AndroidStreams(private val activity: FragmentActivity) : Streams {
    private val resolver get() = activity.contentResolver

    override fun open(uri: String) = try {
        resolver.openInputStream(Uri.parse(uri)) ?: throw CoreError(Err.IO)
    } catch (e: FileNotFoundException) {
        throw CoreError(Err.IO)
    } catch (e: SecurityException) {
        throw CoreError(Err.IO)
    }

    override fun create(uri: String) = try {
        resolver.openOutputStream(Uri.parse(uri), "wt") ?: throw CoreError(Err.IO)
    } catch (e: FileNotFoundException) {
        throw CoreError(Err.IO)
    } catch (e: SecurityException) {
        throw CoreError(Err.IO)
    }

    override fun delete(uri: String) {
        runCatching { DocumentsContract.deleteDocument(resolver, Uri.parse(uri)) }
    }
}

/**
 * قناة `shen/core`: كل نداء بيروح لـ [Api.call] على thread واحد في الخلفية (الواجهة متقفش،
 * ومفيش عمليتين على الخزنة في نفس الوقت). الأخطاء بتوصل كـ كود بس.
 */
class CoreChannel(private val activity: FragmentActivity, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    private val exec = Executors.newSingleThreadExecutor { r -> Thread(r, "shen-core").apply { isDaemon = true } }
    private val main = Handler(Looper.getMainLooper())
    private val bio = BioUnlock(activity)
    val api = Api(
        Vault(File(activity.noBackupFilesDir, "shen"), AndroidKeyWrapper()),
        AndroidStreams(activity),
    )

    init {
        MethodChannel(messenger, "shen/core").setMethodCallHandler(this)
    }

    /** لما التطبيق يتقفل خالص (أو النظام يقتله) نمسح المفاتيح من الذاكرة. */
    fun lockNow() {
        exec.execute { runCatching { api.lock() } }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        @Suppress("UNCHECKED_CAST")
        val args = (call.arguments as? Map<String, Any?>) ?: emptyMap()
        when (call.method) {
            "bioAvailable" -> result.success(bio.available())
            "bioEnable" -> bioEnable(args, result)
            "bioUnlock" -> bioUnlock(args, result)
            "bioDisable" -> run(result) {
                api.vault.bioBlob = null
                bio.delete()
                null
            }
            else -> run(result) {
                val r = api.call(call.method, args)
                if (call.method == "wipeAll") bio.delete()
                r
            }
        }
    }

    private fun run(result: MethodChannel.Result, block: () -> Any?) {
        exec.execute {
            try {
                val r = block()
                main.post { result.success(r) }
            } catch (e: CoreError) {
                main.post { result.error(e.code.name, e.message, mapOf("waitMs" to e.waitMs)) }
            } catch (e: OutOfMemoryError) {
                main.post { result.error(Err.TOO_LARGE.name, null, null) }
            } catch (e: Throwable) {
                // مبنبعتش رسالة الاستثناء: ممكن يكون فيها بيانات
                main.post { result.error("INTERNAL", e.javaClass.simpleName, null) }
            }
        }
    }

    /** يشفّر المفتاح الرئيسي بمفتاح البصمة (الخزنة لازم تكون مفتوحة). */
    private fun bioEnable(args: Map<String, Any?>, result: MethodChannel.Result) {
        if (!api.vault.isUnlocked) return result.error(Err.LOCKED.name, null, null)
        val cipher = try {
            bio.encryptCipher()
        } catch (e: Exception) {
            return result.error(Err.KEYSTORE.name, null, null)
        }
        bio.prompt(cipher, args["title"] as? String ?: "", args["subtitle"] as? String ?: "", args["cancel"] as? String ?: "") { c ->
            if (c == null) return@prompt result.error(Err.CANCELLED.name, null, null)
            run(result) {
                val mk = api.vault.masterKey().copyOf()
                try {
                    val ct = c.doFinal(mk)
                    api.vault.bioBlob = Bytes.b64(c.iv + ct)
                } finally {
                    Bytes.wipe(mk)
                }
                null
            }
        }
    }

    private fun bioUnlock(args: Map<String, Any?>, result: MethodChannel.Result) {
        exec.execute {
            val blob = runCatching { api.vault.bioBlob }.getOrNull()
            main.post {
                if (blob == null) return@post result.error("BIO_UNAVAILABLE", null, null)
                val box = Bytes.unb64(blob)
                val cipher = bio.decryptCipher(box.copyOfRange(0, 12))
                if (cipher == null) {
                    // بصمة جديدة اتضافت للموبايل: لازم كلمة السر
                    exec.execute { runCatching { api.vault.bioBlob = null } }
                    return@post result.error("BIO_INVALIDATED", null, null)
                }
                bio.prompt(cipher, args["title"] as? String ?: "", args["subtitle"] as? String ?: "", args["cancel"] as? String ?: "") { c ->
                    if (c == null) return@prompt result.error(Err.CANCELLED.name, null, null)
                    run(result) {
                        val mk = try {
                            c.doFinal(box, 12, box.size - 12)
                        } catch (e: Exception) {
                            throw CoreError(Err.WRONG_PASSWORD)
                        }
                        try {
                            api.unlockWithMasterKey(mk)
                        } finally {
                            Bytes.wipe(mk)
                        }
                        null
                    }
                }
            }
        }
    }
}
