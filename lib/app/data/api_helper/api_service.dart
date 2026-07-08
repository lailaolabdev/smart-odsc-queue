import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';

import '../constants/api_endpoints.dart';
import '../interceptors/http_interceptors.dart';
import 'jwt_helper.dart';

class HelpersApi {
  static const Duration timeoutDuration = Duration(seconds: 30);

  late final InterceptedClient _client;
  late final AuthenticationInterceptor _authInterceptor;
  late final LoggingInterceptor _loggingInterceptor;
  late final ErrorHandlingInterceptor _errorInterceptor;
  late final CacheInterceptor _cacheInterceptor;

  static final HelpersApi _instance = HelpersApi._internal();
  factory HelpersApi() => _instance;

  HelpersApi._internal() {
    _initializeInterceptors();
    _setupClient();
  }

  void _initializeInterceptors() {
    _authInterceptor = AuthenticationInterceptor();
    _loggingInterceptor = LoggingInterceptor();
    _errorInterceptor = ErrorHandlingInterceptor();
    _cacheInterceptor = CacheInterceptor();
  }

  void _setupClient() {
    _client = InterceptedClient.build(
      interceptors: [
        _authInterceptor,
        _loggingInterceptor,
        _errorInterceptor,
        _cacheInterceptor,
      ],
      requestTimeout: timeoutDuration,
    );
  }

  Map<String, String> get _baseHeaders {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  void setAuthToken(String token) {
    _authInterceptor.setToken(token);
  }

  void clearAuthToken() {
    _authInterceptor.clearToken();
    JwtHelper.clearTokens();
  }

  Future<void> _checkAndRefreshToken() async {
    // ALWAYS sync the interceptor with the current stored token.
    //
    // The previous implementation only updated the interceptor when
    // the token was NOT about to expire — which meant:
    //   • After hot-restart, the singleton's in-memory token starts as
    //     null. If the stored token was within 5 min of expiry, the
    //     interceptor stayed null → request goes out without Bearer
    //     header → backend returns 401 → AuthInterceptor kicks user
    //     to /login. This was the cause of "switched account → feedback
    //     submit → bounced to login" reports.
    //   • After re-login on a kept-alive singleton, the in-memory
    //     token could lag behind storage.
    //
    // Real refresh logic (calling the refresh-token endpoint) would
    // still slot in here, but the sync must happen unconditionally.
    final token = JwtHelper.getStoredToken();
    if (token != null && token.isNotEmpty) {
      _authInterceptor.setToken(token);
    } else {
      _authInterceptor.clearToken();
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      await _checkAndRefreshToken();
      final response = await _client.post(
        Uri.parse('${ApiEndpoints.baseUrl}$endpoint'),
        headers: _baseHeaders,
        body: data != null ? jsonEncode(data) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// POST without the Authorization header.
  ///
  /// Used for endpoints that the `master-data` microservice rejects when
  /// presented with an officer token (cross-service JWT verify mismatch
  /// — see notes in [AuthenticationInterceptor]). Bypasses the
  /// interceptor stack entirely by using a plain `http.Client`.
  Future<Map<String, dynamic>> postPublic(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    final client = http.Client();
    try {
      final response = await client
          .post(
            Uri.parse('${ApiEndpoints.baseUrl}$endpoint'),
            headers: _baseHeaders,
            body: data != null ? jsonEncode(data) : null,
          )
          .timeout(timeoutDuration);
      return _handleResponse(response);
    } finally {
      client.close();
    }
  }

  Future<String> uploadImage(String filePath) async {
    try {
      await _checkAndRefreshToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.uploadImage}'),
      );

      final token = JwtHelper.getStoredToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(await http.MultipartFile.fromPath('image', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final result = _handleResponse(response);
      if (result['status'] == true && result['data'] != null) {
        return result['data']['imageName'] ?? "";
      }
      return "";
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      await _checkAndRefreshToken();
      final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint').replace(
        queryParameters: queryParameters?.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
      final response = await _client.get(uri, headers: _baseHeaders);
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'HTTP Error: ${response.statusCode}',
        response: response.body,
      );
    }
  }
}

class ApiException implements Exception {
  final int? statusCode;
  final String? message;
  final String? response;
  ApiException({
    required this.statusCode,
    required this.message,
    this.response,
  });

  // Without this override, e.toString() returns "Instance of 'ApiException'"
  // which (a) leaks into error dialogs when generic handlers call
  // toString() and (b) is useless in logs. Surface the status code so
  // the failure mode is always identifiable from a stack trace.
  @override
  String toString() => 'ApiException($statusCode): ${message ?? ''}';
}
