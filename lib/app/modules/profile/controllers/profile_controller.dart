import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:smart_odsc_queue/app/data/models/user_model.dart';
import 'package:smart_odsc_queue/app/data/api_helper/jwt_helper.dart';

class ProfileController extends GetxController {
  final storage = GetStorage();
  final Rxn<UserModel> user = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  void loadUserData() {
    final userData = storage.read('user');
    if (userData != null) {
      user.value = UserModel.fromJson(userData);
    }
  }

  void logout() async {
    await JwtHelper.clearTokens();
    storage.remove('user');
    Get.offAllNamed('/login');
  }

  void goToPrinterSettings() {
    Get.toNamed('/printer');
  }
}
