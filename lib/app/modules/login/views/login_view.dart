import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:smart_odsc_queue/app/shared/constants/app_constants.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Side: Login Form (Visible on all screens)
          Expanded(
            flex: 1,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'admin.login.welcome'.tr,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.mainCorlor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'admin.login.subtitle'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          color: ColorConstants.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      TextField(
                        controller: controller.usernameController,
                        decoration: InputDecoration(
                          labelText: 'admin.login.username'.tr,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Obx(
                        () => TextField(
                          controller: controller.passwordController,
                          obscureText: controller.obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'admin.login.password'.tr,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: controller.togglePasswordVisibility,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: controller.login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.mainCorlor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'admin.login.submit'.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _AppVersionLabel(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Right Side: Brand/Logo (Visible on Desktop/Wide screens)
          if (Get.width > 900)
            Expanded(
              flex: 1,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/line-nam-bg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  color: ColorConstants.mainCorlor.withOpacity(0.8),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/logo.png', height: 150),
                        const SizedBox(height: 24),
                        Text(
                          'admin.login.brand.title'.tr,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'admin.login.brand.subtitle'.tr,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small "v1.0.0 (1)" label rendered at the bottom of the login form.
/// Read once via PackageInfo — cached by the plugin after the first call,
/// so the FutureBuilder reflows are negligible.
class _AppVersionLabel extends StatelessWidget {
  const _AppVersionLabel();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 16);
        final info = snapshot.data!;
        return Text(
          'v${info.version} (${info.buildNumber})',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        );
      },
    );
  }
}
