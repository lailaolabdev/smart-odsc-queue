import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

/// Initial-paint screen. Logo + tiny spinner. The controller does all the
/// work in `onReady`; this widget never depends on the result — it gets
/// replaced via `Get.offAllNamed` either way.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Image(
              image: AssetImage('assets/images/main-logo.jpg'),
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 32),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E5394)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
