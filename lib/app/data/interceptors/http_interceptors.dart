import 'dart:convert';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:get/get.dart' hide Response;
import 'package:smart_odsc_queue/app/shared/utils/logger.dart';
import 'package:smart_odsc_queue/app/shared/utils/error_handler.dart';
import 'package:smart_odsc_queue/app/shared/widgets/custom_dialog.dart';

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
    }
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    if (response.statusCode == 401) {
      AppLogger.warning('🔐 Token expired - clearing');
      clearToken();
      Get.offAllNamed('/login');
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
