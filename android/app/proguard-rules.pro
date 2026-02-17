# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Audio Service rules (required for notification/lock screen on Android 14+)
-keep class com.ryanheise.audioservice.** { *; }
-keep class androidx.media.** { *; }
-keep class com.ryanheise.audioservice.AudioService { *; }
-keep class com.ryanheise.audioservice.MediaButtonReceiver { *; }
-keep class com.ryanheise.audioservice.MediaBrowserActivity { *; }

# Just Audio rules
-keep class com.ryanheise.just_audio.** { *; }

# Permission Handler rules
-keep class com.baseflow.permissionhandler.** { *; }

# File Picker rules
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Device Info Plus rules
-keep class dev.fluttercommunity.plus.device_info.** { *; }

# Path Provider rules
-keep class io.flutter.plugins.pathprovider.** { *; }

# Shared Preferences rules
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Hive rules
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }
-keep class * implements androidx.hilt.lifecycle.ViewModelInject { *; }

# JSON Serialization rules
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Freezed rules
-keep class **$** {
    *;
}
-keepclassmembers class * {
    @freezed *;
}

# Equatable rules (Flutter packages are already compiled, no ProGuard rules needed)
# -keep class * implements package:equatable.** { *; }

# Bloc rules (Flutter packages are already compiled, no ProGuard rules needed)
# -keep class * extends package:flutter_bloc.** { *; }
# -keep class * implements package:flutter_bloc.** { *; }

# Go Router rules (Flutter packages are already compiled, no ProGuard rules needed)
# -keep class * extends package:go_router.** { *; }

# Lottie rules
-keep class com.airbnb.lottie.** { *; }

# Cached Network Image rules
-keep class com.github.bumptech.glide.** { *; }
-keep class com.github.bumptech.glide.load.** { *; }

# Shimmer rules
-keep class com.facebook.shimmer.** { *; }

# Carousel Slider rules
-keep class com.serenegiant.widget.** { *; }

# Photo View rules
-keep class com.github.chrisbanes.photoview.** { *; }

# Flutter Slidable rules
-keep class com.tencent.mmkv.** { *; }

# Pull to Refresh rules
-keep class com.handmark.pulltorefresh.** { *; }

# Flutter SVG rules
-keep class com.caverock.androidsvg.** { *; }

# Animated Bottom Navigation Bar rules
-keep class com.tuannguyen.flutter_bloc.** { *; }

# Flutter Animate rules
-keep class com.rive.rive.** { *; }

# Device Calendar rules
-keep class com.builttoroam.devicecalendar.** { *; }

# Connectivity Plus rules
-keep class io.flutter.plugins.connectivity.** { *; }

# Package Info Plus rules
-keep class dev.fluttercommunity.plus.package_info.** { *; }

# Crypto rules
-keep class * implements java.security.MessageDigest { *; }

# UUID rules
-keep class java.util.UUID { *; }

# Intl rules
-keep class com.ibm.icu.** { *; }

# Logger rules (Flutter packages are already compiled, no ProGuard rules needed)
# -keep class * implements package:logger.** { *; }

# Dartz rules (Flutter packages are already compiled, no ProGuard rules needed)
# -keep class * implements package:dartz.** { *; }

# RxDart rules
-keep class io.reactivex.** { *; }
-keep class rx.** { *; }

# Dio rules
-keep class io.flutter.plugins.connectivity.** { *; }

# Flutter Cache Manager rules
-keep class com.github.bumptech.glide.** { *; }

# Image rules
-keep class com.github.bumptech.glide.** { *; }

# General Android rules
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Keep native methods - CRITICAL for JNI
# This preserves all native methods with full signatures (needed for JNI)
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# Keep JNI OnLoad and OnUnload methods (critical for native library initialization)
# These are entry points that native libraries call when loading
-keepclasseswithmembernames class * {
    public static *** JNI_OnLoad(...);
    public static *** JNI_OnUnLoad(...);
}

# Keep enum values
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable implementations
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R classes
-keep class **.R$* {
    public static <fields>;
}

# Keep custom application class
-keep class com.technexa.rhythmflow.** { *; }

# Keep model classes
-keep class **.models.** { *; }
-keep class **.entities.** { *; }
-keep class **.data.** { *; }

# Keep service classes
-keep class **.services.** { *; }
-keep class **.repository.** { *; }

# Keep utility classes
-keep class **.utils.** { *; }
-keep class **.helpers.** { *; }

# Keep constants
-keep class **.constants.** { *; }

# Keep extensions
-keep class **.extensions.** { *; }

# Keep generated files
-keep class **.g.dart { *; }
-keep class **.freezed.dart { *; }
-keep class **.config.dart { *; }

# Optimizations
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Google Play Core (optional, not needed for basic apps)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-keep class com.google.android.play.core.** { *; }

# TensorFlow Lite GPU (optional, only needed if using GPU acceleration)
-dontwarn org.tensorflow.lite.gpu.**
-keep class org.tensorflow.lite.gpu.** { *; }

# ============================================================================
# FFmpegKit Rules - CRITICAL for release builds
# ============================================================================
# FFmpegKit is a transitive dependency (from music_feature_analyzer)
# These rules prevent crashes in release builds

# Keep all FFmpegKit classes
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-keep class com.ffmpegkit.** { *; }
-keep class org.chromium.support_lib_boundary.** { *; }

# Keep FFmpegKit native methods
-keepclasseswithmembernames class com.antonkarpenko.ffmpegkit.** {
    native <methods>;
}

# Keep AbiDetect class (critical for native library loading)
-keep class com.antonkarpenko.ffmpegkit.AbiDetect { *; }
-keep class com.antonkarpenko.ffmpegkit.FFmpegKitConfig { *; }
-keep class com.antonkarpenko.ffmpegkit.FFmpegKitFlutterPlugin { *; }

# Don't warn about missing classes (FFmpegKit has optional dependencies)
-dontwarn com.antonkarpenko.ffmpegkit.**
-dontwarn com.ffmpegkit.**
-dontwarn org.chromium.support_lib_boundary.**

# Keep native library loading methods
-keepclassmembers class * {
    native <methods>;
}

# Preserve JNI method names and signatures
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# Keep all reflection-accessed classes (FFmpegKit uses reflection)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep class names for native code (JNI uses class names)
-keepnames class * {
    native <methods>;
}
