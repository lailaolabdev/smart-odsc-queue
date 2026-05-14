import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/printer_controller.dart';
import 'package:smart_odsc_queue/app/shared/constants/app_constants.dart';

class PrinterView extends GetView<PrinterController> {
  const PrinterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ເລືອກເຄື່ອງພິມ'),
        backgroundColor: ColorConstants.mainCorlor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: controller.skip,
            child: const Text(
              'ຂ້າມໄປກ່ອນ',
              style: TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadPairedPrinters,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.orange),
            onPressed: controller.logout,
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
                      Text(
                        controller.isConnected
                            ? 'ກຳລັງໃຊ້: ${controller.selectedDevice?.name ?? "Unknown"}'
                            : 'ຍັງບໍ່ໄດ້ເລືອກເຄື່ອງພິມ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                return const Center(child: CircularProgressIndicator());
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
                      const Text('ບໍ່ພົບອຸປະກອນ Bluetooth ທີ່ເຊື່ອມໄວ້'),
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
                  bool isThisConnected =
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
