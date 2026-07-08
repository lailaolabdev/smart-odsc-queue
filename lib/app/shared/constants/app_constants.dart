import 'package:flutter/material.dart';

class ColorConstants {
  static const Color mainCorlor = Color(0xFF3554A1);
  static const Color lightBlue = Color(0xFFE6F1FE);
  static const Color orange = Color(0xFFFF6533);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF6B7280);
  static const Color subGrey = Color(0XFF52525B);
  static const Color lightGrey = Color(0XFFF4F4F5);
  static const Color green = Color(0xFF34C759);
  static const Color transparent = Colors.transparent;
}

class AppConstants {
  static const String appName = 'Smart ODSC Queue';
  static const String appVersion = '1.0.0(1)';

  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);

  // Reference canvas the whole kiosk UI is hand-tuned for (logical points,
  // landscape) — measured directly off the actual test iPad. Every screen
  // is scaled to fit this box (see main.dart's GetMaterialApp.builder) so
  // a phone in landscape renders a miniature of the same iPad layout
  // instead of reflowing.
  static const Size designCanvasSize = Size(1280, 800);
}

class StorageKeys {
  static const String authToken = 'auth_token';
  static const String language = 'language';
}
