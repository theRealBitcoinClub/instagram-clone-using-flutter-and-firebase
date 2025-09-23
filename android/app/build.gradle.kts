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

val flutterCompileSdkVersion = 36
val flutterMinSdkVersion = 27
val flutterTargetSdkVersion = 36
val flutterNdkVersion = "27.0.12077973"
val flutterVersionCode = 2025092303
val flutterVersionName = "2.8.1-BCH"

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
            // Use the same variable names as in Codemagic script
            val storeFileEnv = System.getenv("STORE_FILE") ?: keystoreProperties.getProperty("storeFile")
            val storePasswordEnv = System.getenv("STORE_PASSWORD") ?: keystoreProperties.getProperty("storePassword")
            val keyAliasEnv = System.getenv("KEY_ALIAS") ?: keystoreProperties.getProperty("keyAlias")
            val keyPasswordEnv = System.getenv("KEY_PASSWORD") ?: keystoreProperties.getProperty("keyPassword")

            if (storeFileEnv != null) {
                storeFile = file(storeFileEnv)
                println("Using store file: $storeFileEnv")
            } else {
                // Fallback to relative path if env var not set
                storeFile = file("mahakka.keystore")
                println("Using default store file: mahakka.keystore")
            }
            if (storePasswordEnv != null) {
                storePassword = storePasswordEnv
                println("Store password is set")
            }
            if (keyAliasEnv != null) {
                keyAlias = keyAliasEnv
                println("Key alias: $keyAliasEnv")
            }
            if (keyPasswordEnv != null) {
                keyPassword = keyPasswordEnv
                println("Key password is set")
            }

            // Debug output to see what's being used
            println("Signing config - Store file: ${storeFile?.name}")
            println("Signing config - Has store password: ${storePassword?.isNotEmpty()}")
            println("Signing config - Key alias: $keyAlias")
            println("Signing config - Has key password: ${keyPassword?.isNotEmpty()}")
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mahakka"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutterMinSdkVersion
        targetSdk = flutterTargetSdkVersion
        versionCode = flutterVersionCode
        versionName = flutterVersionName
    }

    buildTypes {
        release {
            // Use release signing config if properly configured
            val releaseSigningConfig = signingConfigs.getByName("release")
            signingConfig = if (releaseSigningConfig.storeFile != null &&
                releaseSigningConfig.storePassword?.isNotEmpty() == true &&
                releaseSigningConfig.keyAlias?.isNotEmpty() == true &&
                releaseSigningConfig.keyPassword?.isNotEmpty() == true) {
                println("Using RELEASE signing configuration")
                releaseSigningConfig
            } else {
                // Fallback to debug signing if release config is not available
                println("Falling back to DEBUG signing configuration")
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