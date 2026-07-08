import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_odsc_queue/app/shared/constants/app_constants.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('admin.home.title'.tr),
        backgroundColor: ColorConstants.mainCorlor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: controller.goToProfile,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 100, color: ColorConstants.mainCorlor),
            const SizedBox(height: 16),
            Text(
              'admin.home.welcome'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
