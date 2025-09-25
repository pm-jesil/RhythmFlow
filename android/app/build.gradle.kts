plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pmj.music_player"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.pmj.music_player"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // MultiDex support for large apps
        multiDexEnabled = true
        
        // Vector drawables support
        vectorDrawables.useSupportLibrary = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // Enable minification and obfuscation
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        
        debug {
            // Enable debugging
            isDebuggable = true
            isMinifyEnabled = false
        }
    }
    
    // Enable view binding
    buildFeatures {
        viewBinding = true
    }
    
    // Packaging options
    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            excludes += "META-INF/DEPENDENCIES"
            excludes += "META-INF/LICENSE"
            excludes += "META-INF/LICENSE.txt"
            excludes += "META-INF/license.txt"
            excludes += "META-INF/NOTICE"
            excludes += "META-INF/NOTICE.txt"
            excludes += "META-INF/notice.txt"
            excludes += "META-INF/ASL2.0"
            excludes += "META-INF/*.kotlin_module"
        }
    }
    
    // Lint options
    lint {
        disable += "InvalidPackage"
        checkReleaseBuilds = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    // MultiDex support
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Media session support for audio_service
    implementation("androidx.media:media:1.7.0")
    
    // Work manager for background tasks
    implementation("androidx.work:work-runtime-ktx:2.9.0")
    
    // Lifecycle components
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.7.0")
    
    // Room database (if needed for future features)
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    
    // Coroutines support
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}
