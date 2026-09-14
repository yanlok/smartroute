package com.smartroute.app

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.smartroute.app/maps",
        ).setMethodCallHandler { call, result ->
            if (call.method == "isGooglePlayServicesAvailable") {
                result.success(hasGooglePlayServices())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun hasGooglePlayServices(): Boolean = try {
        val availabilityClass =
            Class.forName("com.google.android.gms.common.GoogleApiAvailability")
        val availability = availabilityClass.getMethod("getInstance").invoke(null)
        val status = availabilityClass.getMethod(
            "isGooglePlayServicesAvailable",
            Context::class.java,
        ).invoke(availability, this) as Int
        status == 0
    } catch (_: Exception) {
        false
    }
}
