import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final storage = const FlutterSecureStorage();

  // Keys
  final String _username = 'username';
  final String _password = 'password';

  Future<void> clearStorage() async => await storage.deleteAll();

  Future<void> setUsername(String username) async =>
      await storage.write(key: _username, value: username);

  Future<String?> getUsername() async => await storage.read(key: _username);

  Future<void> setPassword(String password) async =>
      await storage.write(key: _password, value: password);

  Future<String?> getPassword() async => await storage.read(key: _password);
}
