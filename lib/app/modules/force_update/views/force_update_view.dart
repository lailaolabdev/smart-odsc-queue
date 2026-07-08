import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/force_update_controller.dart';

/// Non-dismissible blocker. The whole point of force-update is that the
/// installed build can't safely keep talking to backend, so there is no
/// back / cancel / dismiss path — only "update" and "retry on error".
///
/// Update happens entirely in-app via [ota_update]: the button below
/// streams a 0..100 progress, then hands the APK to Android's
/// PackageInstaller, which is the one piece we cannot draw ourselves
/// (Android forces a confirmation dialog for non-device-owner installs).
class ForceUpdateView extends GetView<ForceUpdateController> {
  const ForceUpdateView({super.key});

  @override
  Widget build(BuildContext context) {
    final isEnglish = Get.locale?.languageCode == 'en';
    final releaseNotes = isEnglish
        ? controller.result.releaseNotesEn
        : controller.result.releaseNotesLo;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Image(
                      image: AssetImage('assets/images/main-logo.jpg'),
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'force_update.title'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E5394),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'force_update.subtitle'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF333333),
                        height: 1.4,
                      ),
                    ),
                    if (releaseNotes != null && releaseNotes.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          releaseNotes,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF455C91),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    if (controller.result.installedVersionName != null &&
                        controller.result.latestVersionName != null) ...[
                      const SizedBox(height: 24),
                      _VersionArrow(
                        from: controller.result.installedVersionName!,
                        to: controller.result.latestVersionName!,
                      ),
                    ],
                    const SizedBox(height: 32),
                    Obx(() => _ProgressBar(
                          phase: controller.phase.value,
                          percent: controller.progress.value,
                        )),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 400,
                      height: 80,
                      child: Obx(() => _PrimaryButton(
                            phase: controller.phase.value,
                            percent: controller.progress.value,
                            onPressed: controller.startUpdate,
                          )),
                    ),
                    const SizedBox(height: 16),
                    Obx(() => _StatusText(
                          phase: controller.phase.value,
                          errorMessage: controller.errorMessage.value,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.phase, required this.percent});

  final UpdatePhase phase;
  final int percent;

  @override
  Widget build(BuildContext context) {
    // Only show during download / install. Hide in idle/done/error to
    // reduce visual noise.
    final visible =
        phase == UpdatePhase.downloading || phase == UpdatePhase.installing;
    if (!visible) return const SizedBox(height: 8);
    final fraction = (percent.clamp(0, 100)) / 100.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 400,
        height: 8,
        child: LinearProgressIndicator(
          value: phase == UpdatePhase.installing ? null : fraction,
          backgroundColor: const Color(0xFFE6EAF2),
          valueColor:
              const AlwaysStoppedAnimation<Color>(Color(0xFFF47939)),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.phase,
    required this.percent,
    required this.onPressed,
  });

  final UpdatePhase phase;
  final int percent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled =
        phase == UpdatePhase.downloading || phase == UpdatePhase.installing;
    return ElevatedButton(
      onPressed: disabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF47939),
        disabledBackgroundColor: const Color(0xFFF47939).withOpacity(0.85),
        disabledForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 4,
      ),
      child: _buttonChild(),
    );
  }

  Widget _buttonChild() {
    switch (phase) {
      case UpdatePhase.idle:
        return Text(
          'force_update.cta'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        );
      case UpdatePhase.downloading:
        return Text(
          '${'force_update.downloading'.tr} $percent%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        );
      case UpdatePhase.installing:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'force_update.installing'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      case UpdatePhase.done:
        return Text(
          'force_update.done'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        );
      case UpdatePhase.error:
        return Text(
          'force_update.retry'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        );
    }
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.phase, required this.errorMessage});

  final UpdatePhase phase;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    switch (phase) {
      case UpdatePhase.installing:
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'force_update.installing_hint'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        );
      case UpdatePhase.error:
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              Text(
                'force_update.error'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFC62828),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (errorMessage != null && errorMessage!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _VersionArrow extends StatelessWidget {
  const _VersionArrow({required this.from, required this.to});

  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'v$from',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(width: 12),
        Icon(Icons.arrow_forward_rounded,
            size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 12),
        Text(
          'v$to',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2E5394),
          ),
        ),
      ],
    );
  }
}
