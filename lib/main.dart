import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:smart_odsc_queue/app/routes/app_pages.dart';
import 'package:smart_odsc_queue/app/shared/services/printer_service.dart';
import 'package:smart_odsc_queue/app/shared/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Full Screen Kiosk Mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize GetStorage
  await GetStorage.init();

  // Initialize PrinterService
  Get.put(PrinterService());

  // Initialize Logger
  AppLogger.init(enabled: true);


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Smart ODSC Queue',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E5394)),
        useMaterial3: true,
        fontFamily: 'NotoSansLao', // Assuming this was included in pubspec
      ),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
