package com.smartroute.app

import android.content.pm.PackageManager
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.maps.MapsInitializer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MAP_SUPPORT_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isGooglePlayServicesAvailable" -> {
                    result.success(hasSupportedGoogleMaps())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasSupportedGoogleMaps(): Boolean = try {
        val playServicesAvailable = GoogleApiAvailability.getInstance()
            .isGooglePlayServicesAvailable(this) == ConnectionResult.SUCCESS
        hasPlayStore() &&
            playServicesAvailable &&
            MapsInitializer.initialize(applicationContext) == ConnectionResult.SUCCESS
    } catch (_: Exception) {
        false
    }

    private fun hasPlayStore(): Boolean = try {
        packageManager.getApplicationInfo(PLAY_STORE_PACKAGE, 0).enabled
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    private companion object {
        const val MAP_SUPPORT_CHANNEL = "com.smartroute.app/map-support"
        const val PLAY_STORE_PACKAGE = "com.android.vending"
    }
}
