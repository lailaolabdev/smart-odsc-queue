import 'package:talker_flutter/talker_flutter.dart';

class AppLogger {
  static late Talker instance;
  static bool _isInitialized = false;

  static void init({required bool enabled}) {
    if (_isInitialized) return;

    instance = TalkerFlutter.init(
      settings: TalkerSettings(enabled: enabled, useConsoleLogs: enabled),
    );

    _isInitialized = true;
  }

  static void debug(String message, [Object? data]) {
    if (!_isInitialized) return;
    instance.debug(message, data);
  }

  static void info(String message, [Object? data]) {
    if (!_isInitialized) return;
    instance.info(message, data);
  }

  static void warning(String message, [Object? error]) {
    if (!_isInitialized) return;
    instance.warning(message, error);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (!_isInitialized) return;
    instance.error(message, error, stackTrace);
  }

  static void critical(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!_isInitialized) return;
    instance.critical(message, error, stackTrace);
  }

  static void setUserId(String userId) {}
  static void clearUserId() {}
}
