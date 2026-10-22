package com.example.ranah_mobile

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "ranah/phone_dialer"
        ).setMethodCallHandler { call, result ->
            if (call.method != "openDialer") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val number = call.argument<String>("number")
            if (number == null || !Regex("^[0-9]{3,5}$").matches(number)) {
                result.error("INVALID_NUMBER", "Nomor telepon tidak valid.", null)
                return@setMethodCallHandler
            }

            try {
                val intent = Intent(Intent.ACTION_DIAL, Uri.fromParts("tel", number, null))
                startActivity(intent)
                result.success(true)
            } catch (error: ActivityNotFoundException) {
                result.error("DIALER_UNAVAILABLE", "Aplikasi Telepon tidak tersedia.", null)
            }
        }
    }
}
