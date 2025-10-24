plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")

    id("com.google.gms.google-services")
}

// Cargar propiedades de firma si existen
val keystorePropertiesFile = rootProject.file("android/app/key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.flutter_lab_support_incidents"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Configuración de firma consistente
    signingConfigs {
        create("release") {
            // Prioridad: archivo key.properties > variables de entorno > valores por defecto
            keyAlias = keystoreProperties.getProperty("keyAlias") 
                ?: System.getenv("SIGNING_KEY_ALIAS") 
                ?: "upt-lab-key"
            keyPassword = keystoreProperties.getProperty("keyPassword") 
                ?: System.getenv("SIGNING_KEY_PASSWORD") 
                ?: "upt123456"
            storeFile = file(keystoreProperties.getProperty("storeFile") 
                ?: System.getenv("SIGNING_STORE_PATH") 
                ?: "upt-lab-keystore.jks")
            storePassword = keystoreProperties.getProperty("storePassword") 
                ?: System.getenv("SIGNING_STORE_PASSWORD") 
                ?: "upt123456"
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.upt.flutter_lab_support_incidents"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Usar configuración de firma personalizada, fallback a debug si no existe el keystore
            signingConfig = if (file("upt-lab-keystore.jks").exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            minifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
