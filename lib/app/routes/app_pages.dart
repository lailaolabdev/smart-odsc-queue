import 'package:get/get.dart';
import '../modules/force_update/bindings/force_update_binding.dart';
import '../modules/force_update/middlewares/force_update_middleware.dart';
import '../modules/force_update/views/force_update_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/kiosk/bindings/kiosk_binding.dart';
import '../modules/kiosk/views/kiosk_view.dart';
import '../modules/printer/bindings/printer_binding.dart';
import '../modules/printer/views/printer_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  /// Initial route is always /splash. The splash controller runs the
  /// force-update gate (against backend-published `minVersionCode`) and
  /// then either redirects to /force-update or resolves the normal
  /// initial route (JWT → /login, printer → /printer, else /kiosk). The
  /// resolver logic lives in [SplashController._resolveInitialRoute] —
  /// keep it in sync with the documentation there.
  static const String initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.forceUpdate,
      page: () => const ForceUpdateView(),
      binding: ForceUpdateBinding(),
    ),
    GetPage(
      name: AppRoutes.kiosk,
      page: () => const KioskView(),
      binding: KioskBinding(),
      middlewares: [ForceUpdateMiddleware()],
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    // Placeholder for Home
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.printer,
      page: () => const PrinterView(),
      binding: PrinterBinding(),
    ),
  ];
}
