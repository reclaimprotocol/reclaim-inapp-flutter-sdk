pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "1.8.22" apply false
}

include(":app")

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    val flutterStorageUrl: String = System.getenv("FLUTTER_STORAGE_BASE_URL") ?: "https://storage.googleapis.com"
    val reclaimStorageUrl: String = System.getenv("RECLAIM_STORAGE_BASE_URL") ?: "https://reclaim-inapp-sdk.s3.ap-south-1.amazonaws.com/android/repo"
    repositories {
        google()
        mavenCentral()
        maven(url = reclaimStorageUrl)
        maven(url = "$flutterStorageUrl/download.flutter.io")
        maven(url = "/Users/mushaheedsyed/Projects/reclaimprotocol.org/inapp/reclaim_inapp_sdk_android/dist/library/0.5.1/repo")
    }
}
