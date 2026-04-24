import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val androidNamespace = "com.krishnaanu.libraryapp"
val applicationIdValue = (
    providers.gradleProperty("LIBRARYAPP_APPLICATION_ID").orNull
        ?: System.getenv("LIBRARYAPP_APPLICATION_ID")
        ?: androidNamespace
    ).trim()
val appAuthRedirectScheme = (
    providers.gradleProperty("LIBRARYAPP_APP_AUTH_SCHEME").orNull
        ?: System.getenv("LIBRARYAPP_APP_AUTH_SCHEME")
        ?: applicationIdValue
    ).trim()

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun signingValue(propertyName: String, envName: String): String? {
    val propertyValue = keystoreProperties.getProperty(propertyName)?.trim().orEmpty()
    if (propertyValue.isNotEmpty()) {
        return propertyValue
    }

    val envValue = System.getenv(envName)?.trim().orEmpty()
    return envValue.ifEmpty { null }
}

val releaseStoreFile = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")
val releaseStorePassword = signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")
val hasReleaseSigning =
    listOf(
        releaseStoreFile,
        releaseStorePassword,
        releaseKeyAlias,
        releaseKeyPassword,
    ).all { !it.isNullOrBlank() }

if (!hasReleaseSigning) {
    logger.lifecycle(
        "Release signing credentials were not found. Release builds will use the debug keystore. " +
            "Add client/android/key.properties or ANDROID_KEYSTORE_* env vars for Play Store-ready builds.",
    )
}

android {
    namespace = androidNamespace
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
        applicationId = applicationIdValue
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders.putAll(
            mapOf(
                "appAuthRedirectScheme" to appAuthRedirectScheme,
            ),
        )
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(requireNotNull(releaseStoreFile))
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig =
                if (hasReleaseSigning) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

flutter {
    source = "../.."
}
