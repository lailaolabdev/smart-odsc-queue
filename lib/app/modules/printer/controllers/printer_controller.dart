import 'package:get/get.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:get_storage/get_storage.dart';
import 'package:smart_odsc_queue/app/shared/services/printer_service.dart';
import 'package:smart_odsc_queue/app/shared/widgets/custom_dialog.dart';
import 'package:smart_odsc_queue/app/shared/utils/logger.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

class PrinterController extends GetxController {
  final PrinterService _printerService = Get.find<PrinterService>();
  final ScreenshotController screenshotController = ScreenshotController();
  final storage = GetStorage();

  final RxList<BluetoothDevice> devices = <BluetoothDevice>[].obs;
  final RxBool isScanning = false.obs;
  final RxBool isConnecting = false.obs;

  BluetoothDevice? get selectedDevice => _printerService.selectedDevice.value;
  bool get isConnected => _printerService.isConnected.value;

  void logout() {
    storage.erase();
    Get.offAllNamed('/login');
  }

  void skip() {
    Get.offAllNamed('/kiosk');
  }

  @override
  void onInit() {
    super.onInit();
    loadPairedPrinters();
  }

  Future<void> loadPairedPrinters() async {
    isScanning.value = true;
    try {
      final results = await _printerService.getPairedDevices();
      devices.assignAll(results);
    } catch (e) {
      CustomDialog.showError(title: 'Bluetooth Error', message: e.toString());
    } finally {
      isScanning.value = false;
    }
  }

  Future<void> scanDevices() => loadPairedPrinters();

  Future<void> connectToPrinter(BluetoothDevice device) async {
    isConnecting.value = true;
    CustomDialog.showLoading(message: 'ກຳລັງເລືອກ ${device.name}...');
    try {
      await _printerService.connect(device);
      CustomDialog.hideLoading();
      CustomDialog.showSuccess(
        title: 'ສຳເລັດ',
        message: 'ເລືອກເຄື່ອງພິມ ${device.name} ສຳເລັດ',
        onConfirm: () => Get.offAllNamed('/kiosk'),
      );
    } catch (e) {
      CustomDialog.hideLoading();
      CustomDialog.showError(title: 'Connection Error', message: e.toString());
    } finally {
      isConnecting.value = false;
    }
  }

  Future<void> testPrint() async {
    if (!isConnected) {
      CustomDialog.showError(
        title: 'Error',
        message: 'Please connect to a printer first',
      );
      return;
    }

    CustomDialog.showLoading(message: 'Printing test...');
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
      CustomDialog.showError(title: 'Error', message: e.toString());
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
              "Smart ODSC Test",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              "Hello welcome to ODSC",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              "ຍິນດີຕ້ອນຮັບສູ່ ແອັບຈັດການຄິວ",
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
