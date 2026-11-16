package com.adam.shen

import android.content.Intent
import androidx.fragment.app.FragmentActivity
import com.google.zxing.integration.android.IntentIntegrator
import io.flutter.plugin.common.MethodChannel

/**
 * مسح QR (بصمة مفتاح أو مفتاح عام) بمكتبة ZXing — مفتوحة بالكامل ومن غير خدمات جوجل.
 * الصورة مبتتحفظش في أي مكان؛ بيرجع النص بس.
 */
object QrScanner {
    private var pending: MethodChannel.Result? = null

    fun scan(activity: FragmentActivity, result: MethodChannel.Result) {
        pending?.success(null)
        pending = result
        @Suppress("DEPRECATION")
        IntentIntegrator(activity)
            .setDesiredBarcodeFormats(IntentIntegrator.QR_CODE)
            .setPrompt("")
            .setBeepEnabled(false)
            .setOrientationLocked(false)
            .initiateScan()
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        @Suppress("DEPRECATION")
        val r = IntentIntegrator.parseActivityResult(requestCode, resultCode, data) ?: return false
        pending?.success(r.contents?.take(64 * 1024))
        pending = null
        return true
    }
}
