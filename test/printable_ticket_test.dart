import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_odsc_queue/app/shared/widgets/printable_ticket.dart';
import 'package:smart_odsc_queue/app/translations/ticket_translations.dart';

void main() {
  for (final locale in ['en', 'lo']) {
    testWidgets('Citizen and document tickets in $locale', (tester) async {
      Get.addTranslations({'en': ticketEn, 'lo': ticketLo});
      Get.locale = Locale(locale);
      addTearDown(Get.reset);
      final labels = locale == 'lo' ? ticketLo : ticketEn;

      for (final forDocuments in [false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PrintableTicket(
                  queueNumber: 'A034',
                  serviceName: 'Service',
                  qrCodeData: 'https://odsc.gov.la/lo/q#c=test',
                  forDocuments: forDocuments,
                ),
              ),
            ),
          ),
        );
        expect(find.text('A034'), findsOneWidget);
        expect(
          find.byType(BarcodeWidget),
          forDocuments ? findsNothing : findsOneWidget,
        );
        for (final key in ['ticket.full_name', 'ticket.phone']) {
          expect(
            find.text('${labels[key]}:'),
            forDocuments ? findsOneWidget : findsNothing,
          );
        }
        expect(tester.takeException(), isNull);
      }
    });
  }
}
