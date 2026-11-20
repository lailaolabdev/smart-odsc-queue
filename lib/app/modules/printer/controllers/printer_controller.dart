import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:screenshot/screenshot.dart';
import 'package:smart_odsc_queue/app/shared/services/printer_service.dart';
import 'package:smart_odsc_queue/app/shared/utils/logger.dart';
import 'package:smart_odsc_queue/app/shared/widgets/custom_dialog.dart';
import 'package:smart_odsc_queue/app/shared/widgets/update_dialog.dart';
import 'package:smart_odsc_queue/app/data/services/app_version_service.dart';

/// Hidden printer-pair screen, reached via the 5-tap admin gesture on
/// the kiosk welcome step. Pure setup — no auth, no skip; user picks a
/// bonded printer, then returns to the kiosk.
class PrinterController extends GetxController {
  final PrinterService _printerService = Get.find<PrinterService>();
  final ScreenshotController screenshotController = ScreenshotController();

  final RxList<BluetoothDevice> devices = <BluetoothDevice>[].obs;
  final RxBool isScanning = false.obs;
  final RxBool isConnecting = false.obs;

  BluetoothDevice? get selectedDevice => _printerService.selectedDevice.value;
  bool get isConnected => _printerService.isConnected.value;

  // App update check. Lives on this staff-only page (not the kiosk) so a
  // citizen taking a ticket is never interrupted by an update offer.
  final RxBool isCheckingVersion = false.obs;
  final RxBool updateAvailable = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPairedPrinters();
  }

  @override
  void onReady() {
    super.onReady();
    // Offer a newer build as soon as staff open this page.
    checkForUpdate(manual: false);
  }

  /// [manual] = staff pressed the button: also report "up to date" or a
  /// failed check. The automatic check on open only speaks up when there
  /// is something to install.
  Future<void> checkForUpdate({bool manual = true}) async {
    if (isCheckingVersion.value) return;
    isCheckingVersion.value = true;
    final AppVersionResult result;
    try {
      result = await AppVersionService.instance.check();
    } finally {
      isCheckingVersion.value = false;
    }
    updateAvailable.value = result.status == AppVersionStatus.updateAvailable;
    await showVersionCheckResult(result, reportUpToDate: manual);
  }

  Future<void> loadPairedPrinters() async {
    isScanning.value = true;
    try {
      final results = await _printerService.getPairedDevices();
      devices.assignAll(results);
    } catch (e) {
      AppLogger.warning('Bluetooth scan failed: $e');
      CustomDialog.showError(
        title: 'common.error'.tr,
        message: 'printer.error.bluetooth'.tr,
      );
    } finally {
      isScanning.value = false;
    }
  }

  Future<void> connectToPrinter(BluetoothDevice device) async {
    isConnecting.value = true;
    CustomDialog.showLoading(
      message: '${'printer.connecting'.tr} ${device.name}...',
    );
    try {
      await _printerService.connect(device);
      CustomDialog.hideLoading();
      CustomDialog.showSuccess(
        title: 'common.success'.tr,
        message: '${'printer.connected'.tr}: ${device.name}',
        onConfirm: () => Get.offAllNamed('/kiosk'),
      );
    } catch (e) {
      CustomDialog.hideLoading();
      AppLogger.warning('Printer connect failed: $e');
      CustomDialog.showError(
        title: 'common.error'.tr,
        message: 'printer.error.connect_failed'.tr,
      );
    } finally {
      isConnecting.value = false;
    }
  }

  Future<void> testPrint() async {
    if (!isConnected) {
      CustomDialog.showError(
        title: 'common.error'.tr,
        message: 'printer.error.not_connected'.tr,
      );
      return;
    }

    CustomDialog.showLoading(message: 'printer.testing'.tr);
    try {
      final Uint8List imageBytes = await screenshotController.captureFromWidget(
        _buildTestTicket(),
        delay: const Duration(milliseconds: 100),
        context: Get.context,
      );

      await _printerService.printLaoTextAsImage(imageBytes);
      CustomDialog.hideLoading();
    } catch (e) {
      CustomDialog.hideLoading();
      AppLogger.error('Test print error: $e');
      CustomDialog.showError(
        title: 'common.error'.tr,
        message: 'printer.error.test_failed'.tr,
      );
    }
  }

  Widget _buildTestTicket() {
    return Material(
      color: Colors.white,
      child: Container(
        width: 512,
        padding: const EdgeInsets.all(20),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Smart ODSC Test',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Hello welcome to ODSC',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'ຍິນດີຕ້ອນຮັບສູ່ ແອັບຈັດການຄິວ',
              style: TextStyle(
                fontSize: 45,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
