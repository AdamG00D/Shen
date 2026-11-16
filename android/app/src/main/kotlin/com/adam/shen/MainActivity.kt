package com.adam.shen

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    private var core: CoreChannel? = null
    private var system: SystemChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // مفيش سكرين شوت ولا تسجيل شاشة، والتطبيق بيظهر فاضي في قايمة التطبيقات المفتوحة
        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 33) setRecentsScreenshotEnabled(false)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        core = CoreChannel(this, messenger)
        system = SystemChannel(this, messenger).also { it.onIntent(intent) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        system?.onIntent(intent)
    }

    @Deprecated("SAF pickers use startActivityForResult")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (system?.onActivityResult(requestCode, resultCode, data) == true) return
        if (QrScanner.onActivityResult(requestCode, resultCode, data)) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        if (isFinishing) core?.lockNow()
        super.onDestroy()
    }
}
