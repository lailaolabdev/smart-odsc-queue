import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../translations/app_translations.dart';

/// Persistent key used to remember the last selected locale across app
/// (and device) restarts. Stored in [GetStorage].
const String _localeStorageKey = 'app.locale_tag';

/// Loads the persisted locale, if any. Called from `main()` before
/// `runApp` so the initial `GetMaterialApp.locale` matches user choice.
Locale loadPersistedLocale() {
  final tag = GetStorage().read<String>(_localeStorageKey);
  if (tag == 'en_US') return AppTranslations.english;
  return AppTranslations.fallback;
}

/// Two-pill language toggle with a single sliding active indicator —
/// like an iOS segmented control. One thing animates (the indicator
/// slides horizontally) instead of two pills cross-fading their
/// decorations, which keeps the press → settle motion smooth even
/// during the locale-driven MaterialApp rebuild.
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  static const Color _slate = Color(0xFF455C91);
  static const Color _surface = Colors.white;

  // Pill geometry. Track width is derived so the outer Container's
  // *content area* (after border + padding) is exactly two pills wide.
  // Earlier we used `pill*2 + 8` and ate a 4px right-overflow because
  // the 2px border on each side was not accounted for.
  static const double _pillWidth = 92;
  static const double _height = 64;
  static const double _padding = 4;
  static const double _borderWidth = 2;
  static const double _trackWidth =
      _pillWidth * 2 + _padding * 2 + _borderWidth * 2;

  void _setLocale(Locale locale) {
    Get.updateLocale(locale);
    GetStorage().write(
      _localeStorageKey,
      '${locale.languageCode}_${locale.countryCode}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = Get.locale ?? AppTranslations.fallback;
    final isLao = current.languageCode == 'lo';

    return Container(
      height: _height,
      width: _trackWidth,
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: _slate.withOpacity(0.12),
          width: _borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: _slate.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Sliding active indicator — one thing moves, instead of two
          // pills swapping decorations.
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: isLao ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: _pillWidth,
              height: _height - _padding * 2 - _borderWidth * 2,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_slate, Color(0xFF2E5394)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: _slate.withOpacity(0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
          // Tap targets + labels. The label color cross-fades over the
          // same window as the slide so text/background contrast stays
          // legible mid-transition.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Pill(
                label: 'ລາວ',
                isActive: isLao,
                width: _pillWidth,
                onTap: () => _setLocale(AppTranslations.fallback),
              ),
              _Pill(
                label: 'EN',
                isActive: !isLao,
                width: _pillWidth,
                onTap: () => _setLocale(AppTranslations.english),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool isActive;
  final double width;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.isActive,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const slate = LanguageSwitcher._slate;
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          splashColor: slate.withOpacity(0.18),
          highlightColor: slate.withOpacity(0.06),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: isActive ? Colors.white : slate.withOpacity(0.65),
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
