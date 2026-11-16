package com.adam.shen

import android.app.Activity
import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PersistableBundle
import android.provider.OpenableColumns
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * قناة `shen/system`: اختيار ملفات (SAF)، قراية / كتابة ملفات صغيرة (مفاتيح .asc)، المشاركة،
 * الحافظة الحساسة، والحاجات اللي جاية من تطبيقات تانية (Share / افتح بـ).
 */
class SystemChannel(private val activity: FragmentActivity, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "shen/system")
    private val io = Executors.newSingleThreadExecutor { r -> Thread(r, "shen-io").apply { isDaemon = true } }
    private val main = Handler(Looper.getMainLooper())
    private var pending: MethodChannel.Result? = null
    private var pendingKind = 0
    private var incoming: Map<String, Any?>? = null
    private var clipCleaner: Runnable? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickOpen" -> pick(result, REQ_OPEN, Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "*/*"
            })
            "pickCreate" -> pick(result, REQ_CREATE, Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = call.argument<String>("mime") ?: "application/octet-stream"
                putExtra(Intent.EXTRA_TITLE, call.argument<String>("name") ?: "file")
            })
            "readUri" -> background(result) {
                val max = (call.argument<Number>("max") ?: 8 * 1024 * 1024).toInt()
                activity.contentResolver.openInputStream(Uri.parse(call.argument<String>("uri")))?.use { s ->
                    val b = s.readNBytes(max + 1)
                    if (b.size > max) throw IllegalStateException("TOO_LARGE")
                    b
                }
            }
            "writeUri" -> background(result) {
                activity.contentResolver.openOutputStream(Uri.parse(call.argument<String>("uri")), "wt")?.use {
                    it.write(call.argument<ByteArray>("data") ?: ByteArray(0))
                }
                true
            }
            "fileInfo" -> background(result) { fileInfo(Uri.parse(call.argument<String>("uri"))) }
            "shareText" -> {
                val send = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, call.argument<String>("text") ?: "")
                }
                activity.startActivity(Intent.createChooser(send, call.argument<String>("title")))
                result.success(true)
            }
            "copy" -> {
                copy(call.argument<String>("text") ?: "", call.argument<Boolean>("sensitive") ?: true, call.argument<Int>("clearAfter") ?: 45)
                result.success(true)
            }
            "takeIncoming" -> {
                result.success(incoming)
                incoming = null
            }
            "openUrl" -> {
                runCatching { activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(call.argument<String>("url")))) }
                result.success(true)
            }
            "scanQr" -> QrScanner.scan(activity, result)
            else -> result.notImplemented()
        }
    }

    // ---------------- اختيار الملفات ----------------

    private fun pick(result: MethodChannel.Result, kind: Int, intent: Intent) {
        pending?.success(null)
        pending = result
        pendingKind = kind
        try {
            activity.startActivityForResult(intent, kind)
        } catch (e: Exception) {
            pending = null
            result.success(null)
        }
    }

    /** من [MainActivity.onActivityResult]. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQ_OPEN && requestCode != REQ_CREATE) return false
        val r = pending ?: return true
        pending = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            r.success(null)
            return true
        }
        background(r) { fileInfo(uri) }
        return true
    }

    private fun fileInfo(uri: Uri): Map<String, Any?> {
        var name: String? = null
        var size: Long? = null
        runCatching {
            activity.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use { c ->
                if (c.moveToFirst()) {
                    name = c.getString(0)
                    size = if (c.isNull(1)) null else c.getLong(1)
                }
            }
        }
        return mapOf("uri" to uri.toString(), "name" to (name ?: uri.lastPathSegment ?: "file"), "size" to size)
    }

    // ---------------- حاجات جاية من برا ----------------

    /** Share → شِن، أو "افتح بـ" ملف .asc / .pgp / .sig. */
    fun onIntent(intent: Intent?) {
        val data = parseIntent(intent) ?: return
        incoming = data
        channel.invokeMethod("incoming", null)
    }

    private fun parseIntent(intent: Intent?): Map<String, Any?>? {
        intent ?: return null
        return when (intent.action) {
            Intent.ACTION_SEND -> {
                val text = intent.getStringExtra(Intent.EXTRA_TEXT)
                @Suppress("DEPRECATION")
                val stream = if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                }
                when {
                    stream != null -> fileInfo(stream) + mapOf("kind" to "file")
                    !text.isNullOrEmpty() -> mapOf("kind" to "text", "text" to text.take(10 * 1024 * 1024))
                    else -> null
                }
            }
            Intent.ACTION_VIEW -> intent.data?.let { fileInfo(it) + mapOf("kind" to "file") }
            else -> null
        }
    }

    // ---------------- الحافظة ----------------

    /**
     * بيعلّم النص "حساس" (أندرويد 13+ ميعرضش المحتوى في معاينة الحافظة)، وبيمسحه بعد [clearAfter] ثانية
     * لو محدش نسخ حاجة تانية مكانه.
     */
    private fun copy(text: String, sensitive: Boolean, clearAfter: Int) {
        val cm = activity.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText("Shen", text)
        if (sensitive) {
            clip.description.extras = PersistableBundle().apply {
                putBoolean(if (Build.VERSION.SDK_INT >= 33) ClipDescription.EXTRA_IS_SENSITIVE else "android.content.extra.IS_SENSITIVE", true)
            }
        }
        cm.setPrimaryClip(clip)
        clipCleaner?.let(main::removeCallbacks)
        if (!sensitive || clearAfter <= 0) return
        val mine = clip.description.timestamp.takeIf { Build.VERSION.SDK_INT >= 26 }
        val cleaner = Runnable {
            runCatching {
                val current = cm.primaryClipDescription
                // لو اتنسخ حاجة تانية بعدنا منمسحهاش
                if (mine != null && current != null && current.timestamp != mine) return@Runnable
                if (Build.VERSION.SDK_INT >= 28) cm.clearPrimaryClip() else cm.setPrimaryClip(ClipData.newPlainText("", ""))
            }
        }
        clipCleaner = cleaner
        main.postDelayed(cleaner, clearAfter * 1000L)
    }

    private fun background(result: MethodChannel.Result, block: () -> Any?) {
        io.execute {
            try {
                val r = block()
                main.post { result.success(r) }
            } catch (e: IllegalStateException) {
                main.post { result.error(e.message ?: "IO", null, null) }
            } catch (e: Throwable) {
                main.post { result.error("IO", null, null) }
            }
        }
    }

    companion object {
        private const val REQ_OPEN = 7101
        private const val REQ_CREATE = 7102
    }
}
