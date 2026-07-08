import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:smart_odsc_queue/app/data/api_helper/api_service.dart';
import 'package:smart_odsc_queue/app/modules/kiosk/controllers/kiosk_controller.dart';
import 'package:smart_odsc_queue/app/shared/constants/app_constants.dart';
import 'package:smart_odsc_queue/app/shared/widgets/loading_indicator.dart';
import '../controllers/printer_controller.dart';

class PrinterView extends GetView<PrinterController> {
  const PrinterView({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('ອອກຈາກລະບົບ'),
        content: const Text('ທ່ານຕ້ອງການອອກຈາກລະບົບແທ້ບໍ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ຍົກເລີກ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ອອກຈາກລະບົບ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // clearAuthToken() wipes BOTH the in-memory interceptor token
      // AND the persisted JWT — necessary so the next account's
      // requests don't accidentally inherit the previous session's
      // bearer token.
      HelpersApi().clearAuthToken();
      final storage = GetStorage();
      storage.remove('user');
      // Drop printer pairing too so the next user is sent through
      // pairing instead of inheriting the previous staff member's
      // printer choice.
      storage.remove('selected_printer');

      // Force-delete the KioskController so the next account doesn't
      // inherit the previous staff's serviceCenterId / cached profile
      // / queue state. Without this, the GetX dependency tree keeps
      // the old instance alive across navigation, which was producing
      // 401s on /feedback (stale serviceCenterId vs new token).
      if (Get.isRegistered<KioskController>()) {
        Get.delete<KioskController>(force: true);
      }

      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ຕັ້ງຄ່າເຄື່ອງພິມ'),
        backgroundColor: ColorConstants.mainCorlor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Get.offAllNamed('/kiosk'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadPairedPrinters,
            tooltip: 'ໂຫຼດອີກຄັ້ງ',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _confirmLogout(context),
            tooltip: 'ອອກຈາກລະບົບ',
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(
            () => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        controller.isConnected
                            ? Icons.check_circle
                            : Icons.error_outline,
                        color: controller.isConnected
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          controller.isConnected
                              ? 'ກຳລັງໃຊ້: ${controller.selectedDevice?.name ?? "Unknown"}'
                              : 'ຍັງບໍ່ໄດ້ເຊື່ອມເຄື່ອງພິມ',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (controller.isConnected) ...[
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: controller.testPrint,
                      icon: const Icon(Icons.print),
                      label: const Text('ທົດສອບພິມ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isScanning.value) {
                return const Center(child: LoadingIndicator());
              }

              if (controller.devices.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bluetooth_disabled,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text('ບໍ່ພົບອຸປະກອນ Bluetooth ທີ່ pair ໄວ້'),
                      const SizedBox(height: 8),
                      const Text(
                        'ກະລຸນາ pair ເຄື່ອງພິມໃນ Bluetooth settings ກ່ອນ',
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.loadPairedPrinters,
                        child: const Text('ໂຫຼດອີກຄັ້ງ'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: controller.devices.length,
                separatorBuilder: (context, index) => const Divider(),
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final device = controller.devices[index];
                  final bool isThisConnected =
                      device.connected ||
                      (controller.isConnected &&
                          controller.selectedDevice?.address == device.address);

                  return ListTile(
                    leading: const Icon(
                      Icons.print,
                      color: ColorConstants.mainCorlor,
                    ),
                    title: Text(device.name ?? 'Unknown Device'),
                    subtitle: Text(device.address ?? ''),
                    trailing: isThisConnected
                        ? const Chip(
                            label: Text('ເຊື່ອມຢູ່'),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                          )
                        : ElevatedButton(
                            onPressed: () =>
                                controller.connectToPrinter(device),
                            child: const Text('ເລືອກໃຊ້'),
                          ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
