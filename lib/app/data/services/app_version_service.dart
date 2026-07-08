import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';

import '../../shared/utils/logger.dart';
import '../api_helper/api_service.dart';
import '../constants/api_endpoints.dart';

/// Outcome of a single app-version check.
///
///   * [upToDate]            — installed versionCode >= backend minVersionCode.
///   * [forceUpdateRequired] — installed versionCode < backend minVersionCode.
///   * [unknownFailOpen]     — anything went wrong (no network, parse error,
///                             timeout, garbage buildNumber). We DO NOT block
///                             the user in this case — the kiosk would brick
///                             itself the first time the master-data service
///                             hiccups. Treated as "let them through, try
///                             again next launch".
enum AppVersionStatus { upToDate, forceUpdateRequired, unknownFailOpen }

class AppVersionResult {
  final AppVersionStatus status;
  final int? installedVersionCode;
  final String? installedVersionName;
  final int? minVersionCode;
  final int? latestVersionCode;
  final String? latestVersionName;
  final String? apkUrl;
  final String? releaseNotesLo;
  final String? releaseNotesEn;

  const AppVersionResult({
    required this.status,
    this.installedVersionCode,
    this.installedVersionName,
    this.minVersionCode,
    this.latestVersionCode,
    this.latestVersionName,
    this.apkUrl,
    this.releaseNotesLo,
    this.releaseNotesEn,
  });

  const AppVersionResult.failOpen()
      : status = AppVersionStatus.unknownFailOpen,
        installedVersionCode = null,
        installedVersionName = null,
        minVersionCode = null,
        latestVersionCode = null,
        latestVersionName = null,
        apkUrl = null,
        releaseNotesLo = null,
        releaseNotesEn = null;
}

/// Checks the installed kiosk build against the backend-published minimum
/// build, and exposes the most recent result for synchronous reads by route
/// middleware (which cannot await).
class AppVersionService {
  AppVersionService._();
  static final AppVersionService instance = AppVersionService._();

  /// Cached most-recent outcome — read by [ForceUpdateMiddleware] when the
  /// user attempts to navigate into a gated route. `null` only before the
  /// very first [check] call (splash); after that it's always populated.
  AppVersionResult? lastResult;

  Future<AppVersionResult> check({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    // 1. Installed versionCode.
    //
    // `PackageInfo.fromPlatform()` is a method-channel call. It is
    // normally fast, but on a kiosk with other plugins fighting the
    // platform-channel queue at cold start (Bluetooth printer
    // reconnect, geolocator) the channel can stall for tens of
    // seconds. The timeout below caps the whole step.
    int installed = 0;
    String? installedName;
    try {
      final info = await PackageInfo.fromPlatform().timeout(timeout);
      installed = int.tryParse(info.buildNumber) ?? 0;
      installedName = info.version;
    } catch (e) {
      AppLogger.warning('App version check failed (fail-open): $e');
      lastResult = const AppVersionResult.failOpen();
      return lastResult!;
    }

    if (installed == 0) {
      AppLogger.warning(
        'App version check fail-open: buildNumber is not a valid int',
      );
      lastResult = const AppVersionResult.failOpen();
      return lastResult!;
    }

    // 2. Backend version manifest.
    Map<String, dynamic> body;
    try {
      body = await HelpersApi()
          .get(ApiEndpoints.appVersion)
          .timeout(timeout);
    } catch (e) {
      // Any failure — Timeout, Socket, Format, ApiException, anything —
      // is treated as fail-open. We never want a flaky master-data
      // service to brick the kiosk.
      AppLogger.warning('App version check failed (fail-open): $e');
      lastResult = const AppVersionResult.failOpen();
      return lastResult!;
    }

    // 3. Parse defensively. Never `int.parse`, never dot-access without
    //    null-aware: garbage in must not crash the launch path.
    try {
      final data = body['data'];
      if (data is! Map) {
        AppLogger.warning('App version check fail-open: data is not a map');
        lastResult = const AppVersionResult.failOpen();
        return lastResult!;
      }
      final android = data['android'];
      if (android is! Map) {
        AppLogger.warning('App version check fail-open: android block missing');
        lastResult = const AppVersionResult.failOpen();
        return lastResult!;
      }

      final minVersionCode = _asInt(android['minVersionCode']);
      final latestVersionCode = _asInt(android['latestVersionCode']);
      final latestVersionName = android['latestVersionName']?.toString();
      final apkUrl = android['apkUrl']?.toString();

      final releaseNotes = data['releaseNotes'];
      String? releaseLo;
      String? releaseEn;
      if (releaseNotes is Map) {
        releaseLo = releaseNotes['lo']?.toString();
        releaseEn = releaseNotes['en']?.toString();
      }

      if (minVersionCode == null) {
        AppLogger.warning(
          'App version check fail-open: minVersionCode missing/invalid',
        );
        lastResult = const AppVersionResult.failOpen();
        return lastResult!;
      }

      final status = minVersionCode > installed
          ? AppVersionStatus.forceUpdateRequired
          : AppVersionStatus.upToDate;

      lastResult = AppVersionResult(
        status: status,
        installedVersionCode: installed,
        installedVersionName: installedName,
        minVersionCode: minVersionCode,
        latestVersionCode: latestVersionCode,
        latestVersionName: latestVersionName,
        apkUrl: apkUrl,
        releaseNotesLo: releaseLo,
        releaseNotesEn: releaseEn,
      );
      return lastResult!;
    } catch (e) {
      AppLogger.warning('App version check failed (fail-open): $e');
      lastResult = const AppVersionResult.failOpen();
      return lastResult!;
    }
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
