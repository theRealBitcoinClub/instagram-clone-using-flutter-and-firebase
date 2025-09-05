import com.android.build.api.dsl.ApplicationExtension
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read flutter properties from local.properties
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(localPropertiesFile.inputStream())
}

// Read keystore properties from environment variables or local.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

val flutterCompileSdkVersion = localProperties.getProperty("flutter.compileSdkVersion")?.toInt() ?: 36
val flutterMinSdkVersion = localProperties.getProperty("flutter.minSdkVersion")?.toInt() ?: 27
val flutterTargetSdkVersion = localProperties.getProperty("flutter.targetSdkVersion")?.toInt() ?: 35
val flutterNdkVersion = localProperties.getProperty("flutter.ndkVersion") ?: "27.0.12077973"
val flutterVersionCode = localProperties.getProperty("flutter.versionCode")?.toInt() ?: 2025090507
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.1.1-BCH"

android {
    namespace = "com.mahakka"
    compileSdk = flutterCompileSdkVersion
    ndkVersion = flutterNdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            // Try to get from environment variables first (for CI/CD)
            storeFile = file(System.getenv("STORE_FILE") ?: keystoreProperties.getProperty("storeFile") ?: "mahakka.keystore")
            storePassword = System.getenv("STORE_PASSWORD") ?: keystoreProperties.getProperty("storePassword") ?: ""
            keyAlias = System.getenv("KEY_ALIAS") ?: keystoreProperties.getProperty("keyAlias") ?: "mahakka"
            keyPassword = System.getenv("KEY_PASSWORD") ?: keystoreProperties.getProperty("keyPassword") ?: ""
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mahakka"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutterMinSdkVersion
        targetSdk = flutterTargetSdkVersion
        versionCode = 2025090507
        versionName = "1.1.1-BCH"
    }

    buildTypes {
        release {
            // Use release signing config if keystore is available
            signingConfig = if (file(signingConfigs.getByName("release").storeFile.absolutePath).exists() &&
                !signingConfigs.getByName("release").storePassword.isNullOrEmpty()) {
                signingConfigs.getByName("release")
            } else {
                // Fallback to debug signing if release config is not available
                signingConfigs.getByName("debug")
            }

            // Optional: Add proguard rules for release build
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }

        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}