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
        title: 'common.error'.tr,
        message: 'login.error.empty_fields'.tr,
      );
      return;
    }

    _isLoading.value = true;
    CustomDialog.showLoading(message: 'login.loading'.tr);

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

        // First-login on this device → printer not paired yet → send
        // staff to the pairing screen so the kiosk is print-ready
        // before the first customer arrives. Re-logins on a device
        // that already has a saved printer skip straight to the
        // welcome screen.
        final hasPrinter = storage.read('selected_printer') != null;
        Get.offAllNamed(hasPrinter ? '/kiosk' : '/printer');
      } else {
        CustomDialog.showError(
          title: 'login.error.failed_title'.tr,
          message: 'login.error.invalid_credentials'.tr,
        );
      }
    } on ApiException catch (e) {
      // 400 / 401 on the login endpoint always means "wrong credentials"
      // in this app's backend. The generic 401 string is
      // "Please sign in again" — correct for session-expired
      // anywhere else, wrong here (we ARE on the login screen).
      CustomDialog.hideLoading();
      AppLogger.warning('Login failed ${e.statusCode}: ${e.message}');
      final isAuthFailure = e.statusCode == 400 || e.statusCode == 401;
      CustomDialog.showError(
        title: 'login.error.failed_title'.tr,
        message: isAuthFailure
            ? 'login.error.invalid_credentials'.tr
            : ErrorHandler.getMessage(e),
      );
    } catch (e) {
      CustomDialog.hideLoading();
      CustomDialog.showError(
        title: 'common.error'.tr,
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
