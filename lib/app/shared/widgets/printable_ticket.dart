import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:barcode_widget/barcode_widget.dart';

/// Thermal-printable ticket. Labels follow the user's current locale; the
/// queue NUMBER itself is left as-is (it's a code, not text).
///
/// The widget is captured into an image via `screenshot.captureFromWidget`
/// off-screen, so we read translations via `.tr` (which reads Get's
/// statically-held locale, not BuildContext localizations).
class PrintableTicket extends StatelessWidget {
  final String queueNumber;
  final String serviceName;
  final String? barCodeNumber;
  final String? qrCodeData;
  final String? ethnicity;

  const PrintableTicket({
    super.key,
    required this.queueNumber,
    required this.serviceName,
    this.barCodeNumber,
    this.qrCodeData,
    this.ethnicity,
  });

  /// Maps the canonical enum value (LAO / KHMU / HMONG / OTHER) to a
  /// printable label using the *current* locale.
  String _ethnicityLabel(String code) {
    final isLao = (Get.locale?.languageCode ?? 'lo') == 'lo';
    switch (code) {
      case 'LAO':
        return isLao ? 'ລາວ' : 'Lao';
      case 'KHMU':
        return isLao ? 'ຂະມຸ' : 'Khmu';
      case 'HMONG':
        return isLao ? 'ມົ້ງ' : 'Hmong';
      case 'OTHER':
        return isLao ? 'ອື່ນໆ' : 'Other';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Container(
        width: 400, // Slightly narrower for standard receipt
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Date/Time (Left-aligned)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${DateTime.now().toString().split(' ')[0]}  ${DateTime.now().toString().split(' ')[1].substring(0, 5)}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Logo and Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ticket.header_title'.tr,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'ticket.header_subtitle'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    "assets/images/out-line-back.png",
                    width: 80, // Increased size
                    height: 80, // Increased size
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(
                          width: 80,
                          height: 80,
                          child: Icon(
                            Icons.business,
                            size: 80,
                            color: Colors.black,
                          ),
                        ),
                  ),
                ),
              ],
            ),

            const Divider(color: Colors.black, thickness: 1.5, height: 30),

            // Main Row: Queue Number and QR Code side-by-side
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Side: Queue Number
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ticket.queue_number_label'.tr,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        queueNumber,
                        style: const TextStyle(
                          fontSize: 120,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Side: QR Code (Enlarged for scannability)
                if (qrCodeData != null && qrCodeData!.isNotEmpty)
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Text(
                          'ticket.scan_to_track'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(5),
                          color: Colors.white,
                          child: BarcodeWidget(
                            barcode: Barcode.qrCode(),
                            data: qrCodeData!,
                            width: 140, // Increased size for thermal printers
                            height: 140,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 15),

            // Service Name - Clean and Bold
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                serviceName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Ethnicity row (only when value provided)
            if (ethnicity != null && ethnicity!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${'ticket.ethnicity'.tr}: ",
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  Text(
                    _ethnicityLabel(ethnicity!),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 25),

            // Footer
            Center(
              child: Text(
                'ticket.please_wait'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
