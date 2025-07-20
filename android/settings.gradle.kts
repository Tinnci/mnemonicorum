pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }  // 阿里云 Gradle 插件镜像
        maven { url = uri("https://maven.aliyun.com/repository/public") }         // 阿里云公共镜像
        maven { url = uri("https://maven.aliyun.com/repository/google") }         // 阿里云 Google 镜像
        maven { url = uri("https://mirrors.tencent.com/gradle-plugin") }         // 腾讯云镜像
        gradlePluginPortal()                                                     // 官方 Gradle 插件门户（必要，确保最新版本）
        google()                                                                 // Google 官方仓库
        mavenCentral()                                                           // Maven 中央仓库
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
