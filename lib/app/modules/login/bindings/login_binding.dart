import 'package:get/get.dart';
import '../controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // `fenix: true` — re-create the controller automatically if it gets
    // deleted (e.g. after a previous offAllNamed cleared bindings).
    // This is the most reliable form for routes that are entered
    // repeatedly via `Get.offAllNamed` (logout → /login → re-login →
    // logout → /login → …): plain `lazyPut` raced the build under
    // those conditions and `Get.put` could double-register.
    Get.lazyPut<LoginController>(() => LoginController(), fenix: true);
  }
}
