import 'package:flutter/material.dart';

import '../constants/struggle_catalog.dart';
import 'designs.dart';
import 'haven_style.dart';
import 'theme_presets.dart';

export 'designs.dart';
export 'haven_style.dart';
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

  /// "Zorlandım ama dayandım": ışık yine yanar, sıcak bir tonla.
  static const struggledDay = Color(0xFFE3B66F);
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
  return Color.alphaBlend(categoryTint(c).withValues(alpha: dark ? 0.08 : 0.9), scheme.surfaceContainerLow);
}

/// Uygulamanın teması: Klasik tasarımda seçili renk teması; diğer
/// tasarımlarda tasarımın kendi renk dünyası, yazı tipi ve biçimleri.
///
/// [fontFallback] yalnızca ekran görüntüsü aracı içindir (test ortamında
/// sistem yedek yazı tipleri yoktur); telefonda gerekmez.
ThemeData buildAppTheme(HavenDesign design, ThemePreset preset, {List<String>? fontFallback}) =>
    design.isClassic ? buildTheme(preset) : buildDesignTheme(design, fontFallback: fontFallback);

/// Klasik dışındaki tasarımlar: her bileşen (kart, düğme, çip, alt çubuk,
/// diyalog, giriş alanı, sekme…) tasarımın kurallarıyla yeniden çizilir.
ThemeData buildDesignTheme(HavenDesign design, {List<String>? fontFallback}) {
  final fb = fontFallback;
  final t = design.tokens;
  final s = HavenStyle(design);
  final dark = t.dark;
  final scheme = ColorScheme.fromSeed(seedColor: t.primary, brightness: t.brightness).copyWith(
    primary: t.primary,
    onPrimary: t.onPrimary,
    primaryContainer: t.primarySoft,
    onPrimaryContainer: t.ink,
    secondary: t.primary,
    onSecondary: t.onPrimary,
    secondaryContainer: t.primarySoft,
    onSecondaryContainer: t.ink,
    // Simgelerde zeminde okunur sıcak ton; açık tonlu kutular accent'ten.
    tertiary: t.flame,
    onTertiary: t.dark || ThemeData.estimateBrightnessForColor(t.flame) == Brightness.light
        ? t.background
        : Colors.white,
    tertiaryContainer: Color.alphaBlend(t.accent.withValues(alpha: 0.2), t.surface),
    onTertiaryContainer: t.ink,
    surface: t.background,
    onSurface: t.ink,
    onSurfaceVariant: t.muted,
    surfaceContainerLowest: t.surface,
    surfaceContainerLow: t.surface,
    surfaceContainer: t.surfaceAlt,
    surfaceContainerHigh: t.surfaceAlt,
    surfaceContainerHighest: t.surfaceAlt,
    surfaceTint: Colors.transparent,
    outline: t.borderWidth >= 2 ? t.outline : Color.lerp(t.outline, t.ink, 0.35),
    outlineVariant: t.borderWidth >= 2 ? t.ink.withValues(alpha: 0.28) : t.outline,
    error: t.danger,
    onError: t.onDanger,
    inverseSurface: dark ? t.ink : t.deep,
    onInverseSurface: dark ? t.background : Colors.white,
  );

  final cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radius), side: s.side);
  final controlRadius = s.r(18);
  final OutlinedBorder buttonShape = t.stadiumButtons
      ? const StadiumBorder()
      : RoundedRectangleBorder(borderRadius: BorderRadius.circular(s.r(16)));
  final buttonSide = t.hardShadow ? BorderSide(color: t.ink, width: 2) : BorderSide.none;
  final strong = t.borderWidth >= 2 ? FontWeight.w800 : FontWeight.w600;
  final divider = t.hardShadow ? t.ink.withValues(alpha: 0.18) : t.outline;
  final snackBg = dark ? t.surfaceAlt : t.deep;
  final selectedNavIcon = switch (design) {
    HavenDesign.neseli => t.onPrimary,
    HavenDesign.net => t.ink,
    _ => dark ? t.primary : t.ink,
  };
  final navIndicator = switch (design) {
    HavenDesign.sis => t.primarySoft,
    HavenDesign.gece => const Color(0xFF1F3542),
    HavenDesign.neseli => t.primary,
    HavenDesign.defter => Color.alphaBlend(t.accent.withValues(alpha: 0.45), t.surface),
    HavenDesign.net => t.accent,
    _ => t.primarySoft,
  };

  var theme = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: t.bodyFont,
    extensions: [
      HavenPalette(deep: t.deep, primary: t.primary, accent: t.accent),
      s,
    ],
    scaffoldBackgroundColor: t.background,
    canvasColor: t.background,
    dividerColor: divider,
    dividerTheme: DividerThemeData(color: divider, thickness: t.borderWidth >= 2 && !t.hardShadow ? 1.5 : 1),
    iconTheme: IconThemeData(color: t.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: t.background,
      foregroundColor: t.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamilyFallback: fb,
        fontFamily: t.headingFont,
        fontSize: 24 * t.fontScale,
        fontWeight: t.headingWeight,
        color: t.ink,
        letterSpacing: design == HavenDesign.sis ? -0.2 : 0,
      ),
    ),
    cardTheme: CardThemeData(elevation: 0, margin: EdgeInsets.zero, color: t.surface, shape: cardShape),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: buttonShape,
        side: buttonSide,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: TextStyle(
          fontFamilyFallback: fb,
          fontFamily: t.bodyFont,
          fontWeight: strong,
          fontSize: 15 * t.fontScale,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: buttonShape,
        foregroundColor: dark ? t.primary : t.ink,
        side: BorderSide(color: t.borderWidth > 0 ? t.outline : t.primary, width: t.borderWidth >= 2 ? 2 : 1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: TextStyle(fontFamilyFallback: fb, fontFamily: t.bodyFont, fontWeight: strong),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: t.primary,
        shape: buttonShape,
        textStyle: TextStyle(fontFamilyFallback: fb, fontFamily: t.bodyFont, fontWeight: strong),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: t.ink)),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: t.primary,
      foregroundColor: t.onPrimary,
      elevation: t.hardShadow ? 0 : 2,
      highlightElevation: t.hardShadow ? 0 : 4,
      extendedTextStyle: TextStyle(
        fontFamilyFallback: fb,
        fontFamily: t.bodyFont,
        fontWeight: strong,
        fontSize: 15 * t.fontScale,
      ),
      shape: t.stadiumButtons
          ? const StadiumBorder()
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(s.r(18)), side: buttonSide),
    ),
    chipTheme: ChipThemeData(
      shape: t.stadiumButtons
          ? StadiumBorder(
              side: BorderSide(color: t.outline, width: t.borderWidth >= 2 ? 2 : 1),
            )
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(s.r(12)),
              side: BorderSide(color: t.outline, width: t.borderWidth >= 2 ? 2 : 1),
            ),
      backgroundColor: t.surface,
      selectedColor: t.hardShadow || design == HavenDesign.net ? t.accent : t.primarySoft,
      checkmarkColor: t.ink,
      labelStyle: TextStyle(fontFamilyFallback: fb, fontFamily: t.bodyFont, color: t.ink, fontWeight: FontWeight.w600),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: switch (design) {
        HavenDesign.sis => t.background,
        HavenDesign.gece => const Color(0xFF0F2029),
        _ => t.surface,
      },
      indicatorColor: navIndicator,
      indicatorShape: switch (design) {
        HavenDesign.neseli => RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: t.ink, width: 2),
        ),
        HavenDesign.net => RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: t.ink, width: 2),
        ),
        HavenDesign.defter => RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        _ => const StadiumBorder(),
      },
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(color: states.contains(WidgetState.selected) ? selectedNavIcon : t.muted),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamilyFallback: fb,
          fontFamily: t.bodyFont,
          fontSize: 12 * t.fontScale,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          color: states.contains(WidgetState.selected) ? (dark ? t.primary : t.ink) : t.muted,
        ),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: dark ? t.primary : t.ink,
      unselectedLabelColor: t.muted,
      indicatorColor: dark ? t.primary : (t.hardShadow ? t.primary : t.ink),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: divider,
      labelStyle: TextStyle(
        fontFamilyFallback: fb,
        fontFamily: t.bodyFont,
        fontWeight: FontWeight.w800,
        fontSize: 14 * t.fontScale,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamilyFallback: fb,
        fontFamily: t.bodyFont,
        fontWeight: FontWeight.w600,
        fontSize: 14 * t.fontScale,
      ),
    ),
    listTileTheme: ListTileThemeData(iconColor: design == HavenDesign.net ? t.ink : t.muted),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => t.borderWidth >= 2 ? t.ink : (states.contains(WidgetState.selected) ? Colors.transparent : t.muted),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: t.primary, linearTrackColor: t.primarySoft),
    badgeTheme: BadgeThemeData(backgroundColor: t.accent, textColor: t.onAccent),
    bottomSheetTheme: BottomSheetThemeData(
      showDragHandle: true,
      backgroundColor: t.surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: t.muted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(s.r(24))),
        side: s.side,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radius), side: s.side),
      titleTextStyle: TextStyle(
        fontFamilyFallback: fb,
        fontFamily: t.headingFont,
        fontSize: 22 * t.fontScale,
        fontWeight: t.headingWeight,
        color: t.ink,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: t.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(s.r(16)), side: s.side),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: snackBg,
      contentTextStyle: TextStyle(
        fontFamilyFallback: fb,
        fontFamily: t.bodyFont,
        color: dark ? t.ink : Colors.white,
        fontSize: 15 * t.fontScale,
        height: 1.35,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: t.accent,
      closeIconColor: dark ? t.ink : Colors.white,
      elevation: t.hardShadow ? 0 : 6,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(s.r(20)),
        side: t.hardShadow ? BorderSide(color: t.ink, width: 2) : BorderSide.none,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(controlRadius),
        borderSide: BorderSide(color: t.outline, width: t.borderWidth >= 2 ? 2 : 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(controlRadius),
        borderSide: BorderSide(color: t.outline, width: t.borderWidth >= 2 ? 2 : 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(controlRadius),
        borderSide: BorderSide(color: t.primary, width: 2),
      ),
    ),
  );

  // Başlıklar tasarımın başlık yazı tipiyle; Net'te her şey biraz daha büyük.
  final tt = theme.textTheme;
  TextStyle? h(TextStyle? x, {bool heavy = true}) =>
      x?.copyWith(fontFamily: t.headingFont, fontWeight: heavy ? t.headingWeight : null);
  final text = tt.copyWith(
    displayLarge: h(tt.displayLarge),
    displayMedium: h(tt.displayMedium),
    displaySmall: h(tt.displaySmall),
    headlineLarge: h(tt.headlineLarge),
    headlineMedium: h(tt.headlineMedium),
    headlineSmall: h(tt.headlineSmall),
    titleLarge: h(tt.titleLarge),
    titleMedium: h(tt.titleMedium, heavy: false),
    bodySmall: tt.bodySmall?.copyWith(color: t.muted),
    labelSmall: tt.labelSmall?.copyWith(color: t.muted),
  );
  // Yazı boyutları normalde Theme.of anında eklenir; büyütmek için önce
  // boyutları açıkça yazıp sonra çarpanı uygula (yalnızca Net).
  final scaled = t.fontScale == 1 ? text : Typography.englishLike2021.merge(text).apply(fontSizeFactor: t.fontScale);
  theme = theme.copyWith(textTheme: scaled);
  return theme;
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
    extensions: [palette, HavenStyle.classic],
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: scheme.onSurface),
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
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius))),
    ),
    // Alttan gelen kısa bildirimler: varsayılan koyu gri yerine temanın kendi
    // derin rengi (Bugün'deki seri kartıyla aynı), kum rengi yazı, sıcak vurgu.
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.brightness == Brightness.dark ? scheme.primaryContainer : palette.deep,
      contentTextStyle: TextStyle(
        color: scheme.brightness == Brightness.dark ? scheme.onPrimaryContainer : HavenColors.sand,
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: palette.accent,
      closeIconColor: HavenColors.sand,
      elevation: 6,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius))),
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
