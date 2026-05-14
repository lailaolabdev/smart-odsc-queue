import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:get_storage/get_storage.dart';

class JwtHelper {
  static const String _tokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';

  static String get tokenKey => _tokenKey;

  static bool isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      if (kDebugMode) print('Error checking token expiration: $e');
      return true;
    }
  }

  static Map<String, dynamic>? decodeToken(String token) {
    try {
      return JwtDecoder.decode(token);
    } catch (e) {
      if (kDebugMode) print('Error decoding token: $e');
      return null;
    }
  }

  static Map<String, dynamic>? getTokenPayload(String token) {
    return decodeToken(token);
  }

  static Future<void> saveToken(String token) async {
    await GetStorage().write(_tokenKey, token);
  }

  static Future<void> saveRefreshToken(String refreshToken) async {
    await GetStorage().write(_refreshTokenKey, refreshToken);
  }

  static String? getStoredToken() {
    return GetStorage().read(_tokenKey);
  }

  static String? getStoredRefreshToken() {
    return GetStorage().read(_refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    await GetStorage().remove(_tokenKey);
    await GetStorage().remove(_refreshTokenKey);
  }

  static bool hasValidToken() {
    final token = getStoredToken();
    return token != null && !isTokenExpired(token);
  }

  static bool willExpireInMinutes(String token, int minutes) {
    try {
      final expirationDate = JwtDecoder.getExpirationDate(token);
      return expirationDate.difference(DateTime.now()).inMinutes <= minutes;
    } catch (e) {
      return true;
    }
  }
}
