plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

// Google Play upload key: never in the repo (same setup as Hoeveelishet). Without the
// key a release build is debug-signed: fine locally, refused by Google Play.
val uploadStoreFile = file("${System.getProperty("user.home")}/.android-keys/pibbles-upload.jks")
val uploadStorePassword = providers.gradleProperty("PIBBLES_UPLOAD_STORE_PASSWORD").orNull
val uploadKeyPassword = providers.gradleProperty("PIBBLES_UPLOAD_KEY_PASSWORD").orNull
val hasUploadKey = uploadStoreFile.exists() && uploadStorePassword != null && uploadKeyPassword != null

android {
    namespace = "app.pibbles.android"
    compileSdk = 37

    defaultConfig {
        applicationId = "app.pibbles"
        minSdk = 28
        targetSdk = 36
        versionCode = 1
        versionName = "0.1"
    }

    signingConfigs {
        if (hasUploadKey) {
            create("upload") {
                storeFile = uploadStoreFile
                storePassword = uploadStorePassword
                keyAlias = "upload"
                keyPassword = uploadKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // No R8 yet: Skip reflects on generated classes (as in Hoeveelishet)
            isMinifyEnabled = false
            signingConfig = if (hasUploadKey) signingConfigs.getByName("upload") else signingConfigs.getByName("debug")
        }
    }

    buildFeatures {
        compose = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

dependencies {
    implementation("pibbles.ui:PibblesUI") {
        // Skip exports its test runner transitively; keep it out of the app
        exclude(group = "androidx.test")
        exclude(group = "androidx.test.ext")
        exclude(group = "androidx.test.espresso")
    }
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.activity:activity-ktx:1.9.3")
}
