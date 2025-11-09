# Flutter & Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Deferred components & Play Core (for minifyEnabled=true)
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.** { *; }

# Hive (Dart-only; safe to keep empty rules)
# (No Java classes required)
