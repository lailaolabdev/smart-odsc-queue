import '../api_helper/api_service.dart';
import '../constants/api_endpoints.dart';

class AuthRepository {
  final HelpersApi _api = HelpersApi();

  Future<Map<String, dynamic>> loginOfficer({
    required String username,
    required String password,
  }) async {
    return await _api.post(
      ApiEndpoints.loginOfficer,
      data: {'userName': username, 'password': password},
    );
  }
}
