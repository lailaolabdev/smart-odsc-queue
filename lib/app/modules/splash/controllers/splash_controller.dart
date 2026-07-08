import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../data/api_helper/jwt_helper.dart';
import '../../../data/services/app_version_service.dart';
import '../../../routes/app_routes.dart';

/// Boot gate.
///
/// Runs the app-version check, then either routes to /force-update or
/// resolves the normal initial route (JWT → /login, no printer → /printer,
/// otherwise → /kiosk). This logic used to live in [AppPages.initial]; it
/// was lifted here so the version check (which is async) can run BEFORE
/// any user-facing route mounts. The first paintable frame is the splash
/// itself, so the user sees the logo immediately while the network call
/// runs in the background.
class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _gate();
  }

  Future<void> _gate() async {
    final result = await AppVersionService.instance.check();

    if (result.status == AppVersionStatus.forceUpdateRequired) {
      Get.offAllNamed(AppRoutes.forceUpdate, arguments: result);
      return;
    }

    Get.offAllNamed(_resolveInitialRoute());
  }

  /// Mirror of the original [AppPages.initial] resolver, copy-pasted here
  /// so it runs AFTER the version check. Keep this in sync with the order
  /// documented there:
  ///   1. No valid JWT     → /login
  ///   2. No saved printer → /printer
  ///   3. Both present     → /kiosk
  String _resolveInitialRoute() {
    if (!JwtHelper.hasValidToken()) return AppRoutes.login;
    final hasPrinter = GetStorage().read('selected_printer') != null;
    if (!hasPrinter) return AppRoutes.printer;
    return AppRoutes.kiosk;
  }
}
