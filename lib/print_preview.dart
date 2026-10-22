// Dev-only entry point: previews the thermal ticket without a printer.
//   flutter run -d chrome -t lib/print_preview.dart
//
// Left: the ticket widget as rendered.
// Right: simulated paper output — same pipeline as
// PrinterService.printLaoTextAsImage (resize to 512px, grayscale,
// threshold 127 like esc_pos_utils_plus) so you see what the printer gets.
//
// "Production" replicates the ticket currently printed by the deployed APK
// (photo from 2026-10-21) — its text and tracking URL are not in this repo.
// "Repo code" is the PrintableTicket widget from this branch.
import 'dart:math';
import 'dart:typed_data';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';
import 'package:smart_odsc_queue/app/shared/widgets/printable_ticket.dart';
import 'package:smart_odsc_queue/app/translations/app_translations.dart';

void main() => runApp(const PrintPreviewApp());

// URL scanned from a real printed ticket (201 chars -> 53x53 QR modules).
const _productionUrl =
    'https://odsc.gov.la/lo/queue-tracking?queueId=f203db97-591b-44a5-9363-9e176bb9c565&queueNumber=030&serviceCenterId=2ea8440d-c39c-48d2-aade-0906870337a2#claim=PWa5RU4pCbLpuE6rG-fiX3sJ24npgZGh1VyQI5Bpdlo';

// URL built by kiosk_controller.dart in this repo.
const _repoUrl =
    'http://odsc.gov.la/lo/queue-tracking?queueNumber=030&serviceCenterId=2ea8440d-c39c-48d2-aade-0906870337a2';

// 80mm paper printed at 512 dots / 203 dpi = 8 dots per mm.
const _paperDots = 512;
const _dotsPerMm = 8.0;

// Measured with a ruler on a real ticket: 80mm wide, 100mm long.
const _paperMm = 80.0;
const _measuredLengthMm = 100.0;

// CSS pixels per mm at 100% browser zoom (96 dpi).
const _cssPxPerMm = 96 / 25.4;

class PrintPreviewApp extends StatelessWidget {
  const PrintPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'NotoSansLao'),
      translations: AppTranslations(),
      locale: const Locale('lo', 'LA'),
      fallbackLocale: AppTranslations.fallback,
      home: const PrintPreviewPage(),
    );
  }
}

class PrintPreviewPage extends StatefulWidget {
  const PrintPreviewPage({super.key});

  @override
  State<PrintPreviewPage> createState() => _PrintPreviewPageState();
}

class _PrintPreviewPageState extends State<PrintPreviewPage> {
  final ScreenshotController _screenshot = ScreenshotController();
  Uint8List? _paper;
  int _paperHeightDots = 0;

  bool _production = true;
  bool _thermal = true;
  // On-screen width of the whole 80mm paper strip.
  double _paperWidth = 500;

