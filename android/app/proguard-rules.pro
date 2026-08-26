# Keep Flutter & Dart runtime
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# Keep just_audio and ExoPlayer
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Keep file_picker SAF components
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-dontwarn com.mr.flutter.plugin.filepicker.**

# Keep permission_handler
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# Keep MainActivity
-keep class com.vibe.musicplayer.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keepattributes *Annotation*
-dontwarn kotlin.**
