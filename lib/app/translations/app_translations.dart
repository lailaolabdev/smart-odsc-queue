import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'admin_translations.dart';
import 'feedback_translations.dart';
import 'force_update_translations.dart';
import 'kiosk_translations.dart';
import 'service_translations.dart';
import 'ticket_translations.dart';
import 'welcome_translations.dart';

/// Single source of truth for all in-app strings, wired into
/// [GetMaterialApp.translations]. Per-module maps live in sibling files
/// for readability; they're merged here so call-sites use `'key'.tr` with
/// no awareness of which module owns the key.
class AppTranslations extends Translations {
  static const Locale fallback = Locale('lo', 'LA');
  static const Locale english = Locale('en', 'US');

  static const List<Locale> supported = [fallback, english];

  static const String _lo = 'lo_LA';
  static const String _en = 'en_US';

  @override
  Map<String, Map<String, String>> get keys => {
        _lo: {
          ...welcomeLo,
          ...kioskLo,
          ...ticketLo,
          ...feedbackLo,
          ...serviceDetailLo,
          ...adminLo,
          ...forceUpdateLo,
        },
        _en: {
          ...welcomeEn,
          ...kioskEn,
          ...ticketEn,
          ...feedbackEn,
          ...serviceDetailEn,
          ...adminEn,
          ...forceUpdateEn,
        },
      };
}
