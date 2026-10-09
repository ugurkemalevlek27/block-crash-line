import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Production upload key: read from android/key.properties (never committed) or environment.
// key.properties keys: storeFile, storePassword, keyAlias, keyPassword
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
fun signingValue(name: String): String? =
    keystoreProperties.getProperty(name) ?: System.getenv("BLOCK_CRASH_" + name.uppercase())
val hasUploadKey = listOf("storeFile", "storePassword", "keyAlias", "keyPassword").all { signingValue(it) != null }

android {
    namespace = "com.uke.block_crash"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.uke.block_crash"
        minSdk = 21
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadKey) {
            create("upload") {
                storeFile = rootProject.file(signingValue("storeFile")!!)
                storePassword = signingValue("storePassword")
                keyAlias = signingValue("keyAlias")
                keyPassword = signingValue("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Signed only with the private upload key. Without key.properties the bundle is left
            // unsigned on purpose; the old public test keystore is no longer used.
            if (hasUploadKey) {
                signingConfig = signingConfigs.getByName("upload")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    packaging {
        // 16 KB page size: keep native libraries uncompressed and page-aligned.
        jniLibs {
            useLegacyPackaging = false
        }
    }
}

flutter {
    source = "../.."
}
