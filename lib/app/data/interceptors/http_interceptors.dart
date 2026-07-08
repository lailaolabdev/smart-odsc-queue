import 'package:http_interceptor/http_interceptor.dart';
import 'package:get/get.dart' hide Response;
import 'package:smart_odsc_queue/app/shared/utils/logger.dart';

class LoggingInterceptor implements InterceptorContract {
  @override
  Future<bool> shouldInterceptRequest() async => true;

  @override
  Future<bool> shouldInterceptResponse() async => true;

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    AppLogger.debug('🔗 ${request.method} ${request.url}');
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    AppLogger.debug('📥 ${response.statusCode} ${response.request?.url}');
    return response;
  }
}

class AuthenticationInterceptor implements InterceptorContract {
  String? _token;

  // Endpoints that may return 401 for non-session reasons (e.g. a
  // microservice with a different JWT secret) — we should NOT force
  // the user back to /login on 401 here, because their session is
  // still valid for the rest of the app.
  //
  // The login endpoints themselves are included: a 401 there means
  // "wrong credentials," not "session expired." Redirecting to /login
  // from a 401 on /auth/login-officer would cause the page to remount
  // mid-dialog (the loading spinner disappears, the error dialog
  // never shows) and erase the user's typed username.
  static const List<String> _skipAuthRedirectPaths = [
    '/master-data/feedback',
    '/auth/login-officer',
    '/auth/login-citizen',
  ];

  @override
  Future<bool> shouldInterceptRequest() async => true;

  @override
  Future<bool> shouldInterceptResponse() async => true;

  void setToken(String? token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    if (_token != null && _token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_token';
      // Preview-only logging. The full token used to be printed here
      // for Postman replay, but the multi-line interpolation of a
      // 200-500 char JWT through Talker fires synchronously on the UI
      // isolate for EVERY request — measurable jank on the kiosk's
      // mid-range Android, especially right when a user taps a button
      // that fires a network call (the dialog + keyboard + log all
      // race for the same frame). Length + 8-char prefix is enough to
      // confirm the right token is attached during debugging.
      final token = _token!;
      final preview = token.length >= 8 ? token.substring(0, 8) : token;
      AppLogger.debug(
        '🔑 Auth → ${request.url.path} (len=${token.length}, prefix=$preview…)',
      );
    } else {
      AppLogger.warning('⚠️  No auth token for ${request.url.path}');
    }
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    if (response.statusCode == 401) {
      final path = response.request?.url.path ?? '';
      final skip = _skipAuthRedirectPaths.any((p) => path.contains(p));
      if (skip) {
        AppLogger.warning(
          '🔐 401 on $path — NOT redirecting (likely cross-service auth issue)',
        );
      } else {
        AppLogger.warning('🔐 Token rejected on $path — clearing & logout');
        clearToken();
        Get.offAllNamed('/login');
      }
    }
    return response;
  }
}

class ErrorHandlingInterceptor implements InterceptorContract {
  @override
  Future<bool> shouldInterceptRequest() async => true;

  @override
  Future<bool> shouldInterceptResponse() async => true;

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    if (response.statusCode >= 400) {
      AppLogger.warning(
        '⚠️ HTTP Error ${response.statusCode}: ${response.request?.url}',
      );
    }
    return response;
  }
}

class CacheInterceptor implements InterceptorContract {
  @override
  Future<bool> shouldInterceptRequest() async => true;

  @override
  Future<bool> shouldInterceptResponse() async => true;

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    return response;
  }

  void clearCache() {}
  void removeCacheEntry(String url) {}
}
