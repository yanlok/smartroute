import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")

    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}
val mapsProperties = Properties()
val mapsPropertiesFile = rootProject.file("maps.properties")
if (mapsPropertiesFile.exists()) {
    mapsPropertiesFile.inputStream().use { mapsProperties.load(it) }
}

fun findDartDefine(key: String): String? {
    val raw = project.findProperty("dart-defines") as? String ?: return null
    return try {
        for (part in raw.split(",")) {
            val decoded = String(Base64.getDecoder().decode(part.trim()))
            if (decoded.startsWith("$key=")) {
                return decoded.substringAfter("$key=")
            }
        }
        null
    } catch (_: Exception) {
        null
    }
}

val mapsApiKey = (
    localProperties.getProperty("MAPS_API_KEY")?.takeIf { it.isNotBlank() }
        ?: findDartDefine("MAPS_API_KEY")?.takeIf { it.isNotBlank() }
        ?: (project.findProperty("MAPS_API_KEY") as? String)?.takeIf { it.isNotBlank() }
        ?: System.getenv("MAPS_API_KEY")?.takeIf { it.isNotBlank() }
        ?: mapsProperties.getProperty("MAPS_API_KEY", "")
)

android {
    namespace = "com.smartroute.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.smartroute.app"


        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {


            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.gms:play-services-base:18.5.0")
}
