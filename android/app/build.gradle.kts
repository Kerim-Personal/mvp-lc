import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Keystore özelliklerini yükle (varsa)
val keystoreProperties = Properties()
val keystorePropertiesFileCandidates = listOf(
    rootProject.file("key.properties"),              // önerilen konum
    rootProject.file("android/key.properties"),      // geriye dönük uyumluluk
    rootProject.file("android/keystore.properties")  // eski isimle geriye dönük uyumluluk
)
val keystorePropertiesFile = keystorePropertiesFileCandidates.firstOrNull { it.exists() }
if (keystorePropertiesFile != null) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val hasReleaseKeystore = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .all { (keystoreProperties.getProperty(it)?.isNotBlank()) == true }

android {
    namespace = "com.codenzi.vocachat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Sizin yaptığınız değişiklik.

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.codenzi.vocachat"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Release imzası (keystore varsa devreye girer)
        create("release") {
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            if (storeFilePath != null && storeFilePath.isNotBlank()) {
                storeFile = file(storeFilePath)
            }
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            // keystore tam değilse debug imzasına düş
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // R8 ile küçültme ve kaynak kırpma
            isMinifyEnabled = true
            isShrinkResources = true

            // Optimize edilmiş varsayılan proguard kuralları + proje kuralları
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                file("proguard-rules.pro")
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // RevenueCat kullanırken Google Billing bağımlılığını ayrıca eklemeyin; plugin kendi sürümünü getirir.
}