import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_odsc_queue/app/shared/constants/app_constants.dart';
import 'package:smart_odsc_queue/app/routes/app_pages.dart';
import 'package:smart_odsc_queue/app/shared/services/printer_service.dart';
import 'package:smart_odsc_queue/app/shared/utils/logger.dart';

class CustomDialog {
  static void showLoading({String? message}) {
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message ?? 'ກະລຸນາລໍຖ້າ...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void hideLoading() {
    if (Get.isDialogOpen ?? false) Get.back();
  }

  static void showError({required String title, required String message}) {
    Get.dialog(
      AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }

  static void showSuccess({
    String? title,
    required String message,
    Function()? onConfirm,
  }) {
    Get.dialog(
      AlertDialog(
        title: Text(
          title ?? 'Success',
          style: const TextStyle(color: Colors.green),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              if (Get.isDialogOpen ?? false) Get.back();
              if (onConfirm != null) onConfirm();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
