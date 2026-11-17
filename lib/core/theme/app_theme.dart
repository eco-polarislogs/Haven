import 'package:flutter/material.dart';

import '../constants/struggle_catalog.dart';
import 'theme_presets.dart';

export 'theme_presets.dart';

/// Haven paleti: liman teması. Derin deniz mavisi-yeşili, arduvaz mavisi,
/// kum rengi zemin ve "ışık" vurgusu olarak kehribar.
/// Cinsiyetten bağımsız, sakin ve güven veren tonlar.
/// Kural: Arayüzde KIRMIZI yok. "Zor gün" bile yumuşak kil tonuyla gösterilir.
class HavenColors {
  HavenColors._();

  static const harbor = Color(0xFF2B6B73); // ana renk
  static const harborDeep = Color(0xFF1C4A52);
  static const harborSoft = Color(0xFFDCEBEA);
  static const slate = Color(0xFF5B7DB1);
  static const slateSoft = Color(0xFFE3EAF5);
  static const sand = Color(0xFFF5F2EC); // zemin
  static const card = Color(0xFFFBFAF7);
  static const amber = Color(0xFFE3A64F); // ışık / seri
  static const amberSoft = Color(0xFFF8EBD6);
  static const clay = Color(0xFFC98468); // zor gün, hata (kırmızı yerine)
  static const ink = Color(0xFF26313A);
  static const night = Color(0xFF111A21);
  static const nightCard = Color(0xFF1A2630);

  /// Takvimdeki gün renkleri.
  static const kindDay = Color(0xFF8CC3BE);
  static const hardDay = Color(0xFFE6C1AE);
}

/// Her mücadele kategorisinin kart tonu: ayırt edilebilir, soluk ve nötr.
Color categoryTint(StruggleCategory c) => switch (c) {
      StruggleCategory.bfrb => const Color(0xFFE2EEEF), // sis
      StruggleCategory.ocd => const Color(0xFFE6EBF2), // buz mavisi
      StruggleCategory.anxiety => const Color(0xFFDFEDF2), // açık deniz
      StruggleCategory.mood => const Color(0xFFEDE9E3), // sıcak gri
      StruggleCategory.eating => const Color(0xFFF2EADF), // kum
      StruggleCategory.behavioral => const Color(0xFFE3E9F5), // gök
      StruggleCategory.substance => const Color(0xFFE4EFE8), // adaçayı
      StruggleCategory.selfHarm => const Color(0xFFE7E9EF), // arduvaz
      StruggleCategory.anger => const Color(0xFFF1E6DE), // kil
      StruggleCategory.trauma => const Color(0xFFEAE7E1), // taş
      StruggleCategory.sleep => const Color(0xFFE4E6F1), // gece mavisi
    };

/// Kategori ikonunun vurgu rengi.
Color categoryAccent(StruggleCategory c) => switch (c) {
      StruggleCategory.bfrb => const Color(0xFF3F7F86),
      StruggleCategory.ocd => const Color(0xFF55709A),
      StruggleCategory.anxiety => const Color(0xFF2F7C93),
      StruggleCategory.mood => const Color(0xFF8A7458),
      StruggleCategory.eating => const Color(0xFF9A7A4F),
      StruggleCategory.behavioral => const Color(0xFF4F6FA8),
      StruggleCategory.substance => const Color(0xFF4E8063),
      StruggleCategory.selfHarm => const Color(0xFF5A6684),
      StruggleCategory.anger => const Color(0xFFA06A4C),
      StruggleCategory.trauma => const Color(0xFF7A6E5E),
      StruggleCategory.sleep => const Color(0xFF5B6299),
    };

/// Kart zemini: açık temada soluk ton, gece temasında tonun çok hafif izi.
Color categoryCardColor(StruggleCategory c, ColorScheme scheme) {
  final dark = scheme.brightness == Brightness.dark;
  return Color.alphaBlend(
    categoryTint(c).withValues(alpha: dark ? 0.08 : 0.9),
    scheme.surfaceContainerLow,
  );
}

/// Seçilen tema ön ayarından tam bir Material 3 teması üretir.
ThemeData buildTheme(ThemePreset p) {
  final dark = p.brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: p.primary, brightness: p.brightness).copyWith(
    primary: p.primary,
    onPrimary: dark ? p.deep : Colors.white,
    primaryContainer: p.soft,
    onPrimaryContainer: dark ? Colors.white : p.deep,
    tertiary: p.accent,
    surface: p.surface,
    onSurface: dark ? const Color(0xFFE6ECEF) : HavenColors.ink,
    surfaceContainerLow: p.card,
    error: dark ? HavenColors.hardDay : HavenColors.clay,
  );
  return _base(scheme, HavenPalette(deep: p.deep, primary: p.primary, accent: p.accent));
}

ThemeData _base(ColorScheme scheme, HavenPalette palette) {
  const radius = 24.0;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    extensions: [palette],
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    chipTheme: const ChipThemeData(shape: StadiumBorder()),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.primaryContainer,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
  );
}
