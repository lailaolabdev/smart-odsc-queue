import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:smart_odsc_queue/app/modules/login/controllers/login_controller.dart';
import 'package:smart_odsc_queue/app/routes/app_pages.dart';
import 'package:smart_odsc_queue/app/shared/constants/app_constants.dart';
import 'package:smart_odsc_queue/app/shared/services/printer_service.dart';
import 'package:smart_odsc_queue/app/shared/utils/logger.dart';
import 'package:smart_odsc_queue/app/shared/widgets/language_switcher.dart';
import 'package:smart_odsc_queue/app/translations/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Full Screen Kiosk Mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Kiosk UI is landscape-only — lock it so a handheld device (phone/tablet)
  // can't rotate into the un-designed portrait layout.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize GetStorage
  await GetStorage.init();

  // Initialize PrinterService
  Get.put(PrinterService());

  // LoginController as a permanent singleton — survives every
  // Get.offAllNamed cleanup so /login never crashes with
  // "LoginController not found" when the auth interceptor force-routes
  // a user back to login mid-flow (e.g. on a 401 from feedback).
  Get.put<LoginController>(LoginController(), permanent: true);

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
      translations: AppTranslations(),
      locale: loadPersistedLocale(),
      fallbackLocale: AppTranslations.fallback,
      supportedLocales: AppTranslations.supported,
      // Material/Cupertino/Widgets localizations for any locale we declare in
      // supportedLocales (incl. Lao). Without these, Flutter throws "No
      // MaterialLocalizations found" the first time a Scaffold/TextField/etc.
      // tries to render in a non-English locale.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      // The whole flow is hand-tuned for AppConstants.designCanvasSize (an
      // iPad-class landscape screen). Rather than reflow every screen per
      // device size, scale that fixed canvas uniformly to fit whatever
      // landscape screen it's actually running on — a phone gets a
      // pillarboxed miniature of the same iPad layout, not a redesign.
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return RepaintBoundary(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: AppConstants.designCanvasSize.width,
              height: AppConstants.designCanvasSize.height,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
