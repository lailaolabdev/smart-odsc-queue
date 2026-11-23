import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/app_version_service.dart';
import '../../routes/app_routes.dart';

const _blue = Color(0xFF2E5394);

/// Shows the result of a version check on the staff-only printer page.
///
///   * update available → offer it ("Update now" opens the update screen).
///   * up to date       → confirm it, with the installed version.
///   * check failed     → say so (only when [reportUpToDate] is set, i.e. the
///                        staff pressed the check button themselves).
Future<void> showVersionCheckResult(
  AppVersionResult result, {
  required bool reportUpToDate,
}) async {
  switch (result.status) {
    case AppVersionStatus.forceUpdateRequired:
      Get.toNamed(AppRoutes.forceUpdate, arguments: result);
      return;
    case AppVersionStatus.updateAvailable:
      final update = await Get.dialog<bool>(
        UpdateAvailableDialog(result: result),
        barrierDismissible: false,
      );
      if (update == true) {
        Get.toNamed(AppRoutes.forceUpdate, arguments: result);
      }
      return;
    case AppVersionStatus.upToDate:
    case AppVersionStatus.unknownFailOpen:
      if (!reportUpToDate) return;
      await Get.dialog<void>(_VersionStatusDialog(result: result));
      return;
  }
}

class _VersionStatusDialog extends StatelessWidget {
  const _VersionStatusDialog({required this.result});

  final AppVersionResult result;

  @override
  Widget build(BuildContext context) {
    final ok = result.status == AppVersionStatus.upToDate;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ok ? Icons.check_circle : Icons.cloud_off,
                size: 64,
                color: ok ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                ok ? 'update_prompt.latest'.tr : 'update_prompt.check_failed'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _blue,
                ),
              ),
              if (ok && result.installedVersionName != null) ...[
                const SizedBox(height: 8),
                Text(
                  'v${result.installedVersionName} (${result.installedVersionCode})',
                  style: const TextStyle(fontSize: 18, color: Color(0xFF455C91)),
                ),
              ],
              if (!ok) ...[
                const SizedBox(height: 8),
                Text(
                  'update_prompt.check_failed_hint'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                height: 56,
                child: ElevatedButton(
                  onPressed: Get.back,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'common.ok'.tr,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UpdateAvailableDialog extends StatelessWidget {
  const UpdateAvailableDialog({super.key, required this.result});

  final AppVersionResult result;

  static const _versionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Color(0xFF455C91),
  );

  @override
  Widget build(BuildContext context) {
    final isEnglish = Get.locale?.languageCode == 'en';
    final notes = isEnglish ? result.releaseNotesEn : result.releaseNotesLo;
    const blue = Color(0xFF2E5394);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.system_update, size: 64, color: blue),
              const SizedBox(height: 16),
              Text(
                'update_prompt.title'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: blue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'update_prompt.body'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Color(0xFF333333)),
              ),
              if (result.installedVersionName != null &&
                  result.latestVersionName != null) ...[
                const SizedBox(height: 12),
                // Icon, not "→": the Lao font has no arrow glyph.
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(result.installedVersionName!, style: _versionStyle),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 22,
                        color: Color(0xFF455C91),
                      ),
                    ),
                    Text(result.latestVersionName!, style: _versionStyle),
                  ],
                ),
              ],
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notes,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF455C91),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 64,
                      child: OutlinedButton(
                        onPressed: () => Get.back(result: false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: blue,
                          side: const BorderSide(color: blue, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'update_prompt.later'.tr,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 64,
                      child: ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'update_prompt.now'.tr,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
