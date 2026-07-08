import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Must be `put` (eager) not `lazyPut`: the splash view body never
    // reads `controller`, so a lazy factory would never fire and the
    // boot gate would never run.
    Get.put<SplashController>(SplashController());
  }
}
