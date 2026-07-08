import 'dart:async';

import 'package:get/get.dart';
import 'package:ota_update/ota_update.dart';

import '../../../data/services/app_version_service.dart';
import '../../../shared/utils/logger.dart';
import '../../../shared/widgets/custom_dialog.dart';

/// Discrete UI phases. The view binds each one to a different button +
/// helper text. Keep these in sync with the matching cases below.
enum UpdatePhase { idle, downloading, installing, done, error }

class ForceUpdateController extends GetxController {
  late final AppVersionResult result;

  final Rx<UpdatePhase> phase = UpdatePhase.idle.obs;
  // 0..100 during DOWNLOADING; the INSTALLING phase emits its own
  // PackageInstaller progress but we keep the value sticky at 100 so the
  // bar doesn't visibly reset between download → install hand-off.
  final RxInt progress = 0.obs;
  final RxnString errorMessage = RxnString();

  StreamSubscription<OtaEvent>? _sub;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is AppVersionResult) {
      result = args;
    } else {
      result = AppVersionService.instance.lastResult ??
          const AppVersionResult.failOpen();
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  /// Kicks off the OTA stream. Idempotent — re-tapping during an active
  /// download is a no-op; tapping after an error restarts cleanly.
  Future<void> startUpdate() async {
    if (phase.value == UpdatePhase.downloading ||
        phase.value == UpdatePhase.installing) {
      return;
    }
    final url = result.apkUrl;
    if (url == null || url.isEmpty) {
      _showBlocked();
      return;
    }
    AppLogger.info('Force-update: download starting → $url');

    // Reset to a clean downloading state. We cancel any prior subscription
    // so retries after an error don't leak the previous stream.
    await _sub?.cancel();
    _sub = null;
    progress.value = 0;
    errorMessage.value = null;
    phase.value = UpdatePhase.downloading;

    try {
      _sub = OtaUpdate()
          .execute(url, destinationFilename: 'smart-odsc-queue.apk')
          .listen(
        _onEvent,
        onError: (Object e) => _setError(e.toString()),
      );
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _onEvent(OtaEvent event) {
    switch (event.status) {
      case OtaStatus.DOWNLOADING:
        phase.value = UpdatePhase.downloading;
        progress.value = int.tryParse(event.value ?? '') ?? progress.value;
        break;
      case OtaStatus.INSTALLING:
        phase.value = UpdatePhase.installing;
        // Keep the bar at 100 so the visual doesn't snap backwards while
        // PackageInstaller boots its own UI.
        progress.value = 100;
        break;
      case OtaStatus.INSTALLATION_DONE:
        // PackageInstaller reported success. The activity is about to be
        // killed and replaced by the new APK — there's no recovery /
        // post-install navigation to do here.
        phase.value = UpdatePhase.done;
        break;
      case OtaStatus.CANCELED:
        phase.value = UpdatePhase.idle;
        progress.value = 0;
        break;
      case OtaStatus.DOWNLOAD_ERROR:
      case OtaStatus.INSTALLATION_ERROR:
      case OtaStatus.CHECKSUM_ERROR:
      case OtaStatus.INTERNAL_ERROR:
      case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
      case OtaStatus.ALREADY_RUNNING_ERROR:
        _setError('${event.status.name}: ${event.value ?? ''}');
        break;
    }
  }

  void _setError(String details) {
    AppLogger.error('Force-update failed: $details');
    errorMessage.value = details;
    phase.value = UpdatePhase.error;
  }

  void _showBlocked() {
    CustomDialog.showError(
      title: 'common.error'.tr,
      message: 'force_update.install_blocked'.tr,
    );
  }
}
