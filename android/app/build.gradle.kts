import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties from key.properties file (if it exists)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.technexa.rhythmflow"
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
        applicationId = "com.technexa.rhythmflow"
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
        
        // FIX: Support for 16KB page size devices
        // Exclude x86 and x86_64 architectures (mainly for emulators)
        // These architectures have libraries incompatible with 16KB page size
        // Real Android devices use ARM architectures (armeabi-v7a, arm64-v8a)
        ndk {
            //noinspection ChromeOsAbiSupport
            // Only include ARM architectures - these support 16KB page size
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
            // Excluded: "x86", "x86_64" - incompatible with 16KB page size
        }
    }

    signingConfigs {
        // Release signing configuration using keystore
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Use release signing config if keystore exists, otherwise use debug (for development)
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Fallback to debug signing if key.properties not found
                signingConfig = signingConfigs.getByName("debug")
            }
            
            // Enable minification and obfuscation
            isMinifyEnabled = true
            isShrinkResources = true
            // Use proguard-android.txt instead of optimize to prevent aggressive optimizations
            // that might break JNI initialization
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
            
            // Disable debugging in release
            isDebuggable = false
        }
        
        debug {
            // Enable debugging
            isDebuggable = true
            isMinifyEnabled = false
        }
    }

    // aaptOptions {
    //     noCompress 'tflite'
    // }
    
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
        
        // IMPORTANT: Exclude 16KB incompatible libraries
        // Ensure FFmpegKit native libraries are properly included
        // This prevents conflicts when multiple libraries provide the same .so files
        jniLibs {
            useLegacyPackaging = true
            pickFirsts += listOf(
                "lib/**/libffmpegkit*.so",
                "lib/**/libffmpeg*.so",
                "lib/**/libabidetect*.so"
            )
            // Exclude 16KB incompatible libraries
            // Note: x86_64 is already excluded via abiFilters, but we explicitly exclude here too
            excludes += listOf(
                "lib/x86_64/libaudiotags.so",
                "lib/x86_64/libtensorflowlite_gpu_jni.so",
                "lib/x86_64/libtensorflowlite_jni.so",
                // Exclude arm64-v8a audiotags - it's incompatible with 16KB page size
                // The app has fallback metadata extraction that will work without this library
                // This only affects metadata quality, not core functionality
                "lib/arm64-v8a/libaudiotags.so"
            )
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