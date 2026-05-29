import java.io.File
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.caltrack.caltrack"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.caltrack.caltrack"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keystorePropsFile = rootProject.file("key.properties")
    val hasLocalKeyProps = keystorePropsFile.exists()
    val localProps = if (hasLocalKeyProps) {
        Properties().apply { load(keystorePropsFile.inputStream()) }
    } else null

    val envKeystoreB64 = System.getenv("RELEASE_KEYSTORE_BASE64")
    val envStorePass = System.getenv("RELEASE_KEYSTORE_PASSWORD")
    val envKeyAlias = System.getenv("RELEASE_KEY_ALIAS")
    val envKeyPass = System.getenv("RELEASE_KEY_PASSWORD")

    val hasEnvSigning = envKeystoreB64 != null && envStorePass != null && envKeyAlias != null && envKeyPass != null

    if (hasLocalKeyProps || hasEnvSigning) {
        signingConfigs.create("release") {
            if (hasLocalKeyProps) {
                storeFile = rootProject.file(localProps!!.getProperty("storeFile"))
                storePassword = localProps.getProperty("storePassword")
                keyAlias = localProps.getProperty("keyAlias")
                keyPassword = localProps.getProperty("keyPassword")
            } else {
                val decoded = Base64.getDecoder().decode(envKeystoreB64)
                val tempFile = File.createTempFile("release-keystore-", ".jks")
                tempFile.writeBytes(decoded)
                tempFile.deleteOnExit()
                storeFile = tempFile
                storePassword = envStorePass
                keyAlias = envKeyAlias
                keyPassword = envKeyPass
            }
        }
    }

    buildTypes {
        release {
            if (hasLocalKeyProps || hasEnvSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}