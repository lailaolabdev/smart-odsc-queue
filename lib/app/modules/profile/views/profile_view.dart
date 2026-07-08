import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_odsc_queue/app/shared/constants/app_constants.dart';
import 'package:smart_odsc_queue/app/shared/widgets/loading_indicator.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('admin.profile.title'.tr),
        backgroundColor: ColorConstants.mainCorlor,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        final user = controller.user.value;
        if (user == null) {
          return const Center(child: LoadingIndicator());
        }
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 50,
                backgroundColor: ColorConstants.mainCorlor,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                '${user.firstName} ${user.lastName}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user.userType,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              _buildMenuItem(
                icon: Icons.logout,
                title: 'admin.profile.logout'.tr,
                onTap: controller.logout,
                color: Colors.red,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? ColorConstants.mainCorlor),
      title: Text(title, style: TextStyle(color: color, fontSize: 18)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
