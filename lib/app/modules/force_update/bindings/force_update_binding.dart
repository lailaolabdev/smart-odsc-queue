import 'package:get/get.dart';

import '../controllers/force_update_controller.dart';

class ForceUpdateBinding extends Bindings {
  @override
  void dependencies() {
    // Eager `put`: matches the pattern documented on SplashBinding —
    // we don't want to risk an Obx() that doesn't read `controller`
    // resulting in the controller never being instantiated and the
    // update button being a no-op.
    Get.put<ForceUpdateController>(ForceUpdateController());
  }
}
