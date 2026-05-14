import 'package:get/get.dart';
import '../controllers/kiosk_controller.dart';
import 'package:smart_odsc_queue/app/shared/services/printer_service.dart';

class KioskBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<KioskController>(() => KioskController());
    Get.lazyPut<PrinterService>(() => PrinterService());
  }
}
