import java.nio.file.Files
import java.util.Base64

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun loadReleaseSigningConfig(): SigningConfig? {
    // 1. Local development: key.properties
    val propsFile = rootProject.file("key.properties")
    if (propsFile.exists()) {
        val props = java.util.Properties().apply { load(propsFile.inputStream()) }
        val storeFile = rootProject.file(props["storeFile"] as String)
        if (storeFile.exists()) {
            return signingConfigs.create("release") {
                storeFile = storeFile
                storePassword = props["storePassword"] as String
                keyAlias = props["keyAlias"] as String
                keyPassword = props["keyPassword"] as String
            }
        }
    }

    // 2. CI / GitHub Actions: decode keystore from env var
    val keystoreB64 = System.getenv("RELEASE_KEYSTORE_BASE64")
    val storePass = System.getenv("RELEASE_KEYSTORE_PASSWORD")
    val keyAliasName = System.getenv("RELEASE_KEY_ALIAS")
    val keyPass = System.getenv("RELEASE_KEY_PASSWORD")

    if (keystoreB64 != null && storePass != null && keyAliasName != null && keyPass != null) {
        val decoded = Base64.getDecoder().decode(keystoreB64)
        val tempFile = java.io.File.createTempFile("release-keystore-", ".jks")
        Files.write(tempFile.toPath(), decoded)
        tempFile.deleteOnExit()
        return signingConfigs.create("release") {
            storeFile = tempFile
            storePassword = storePass
            keyAlias = keyAliasName
            keyPassword = keyPass
        }
    }

    return null
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

    buildTypes {
        release {
            signingConfig = loadReleaseSigningConfig()
                ?: signingConfigs.getByName("debug")

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
