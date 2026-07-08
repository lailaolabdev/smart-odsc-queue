import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_odsc_queue/app/shared/constants/app_constants.dart';
import 'package:smart_odsc_queue/app/shared/widgets/loading_indicator.dart';

class CustomDialog {
  static void showLoading({String? message}) {
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingIndicator(size: 80),
            const SizedBox(height: 16),
            Text(message ?? 'common.loading'.tr),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void hideLoading() {
    if (Get.isDialogOpen ?? false) Get.back();
  }

  static void showError({required String title, required String message}) async {
    if (Get.isDialogOpen ?? false) {
      Get.back();
      await Future.delayed(const Duration(milliseconds: 150));
    } else {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Container(
          width: 500, // Compact alert width
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Theme Blue Error/Info Icon + Title & Close Button
              Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: ColorConstants.mainCorlor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.mainCorlor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF64748B),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Thin Divider
              Container(
                height: 1,
                color: const Color(0xFFE2E8F0),
              ),
              const SizedBox(height: 24),
              // Body Message
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              // Footer Button: Theme Blue Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 52,
                    width: 130,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.mainCorlor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'common.ok'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showSuccess({
    String? title,
    required String message,
    Function()? onConfirm,
  }) async {
    if (Get.isDialogOpen ?? false) {
      Get.back();
      await Future.delayed(const Duration(milliseconds: 150));
    } else {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Container(
          width: 500, // Compact alert width
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Theme Blue Success Icon + Title & Close Button
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: ColorConstants.mainCorlor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title ?? 'common.success'.tr,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.mainCorlor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (Get.isDialogOpen ?? false) Get.back();
                        if (onConfirm != null) onConfirm();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF64748B),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Thin Divider
              Container(
                height: 1,
                color: const Color(0xFFE2E8F0),
              ),
              const SizedBox(height: 24),
              // Body Message
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              // Footer Button: Theme Blue Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 52,
                    width: 130,
                    child: ElevatedButton(
                      onPressed: () {
                        if (Get.isDialogOpen ?? false) Get.back();
                        if (onConfirm != null) onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.mainCorlor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'common.ok'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Displays the premium Rejection Reason input modal exactly as shown in [popup.png].
  ///
  ///   * Pixel-perfect styling matches the clean rounded container (radius 24).
  ///   * Title on the left, close "x" icon on the right, divided by a thin line.
  ///   * Custom red-asterisk label and bordered multiline text area.
  ///   * Slate-white cancel button and deep blue confirm button.
  ///   * Returns a [Future<String?>] which resolves to the trimmed text if sent,
  ///     or `null` if cancelled/closed.
  static Future<String?> showRejectionDialog({
    String? title,
    String? label,
    String? hint,
    String? cancelText,
    String? confirmText,
  }) async {
    final textController = TextEditingController();

    return await Get.dialog<String>(
      Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Container(
          width: 680, // Perfect standard desktop/tablet modal width
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title ?? 'ປ້ອນເຫດຜົນປະຕິເສດ',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Get.back(result: null),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF64748B),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Thin Divider
              Container(
                height: 1,
                color: const Color(0xFFE2E8F0),
              ),
              const SizedBox(height: 24),
              // Body Label: Enter Reason *
              Row(
                children: [
                  Text(
                    label ?? 'ປ້ອນເຫດຜົນ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Multiline Rejection Reason Input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ColorConstants.mainCorlor.withOpacity(0.6),
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: textController,
                  maxLines: 4,
                  minLines: 4,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    hintText: hint ?? 'ກະລຸນາປ້ອນເຫດຜົນໃນການປະຕິເສດ...',
                    hintStyle: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.withOpacity(0.4),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Footer Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel "ຍົກເລີກ"
                  SizedBox(
                    height: 52,
                    width: 130,
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: null),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF475569),
                        elevation: 0,
                      ),
                      child: Text(
                        cancelText ?? 'ຍົກເລີກ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Submit "ສົ່ງ"
                  SizedBox(
                    height: 52,
                    width: 130,
                    child: ElevatedButton(
                      onPressed: () {
                        final text = textController.text.trim();
                        if (text.isNotEmpty) {
                          Get.back(result: text);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.mainCorlor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        confirmText ?? 'ສົ່ງ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
