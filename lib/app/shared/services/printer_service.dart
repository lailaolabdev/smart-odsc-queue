import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image/image.dart' as img;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class PrinterService extends GetxService {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  final _storage = GetStorage();

  final RxList<BluetoothDevice> devices = <BluetoothDevice>[].obs;
  final Rx<BluetoothDevice?> selectedDevice = Rx<BluetoothDevice?>(null);
  final RxBool isConnected = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSelectedPrinter();
    _checkConnectionStatus();
  }

  Future<void> _loadSelectedPrinter() async {
    final storedDevice = _storage.read('selected_printer');
    if (storedDevice != null) {
      selectedDevice.value = BluetoothDevice(
        storedDevice['name'],
        storedDevice['address'],
      );
    }
  }

  Future<void> _checkConnectionStatus() async {
    isConnected.value = await bluetooth.isConnected ?? false;
  }

  Future<List<BluetoothDevice>> getPairedDevices() async {
    final List<BluetoothDevice> results = await bluetooth.getBondedDevices();

    for (final device in results) {
      try {
        device.connected = await bluetooth.isDeviceConnected(device) ?? false;
        if (device.connected) {
          selectedDevice.value = device;
          isConnected.value = true;
          await _saveSelectedPrinter(device);
        }
      } catch (_) {
        device.connected = false;
      }
    }

    devices.assignAll(results);
    return results;
  }

  Future<List<BluetoothDevice>> scanDevices() => getPairedDevices();

  Future<void> _saveSelectedPrinter(BluetoothDevice device) async {
    await _storage.write('selected_printer', {
      'name': device.name,
      'address': device.address,
    });
  }

  Future<void> connect(BluetoothDevice device) async {
    try {
      final isBluetoothConnected = await bluetooth.isConnected ?? false;
      final isTargetConnected =
          await bluetooth.isDeviceConnected(device) ?? false;

      if (isBluetoothConnected && isTargetConnected) {
        selectedDevice.value = device;
        isConnected.value = true;
        device.connected = true;
        await _saveSelectedPrinter(device);
        return;
      }

      if (isBluetoothConnected && !isTargetConnected) {
        await bluetooth.disconnect();
      }

      await bluetooth.connect(device);
      selectedDevice.value = device;
      isConnected.value = true;
      device.connected = true;

      await _saveSelectedPrinter(device);
    } catch (e) {
      isConnected.value = false;
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await bluetooth.disconnect();
    isConnected.value = false;
  }

  Future<void> printLaoTextAsImage(Uint8List imageBytes) async {
    if (await bluetooth.isConnected ?? false) {
      // 1. แปลงไฟล์ภาพให้เป็น Object Image ของภาษา Dart
      final img.Image? oriImage = img.decodeImage(imageBytes);
      if (oriImage == null) return;

      // 2. ปรับขนาดภาพให้พอดีกับหน้ากระดาษ (80mm ประมาณ 512 pixels สำหรับ Raster)
      // ถ้าไม่ปรับขนาด เครื่องจะอ่านตำแหน่งจุดผิดและพิมพ์เละ
      final img.Image resizedImage = img.copyResize(oriImage, width: 512);

      // 3. เตรียม Generator สำหรับสร้างคำสั่งภาษาเครื่อง (ESC/POS)
      // โหลด CapabilityProfile (ส่วนใหญ่ใช้ default)
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);

      // 4. แปลงรูปภาพเป็น Byte สำหรับพิมพ์ (Raster Image)
      // ตรงนี้สำคัญมาก: มันจะเปลี่ยนจากไฟล์ภาพ เป็นชุดคำสั่งที่เครื่องพิมพ์เข้าใจ (0x1D 0x76 0x30)
      List<int> bytes = generator.imageRaster(resizedImage);

      // 5. ส่ง "คำสั่ง" (ไม่ใช่ส่งไฟล์ภาพ) ไปที่เครื่องพิมพ์
      await bluetooth.writeBytes(Uint8List.fromList(bytes));

      // สั่งฟีดกระดาษและตัด
      await bluetooth.printNewLine();
      await bluetooth.printNewLine();
      await bluetooth.paperCut();
    }
  }

  // Keep old methods for compatibility if needed, but primarily use printLaoTextAsImage
  Future<void> printImageBytes(Uint8List bytes) async =>
      await printLaoTextAsImage(bytes);
}
