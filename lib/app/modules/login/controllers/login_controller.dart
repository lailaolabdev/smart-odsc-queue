import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:smart_odsc_queue/app/data/api_helper/api_service.dart';
import 'package:smart_odsc_queue/app/data/api_helper/jwt_helper.dart';
import 'package:smart_odsc_queue/app/data/models/user_model.dart';
import 'package:smart_odsc_queue/app/data/repositories/auth_repository.dart';
import 'package:smart_odsc_queue/app/shared/utils/secure_storage_service.dart';
import 'package:smart_odsc_queue/app/shared/widgets/custom_dialog.dart';
import 'package:smart_odsc_queue/app/shared/utils/error_handler.dart';
import 'package:smart_odsc_queue/app/shared/utils/logger.dart';

class LoginController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  final SecureStorageService _secureStorage = SecureStorageService();

  final usernameController = TextEditingController(text: '');
  final passwordController = TextEditingController(text: '');

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  final _obscurePassword = true.obs;
  bool get obscurePassword => _obscurePassword.value;

  void togglePasswordVisibility() =>
      _obscurePassword.value = !_obscurePassword.value;

  Future<void> login() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      CustomDialog.showError(
        title: 'Error',
        message: 'Please enter username and password',
      );
      return;
    }

    _isLoading.value = true;
    CustomDialog.showLoading(message: 'Logging in...');

    try {
      final response = await _authRepository.loginOfficer(
        username: usernameController.text,
        password: passwordController.text,
      );

      AppLogger.info('Login API Response: $response');

      CustomDialog.hideLoading();

      final accessToken = response['data']?['accessToken'];
      if (accessToken != null) {
        // Save user data
        final userModel = UserModel.fromJson(response['data']);
        final storage = GetStorage();
        await storage.write('user', userModel.toJson());

        await JwtHelper.saveToken(accessToken);
        HelpersApi().setAuthToken(accessToken);

        // Save credentials for next time (optional)
        await _secureStorage.setUsername(usernameController.text);
        await _secureStorage.setPassword(passwordController.text);

        // Check if printer is configured
        final selectedPrinter = storage.read('selected_printer');
        if (selectedPrinter == null) {
          Get.offAllNamed('/printer');
        } else {
          Get.offAllNamed('/kiosk');
        }
      } else {
        CustomDialog.showError(
          title: 'Login Failed',
          message: 'Invalid credentials',
        );
      }
    } catch (e) {
      CustomDialog.hideLoading();
      CustomDialog.showError(
        title: 'Error',
        message: ErrorHandler.getMessage(e),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
