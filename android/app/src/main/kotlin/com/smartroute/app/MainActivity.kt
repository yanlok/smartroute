package com.smartroute.app

import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.smartroute.app/google_maps_capability",
        ).setMethodCallHandler { call, result ->
            if (call.method != "isGoogleMapsAvailable") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val status = GoogleApiAvailability
                .getInstance()
                .isGooglePlayServicesAvailable(this)
            result.success(status == ConnectionResult.SUCCESS)
        }
    }
}
