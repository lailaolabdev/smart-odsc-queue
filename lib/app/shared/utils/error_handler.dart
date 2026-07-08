import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';

import '../../data/api_helper/api_service.dart';
import 'logger.dart';

class ErrorHandler {
  ErrorHandler._();

  /// Maps any exception to a localized message safe to show to a kiosk
  /// operator. We deliberately NEVER return raw `e.toString()` because
  /// (1) those strings are always English and (2) they tend to leak
  /// stack-y internals like "SocketException: Connection refused, errno
  /// = 111, address = api.odsc..." which kiosk operators can't act on.
  ///
  /// The actual technical detail is logged via [AppLogger.warning] for
  /// debugging — it just doesn't reach the dialog.
  static String getMessage(Object e) {
    // Handle our own typed API errors first so we can map status codes
    // to localized messages instead of leaking "Instance of 'ApiException'"
    // through e.toString() into a user-facing dialog.
    if (e is ApiException) {
      final code = e.statusCode;
      AppLogger.warning('ApiException $code: ${e.message}');
      if (code != null) {
        final mapped = _fromStatusCode(code.toString());
        if (mapped != null) return mapped;
      }
      return 'error.unexpected'.tr;
    }

    if (e is HandshakeException) {
      AppLogger.warning('TLS handshake: ${e.message}');
      return 'error.tls'.tr;
    }

    if (e is SocketException) {
      final os = e.osError;
      final host = e.address?.host ?? '';
      AppLogger.warning(
        'SocketException: code=${os?.errorCode}, msg=${os?.message}, host=$host',
      );
      if (os != null) {
        final code = os.errorCode;
        if (code == 7 || os.message.toLowerCase().contains('hostname')) {
          return 'error.dns'.tr;
        }
        if (code == 111) return 'error.server_refused'.tr;
        if (code == 113 || code == 101) return 'error.server_unreachable'.tr;
        if (code == 110) return 'error.server_timeout'.tr;
        return 'error.network_generic'.tr;
      }
      return 'error.no_internet'.tr;
    }

    if (e is TimeoutException) return 'error.timeout'.tr;

    if (e is HttpException) {
      AppLogger.warning('HttpException: ${e.message}');
      return 'error.server_prefix'.tr;
    }

    if (e is FormatException) {
      AppLogger.warning('FormatException: ${e.message}');
      return 'error.bad_format'.tr;
    }

    if (e is TypeError) return 'error.bad_data'.tr;
    if (e is RangeError) return 'error.out_of_range'.tr;
    if (e is ArgumentError) return 'error.bad_argument'.tr;
    if (e is StateError) return 'error.bad_state'.tr;
    if (e is UnsupportedError) return 'error.unsupported'.tr;

    // Try to pull a status code out of an ApiException-like string. We
    // only return a mapped (localized) message — never the raw string,
    // even if the exception's message happens to be human-readable in
    // English, because mixing languages in the dialog is worse than
    // a generic Lao fallback.
    final raw = e.toString();
    AppLogger.warning('Unhandled exception in getMessage: $raw');
    final statusMessage = _fromStatusCode(raw);
    if (statusMessage != null) return statusMessage;

    return 'error.unexpected'.tr;
  }

  static String getHttpMessage(int statusCode) {
    return _fromStatusCode(statusCode.toString()) ??
        '${'error.http_generic_prefix'.tr} (HTTP $statusCode)';
  }

  static String? _fromStatusCode(String raw) {
    final trimmed = raw.trim();
    // Allow either a bare "404" or a string that contains "statusCode: 404"
    final match = RegExp(r'\b(\d{3})\b').firstMatch(trimmed);
    final code = match?.group(1) ?? trimmed;
    switch (code) {
      case '400':
        return '${'error.http_400'.tr} (400)';
      case '401':
        return '${'error.http_401'.tr} (401)';
      case '403':
        return '${'error.http_403'.tr} (403)';
      case '404':
        return '${'error.http_404'.tr} (404)';
      case '409':
        return '${'error.http_409'.tr} (409)';
      case '422':
        return '${'error.http_422'.tr} (422)';
      case '429':
        return '${'error.http_429'.tr} (429)';
      case '500':
        return '${'error.http_500'.tr} (500)';
      case '502':
      case '503':
      case '504':
        return 'error.http_5xx'.tr;
      default:
        return null;
    }
  }
}
