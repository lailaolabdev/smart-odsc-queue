# Flutter ProGuard/R8 Rules
# These rules suppress warnings for missing Google/AndroidX classes common in Flutter builds.

-dontwarn androidx.window.extensions.**
-dontwarn androidx.window.sidecar.**

# ota_update — the plugin reflects into its own FileProvider /
# InstallResultReceiver classes by string name when wiring up the
# Android intents. Without these keep rules R8 strips them and the
# force-update install step silently fails on release builds.
-keep class sk.fourq.otaupdate.** { *; }
-keepclassmembers class sk.fourq.otaupdate.** { *; }

# Firebase + GMS — keep their entry points so the analytics/messaging
# wiring survives R8. Cheap to leave on; expensive to debug if missing.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
