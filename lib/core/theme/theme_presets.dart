import 'package:flutter/material.dart';

import '../../l10n/tx.dart';

/// Kullanıcının ruh haline göre seçebileceği temalar. Renk temaları
/// ÜCRETSİZ: herkes kendini en rahat hissettiği tonu seçebilsin. Mor tonlar ve
/// Gece Karanlığı küçük birer hediye (seriyle ya da isteğe bağlı reklamla).
enum ThemePreset {
  ocean(
    label: 'Okyanus',
    primary: Color(0xFF2B6B73),
    deep: Color(0xFF1C4A52),
    soft: Color(0xFFDCEBEA),
    surface: Color(0xFFF5F2EC),
    card: Color(0xFFFBFAF7),
    accent: Color(0xFFE3A64F),
  ),
  sky(
    label: 'Mavi Tonlar',
    primary: Color(0xFF3F6FB0),
    deep: Color(0xFF243F6B),
    soft: Color(0xFFDCE6F5),
    surface: Color(0xFFF3F5F9),
    card: Color(0xFFFAFBFD),
    accent: Color(0xFFE3A64F),
  ),
  forest(
    label: 'Yeşil Tonlar',
    primary: Color(0xFF3F6B4F),
    deep: Color(0xFF2A4A36),
    soft: Color(0xFFDDE9DF),
    surface: Color(0xFFF3F3EC),
    card: Color(0xFFFAFAF5),
    accent: Color(0xFFD9A54E),
  ),
  sunset(
    label: 'Turuncu Tonlar',
    primary: Color(0xFFC2662D),
    deep: Color(0xFF7A3B16),
    soft: Color(0xFFF7E2D2),
    surface: Color(0xFFFAF3EC),
    card: Color(0xFFFEFAF6),
    accent: Color(0xFFE0A33A),
  ),
  crimson(
    label: 'Kırmızı Tonlar',
    primary: Color(0xFFB04848),
    deep: Color(0xFF6E2626),
    soft: Color(0xFFF4DADA),
    surface: Color(0xFFFAF2F1),
    card: Color(0xFFFEF9F8),
    accent: Color(0xFFD9A04A),
  ),
  rose(
    label: 'Pembe Tonlar',
    primary: Color(0xFFB85C86),
    deep: Color(0xFF6F3352),
    soft: Color(0xFFF5DDE8),
    surface: Color(0xFFFAF3F6),
    card: Color(0xFFFEF9FB),
    accent: Color(0xFFD9A04A),
  ),
  lavender(
    label: 'Mor Tonlar',
    primary: Color(0xFF6E5BA8),
    deep: Color(0xFF3F3168),
    soft: Color(0xFFE5DFF4),
    surface: Color(0xFFF5F3FA),
    card: Color(0xFFFCFBFE),
    accent: Color(0xFFE3A64F),
    unlockStreak: 3,
  ),
  night(
    label: 'Gece Karanlığı',
    primary: Color(0xFF7FB3B8),
    deep: Color(0xFF0E1A22),
    soft: Color(0xFF233541),
    surface: Color(0xFF111A21),
    card: Color(0xFF1A2630),
    accent: Color(0xFFE3A64F),
    brightness: Brightness.dark,
    unlockStreak: 7,
  );

  const ThemePreset({
    required String label,
    required this.primary,
    required this.deep,
    required this.soft,
    required this.surface,
    required this.card,
    required this.accent,
    this.brightness = Brightness.light,
    this.unlockStreak = 0,
  }) : labelTr = label;

  final String labelTr;
  String get label => tx(labelTr);
  final Color primary;
  final Color deep;
  final Color soft;
  final Color surface;
  final Color card;
  final Color accent;
  final Brightness brightness;

  /// 0 = ücretsiz; N = en iyi seri N güne ulaşınca açılır.
  final int unlockStreak;

  bool get isGift => unlockStreak > 0;

  /// Eski kayıtlar ('light' → okyanus) ile uyumlu.
  static ThemePreset parse(String? id) =>
      ThemePreset.values.firstWhere((p) => p.name == id, orElse: () => ThemePreset.ocean);
}

/// Tema rengini widget'lardan okumak için kısayol (gradyanlar, vurgular).
class HavenPalette extends ThemeExtension<HavenPalette> {
  const HavenPalette({required this.deep, required this.primary, required this.accent});

  final Color deep;
  final Color primary;
  final Color accent;

  static HavenPalette of(BuildContext context) =>
      Theme.of(context).extension<HavenPalette>() ??
      HavenPalette(deep: ThemePreset.ocean.deep, primary: ThemePreset.ocean.primary, accent: ThemePreset.ocean.accent);

  @override
  HavenPalette copyWith({Color? deep, Color? primary, Color? accent}) =>
      HavenPalette(deep: deep ?? this.deep, primary: primary ?? this.primary, accent: accent ?? this.accent);

  @override
  HavenPalette lerp(HavenPalette? other, double t) => other == null
      ? this
      : HavenPalette(
          deep: Color.lerp(deep, other.deep, t)!,
          primary: Color.lerp(primary, other.primary, t)!,
          accent: Color.lerp(accent, other.accent, t)!,
        );
}
