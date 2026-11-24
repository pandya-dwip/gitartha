package com.gitartha.gitartha

import android.content.ActivityNotFoundException
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lets the "No internet connection" prompt open the system's network
        // settings (lib/core/network/internet_checker.dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "gitartha/network")
            .setMethodCallHandler { call, result ->
                if (call.method == "openNetworkSettings") {
                    result.success(openFirstAvailable(
                        Settings.ACTION_WIRELESS_SETTINGS,
                        Settings.ACTION_SETTINGS,
                    ))
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun openFirstAvailable(vararg actions: String): Boolean {
        for (action in actions) {
            try {
                startActivity(Intent(action).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return true
            } catch (_: ActivityNotFoundException) {
                // Try the next, more general settings screen.
            }
        }
        return false
    }
}