  Widget get _ticket => _production
      ? const ProductionTicket(
          queueNumber: '034',
          serviceName: 'ສອບຖາມຂໍ້ມູນ',
          qrCodeData: _productionUrl,
        )
      : const PrintableTicket(
          queueNumber: '034',
          serviceName: 'ສອບຖາມຂໍ້ມູນ',
          qrCodeData: _repoUrl,
          ethnicity: 'LAO',
        );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _renderPaper());
  }

  Future<void> _renderPaper() async {
    setState(() => _paper = null);
    final bytes = await _screenshot.captureFromWidget(
      _ticket,
      delay: const Duration(milliseconds: 300),
      context: context,
      pixelRatio: 3.0,
      // The app captures within the screen size; a fixed tall box keeps the
      // preview independent of the browser window height.
      targetSize: const Size(400, 2000),
    );
    var paper = img.grayscale(
      img.copyResize(img.decodeImage(bytes)!, width: _paperDots),
    );
    _threshold(paper);
    if (_thermal) paper = _thermalHead(paper);
    setState(() {
      _paper = Uint8List.fromList(img.encodePng(paper));
      _paperHeightDots = paper.height;
    });
  }

  /// esc_pos_utils_plus: inverted gray > 127 prints a dot.
  void _threshold(img.Image image) {
    for (final p in image) {
      final v = p.r < 128 ? 0 : 255;
      p
        ..r = v
        ..g = v
        ..b = v;
    }
  }

  /// Rough thermal-head model: each burnt dot bleeds heat into its
  /// neighbours (dot gain), and the head burns unevenly across the line,
  /// with a weak band in the middle like the photo.
  img.Image _thermalHead(img.Image src) {
    final rnd = Random(7);
    final out = img.Image.from(src);
    final w = src.width, h = src.height;
    bool black(int x, int y) =>
        x >= 0 && y >= 0 && x < w && y < h && src.getPixel(x, y).r == 0;

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final fade = 0.5 + 0.5 * cos((x / w - 0.62) * pi * 2.2).abs();
        int v;
        if (black(x, y)) {
          // Faded head: some dots don't fully burn.
          v = rnd.nextDouble() > fade * 1.1 ? 150 + rnd.nextInt(60) : 15;
        } else {
          final n = [
            black(x - 1, y),
            black(x + 1, y),
            black(x, y - 1),
            black(x, y + 1),
          ].where((b) => b).length;
          // Heat spill fills gaps between neighbouring dots.
          v = n >= 2 && rnd.nextDouble() < 0.35 * n * fade
              ? 70 + rnd.nextInt(70)
              : 245 + rnd.nextInt(10);
        }
        out.setPixelRgb(x, y, v, v, v);
      }
    }
    return img.gaussianBlur(out, radius: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[100],
      appBar: AppBar(
        title: const Text('Print preview'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _renderPaper),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Production')),
                    ButtonSegment(value: false, label: Text('Repo code')),
                  ],
                  selected: {_production},
                  onSelectionChanged: (s) {
                    setState(() => _production = s.first);
                    _renderPaper();
                  },
                ),
                FilterChip(
                  label: const Text('Thermal head effect'),
                  selected: _thermal,
                  onSelected: (v) {
                    setState(() => _thermal = v);
                    _renderPaper();
                  },
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Paper zoom'),
                    Slider(
                      value: _paperWidth,
                      min: 250,
                      max: 1400,
                      onChanged: (v) => setState(() => _paperWidth = v),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => _paperWidth = _paperMm * _cssPxPerMm),
                      child: const Text('1:1 real size'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_qrStats()),
            Text(_lengthStats()),
            const SizedBox(height: 16),
            Wrap(
              spacing: 40,
              runSpacing: 24,
              children: [
                _panel('Widget', _ticket),
                _panel(
                  'Paper (80mm strip, 512 dots printed in the middle)',
                  _paper == null
                      ? SizedBox(
                          width: _paperWidth,
                          height: 200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _paperStrip(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _qrStats() {
    final url = _production ? _productionUrl : _repoUrl;
    final modules = _moduleCount(url);
    // Both tickets draw the QR 140px wide on a 400px ticket.
    const qrDots = 140 / 400 * _paperDots;
    final dotsPerModule = qrDots / modules;
    return 'URL ${url.length} chars · QR ${modules}x$modules modules · '
        '${(qrDots / _dotsPerMm).toStringAsFixed(1)}mm wide · '
        '${dotsPerModule.toStringAsFixed(2)} dots '
        '(${(dotsPerModule / _dotsPerMm).toStringAsFixed(2)}mm) per module';
  }

  String _lengthStats() {
    if (_paperHeightDots == 0) return '';
    final printedMm = _paperHeightDots / _dotsPerMm;
    return 'Printed image ${printedMm.toStringAsFixed(0)}mm long · '
        'measured ticket ${_measuredLengthMm.toStringAsFixed(0)}mm '
        '(rest is feed + cutter margin)';
  }

  /// Paper strip at the measured size: the 512-dot image centred on 80mm,
  /// padded to the measured ticket length.
  Widget _paperStrip() {
    final pxPerMm = _paperWidth / _paperMm;
    final printedWidth = _paperDots / _dotsPerMm * pxPerMm;
    final printedHeight = _paperHeightDots / _dotsPerMm * pxPerMm;
    return Container(
      color: Colors.white,
      width: _paperWidth,
      constraints: BoxConstraints(minHeight: _measuredLengthMm * pxPerMm),
      alignment: Alignment.topCenter,
      child: Image.memory(
        _paper!,
        width: printedWidth,
        height: printedHeight,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.none,
      ),
    );
  }

  int _moduleCount(String data) {
    final bars = Barcode.qrCode()
        .make(data, width: 1000, height: 1000)
        .whereType<BarcodeBar>()
        .map((e) => e.width);
    return (1000 / bars.reduce(min)).round();
  }

  Widget _panel(String label, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black26)],
        ),
        child: child,
      ),
    ],
  );
}

/// Replica of the ticket printed by the deployed APK, laid out from the
/// photo: no grey service box, no ethnicity row, QR label above the code.
class ProductionTicket extends StatelessWidget {
  final String queueNumber;
  final String serviceName;
  final String qrCodeData;

  const ProductionTicket({
    super.key,
    required this.queueNumber,
    required this.serviceName,
    required this.qrCodeData,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toString();
    return Material(
      color: Colors.white,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${now.split(' ')[0]}  ${now.split(' ')[1].substring(0, 5)}',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart ODSC',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'ລະບົບບໍລິການຜ່ານປະຕູດຽວແບບທັນສະໄໝ',
                        style: TextStyle(fontSize: 13, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Image.asset(
                  'assets/images/out-line-back.png',
                  width: 70,
                  height: 70,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const Divider(color: Colors.black, thickness: 1.5, height: 30),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ເລກຄິວຂອງທ່ານ',
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
                      Text(
                        queueNumber,
                        style: const TextStyle(
                          fontSize: 110,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'ສະແກນເພື່ອປ້ອນຂໍ້ມູນລ່ວງໜ້າ',
                      style: TextStyle(fontSize: 11, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    BarcodeWidget(
                      barcode: Barcode.qrCode(),
                      data: qrCodeData,
                      width: 140,
                      height: 140,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 25),
            Center(
              child: Text(
                serviceName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Center(
              child: Text(
                'ກະລຸນາລໍຖ້າການເອີ້ນຄິວ',
                style: TextStyle(
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
