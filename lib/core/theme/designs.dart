import 'package:flutter/material.dart';

import '../../l10n/tx.dart';

/// Uygulamanın GÖRÜNÜM tasarımları: yazı tipi, renk dünyası, köşeler,
/// kenarlıklar, gölgeler, seri kartı ve nefes animasyonu birlikte değişir.
///
/// [classic] uygulamanın ilk (orijinal) tasarımıdır ve varsayılandır: renk
/// temaları (ThemePreset) yalnızca onda geçerlidir. Diğer tasarımlar kendi
/// renk dünyalarıyla gelir.
enum HavenDesign {
  classic('Klasik'),
  sis('Sis'),
  gece('Gece Limanı'),
  bahce('Bahçe'),
  neseli('Neşeli'),
  defter('Defter'),
  net('Net');

  const HavenDesign(this.labelTr);

  final String labelTr;
  String get label => tx(labelTr);

  bool get isClassic => this == classic;

  /// Tasarımın tüm ölçüleri (classic için orijinal değerler).
  DesignTokens get tokens => switch (this) {
    classic => DesignTokens.classic,
    sis => _sis,
    gece => _gece,
    bahce => _bahce,
    neseli => _neseli,
    defter => _defter,
    net => _net,
  };

  static HavenDesign parse(String? id) =>
      HavenDesign.values.firstWhere((d) => d.name == id, orElse: () => HavenDesign.classic);
}

/// Seri kartının çizim biçimi.
enum HeroStyle { gradient, number, ring, plant, chunky, notebook, block }

/// Nefes ekranındaki animasyonun biçimi.
enum BreathStyle { classic, ring, glow, bloom, puff, ink, bold }

/// Bir tasarımın renkleri ve biçim kuralları.
class DesignTokens {
  const DesignTokens({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.deep,
    required this.accent,
    required this.onAccent,
    required this.flame,
    required this.outline,
    required this.danger,
    required this.onDanger,
    required this.tiles,
    required this.games,
    required this.kindDay,
    required this.struggledDay,
    required this.hardDay,
    required this.hero,
    required this.breath,
    this.bodyFont,
    this.headingFont,
    this.headingWeight = FontWeight.w600,
    this.radius = 24,
    this.radiusScale = 1,
    this.minRadius = 0,
    this.maxRadius = 999,
    this.borderWidth = 0,
    this.hardShadow = false,
    this.glow = false,
    this.stadiumButtons = true,
    this.tileFilled = false,
    this.feedCards = false,
    this.squareDays = false,
    this.navTopBorder = false,
    this.navRounded = false,
    this.fontScale = 1,
  });

  final Brightness brightness;

  /// Sayfa zemini.
  final Color background;

  /// Kartlar ve kutular.
  final Color surface;

  /// Kart içindeki iç içe bloklar, giriş alanları.
  final Color surfaceAlt;

  /// Ana metin ve ikinci derece metin.
  final Color ink;
  final Color muted;

  final Color primary;
  final Color onPrimary;
  final Color primarySoft;

  /// Seri kartı, alt bildirimler gibi koyu/derin yüzeyler.
  final Color deep;

  /// Sıcak vurgu (seri ışığı, rozet).
  final Color accent;
  final Color onAccent;

  /// Seri alevi ve küçük seri rozetinin rengi (zeminde okunur).
  final Color flame;

  /// Kenarlık rengi.
  final Color outline;

  /// Acil yardım ve "başaramadım" (kırmızı yerine yumuşak ton).
  final Color danger;
  final Color onDanger;

  /// Bugün'deki kısayolların ve Sakinleş'teki oyun kutularının renkleri (4'er).
  final List<Color> tiles;
  final List<Color> games;

  /// Takvim ve kayıt düğmesi renkleri.
  final Color kindDay;
  final Color struggledDay;
  final Color hardDay;

  final HeroStyle hero;
  final BreathStyle breath;

  /// null = sistem yazı tipi (Roboto).
  final String? bodyFont;
  final String? headingFont;
  final FontWeight headingWeight;

  /// Kart köşesi; diğer köşeler [radiusScale] ile ölçeklenip sınırlanır.
  final double radius;
  final double radiusScale;
  final double minRadius;
  final double maxRadius;

  /// Kart ve kutu kenarlığı (0 = yok).
  final double borderWidth;

  /// Neşeli: kutuların altında sert, kaydırılmış gölge.
  final bool hardShadow;

  /// Gece Limanı: vurgu öğelerinde yumuşak ışıma.
  final bool glow;

  /// Düğmeler hap biçiminde mi (yoksa köşeli dikdörtgen mi).
  final bool stadiumButtons;

  /// Kısayol kutuları dolu renk mi (yoksa açık ton + renkli simge mi).
  final bool tileFilled;

  /// Topluluk gönderileri ayrı kartlar mı (yoksa çizgiyle ayrılmış liste mi).
  final bool feedCards;

  /// Takvim günleri kare mi (yoksa yuvarlak mı).
  final bool squareDays;

  /// Alt gezinme çubuğunun üstünde çizgi / yuvarlatılmış üst köşeler.
  final bool navTopBorder;
  final bool navRounded;

  /// Yazı boyutu çarpanı (Net: daha büyük, daha okunaklı).
  final double fontScale;

  bool get dark => brightness == Brightness.dark;

  /// Orijinal tasarımın değerleri. Classic'te bu değerler kullanılan yerlerde
  /// eskisiyle BİREBİR aynı sonucu verir.
  static const classic = DesignTokens(
    brightness: Brightness.light,
    background: Color(0xFFF5F2EC),
    surface: Color(0xFFFBFAF7),
    surfaceAlt: Color(0xFFFFFFFF),
    ink: Color(0xFF26313A),
    muted: Color(0xFF5B6670),
    primary: Color(0xFF2B6B73),
    onPrimary: Colors.white,
    primarySoft: Color(0xFFDCEBEA),
    deep: Color(0xFF1C4A52),
    accent: Color(0xFFE3A64F),
    onAccent: Color(0xFF1C4A52),
    flame: Color(0xFFE3A64F),
    outline: Color(0xFFC4C8CC),
    danger: Color(0xFFC98468),
    onDanger: Colors.white,
    tiles: [Color(0xFF2F7C93), Color(0xFF5B7DB1), Color(0xFF4E8063), Color(0xFFA9783C)],
    games: [Color(0xFF8A7458), Color(0xFF5B7DB1), Color(0xFFA0603F), Color(0xFF4E8063)],
    kindDay: Color(0xFF8CC3BE),
    struggledDay: Color(0xFFE3B66F),
    hardDay: Color(0xFFE6C1AE),
    hero: HeroStyle.gradient,
    breath: BreathStyle.classic,
  );
}

// ------------------------------------------------------------ A · Sis
// Sade ve ferah: kırık beyaz zemin, ince çizgiler, tek vurgu rengi (adaçayı).
const _sis = DesignTokens(
  brightness: Brightness.light,
  background: Color(0xFFF7F7F5),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFF1F2EF),
  ink: Color(0xFF1E2326),
  muted: Color(0xFF5E666B),
  primary: Color(0xFF3F6B58),
  onPrimary: Colors.white,
  primarySoft: Color(0xFFE3ECE7),
  deep: Color(0xFF1E2326),
  accent: Color(0xFF3F6B58),
  onAccent: Colors.white,
  flame: Color(0xFF3F6B58),
  outline: Color(0xFFE2E3E0),
  danger: Color(0xFFA4493D),
  onDanger: Colors.white,
  tiles: [Color(0xFF3F6B58), Color(0xFF3F6B58), Color(0xFF3F6B58), Color(0xFF3F6B58)],
  games: [Color(0xFF3F6B58), Color(0xFF3F6B58), Color(0xFF3F6B58), Color(0xFF3F6B58)],
  kindDay: Color(0xFF3F6B58),
  struggledDay: Color(0xFFB9A26E),
  hardDay: Color(0xFFDCCFC6),
  hero: HeroStyle.number,
  breath: BreathStyle.ring,
  bodyFont: 'Inter',
  headingFont: 'Inter',
  headingWeight: FontWeight.w600,
  radius: 16,
  radiusScale: 0.7,
  maxRadius: 16,
  borderWidth: 1,
  navTopBorder: true,
);

// ------------------------------------------------------------ B · Gece Limanı
// Koyu deniz gecesi; seri, rekora doğru dolan parlayan bir ışık halkası.
const _gece = DesignTokens(
  brightness: Brightness.dark,
  background: Color(0xFF0D1B24),
  surface: Color(0xFF142733),
  surfaceAlt: Color(0xFF1B3341),
  ink: Color(0xFFE8EEF1),
  muted: Color(0xFFA3B6C0),
  primary: Color(0xFFF2B35E),
  onPrimary: Color(0xFF0D1B24),
  primarySoft: Color(0xFF3A3A30),
  deep: Color(0xFF0F2029),
  accent: Color(0xFFF2B35E),
  onAccent: Color(0xFF0D1B24),
  flame: Color(0xFFF2B35E),
  outline: Color(0xFF24414F),
  danger: Color(0xFFE8A48C),
  onDanger: Color(0xFF0D1B24),
  tiles: [Color(0xFF6FC1BE), Color(0xFFF2B35E), Color(0xFFB9A6F0), Color(0xFFD39A82)],
  games: [Color(0xFF6FC1BE), Color(0xFFF2B35E), Color(0xFFD39A82), Color(0xFFB9A6F0)],
  kindDay: Color(0xFFF2B35E),
  struggledDay: Color(0xFF6FC1BE),
  hardDay: Color(0xFF4A5D69),
  hero: HeroStyle.ring,
  breath: BreathStyle.glow,
  bodyFont: 'PlusJakartaSans',
  headingFont: 'PlusJakartaSans',
  headingWeight: FontWeight.w700,
  radius: 20,
  radiusScale: 0.9,
  borderWidth: 1,
  glow: true,
  feedCards: true,
  navTopBorder: true,
);

// ------------------------------------------------------------ C · Bahçe
// Doğal ve yumuşak: seri büyüyen bir fidan, iyi günler yaprak.
const _bahce = DesignTokens(
  brightness: Brightness.light,
  background: Color(0xFFEEF3EC),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFDCE8DB),
  ink: Color(0xFF1F2D27),
  muted: Color(0xFF3F5148),
  primary: Color(0xFF2F5D4A),
  onPrimary: Colors.white,
  primarySoft: Color(0xFFDCE8DB),
  deep: Color(0xFF2F5D4A),
  accent: Color(0xFFE9B872),
  onAccent: Color(0xFF1F2D27),
  flame: Color(0xFFB7791F),
  outline: Color(0xFFD3DED1),
  danger: Color(0xFFA4493D),
  onDanger: Colors.white,
  tiles: [Color(0xFF2F5D4A), Color(0xFF3B5F7A), Color(0xFF9A6B23), Color(0xFF9B5A3C)],
  games: [Color(0xFF2F5D4A), Color(0xFF3B5F7A), Color(0xFF9A6B23), Color(0xFF9B5A3C)],
  kindDay: Color(0xFF7BA889),
  struggledDay: Color(0xFFE9B872),
  hardDay: Color(0xFFE3CDBE),
  hero: HeroStyle.plant,
  breath: BreathStyle.bloom,
  bodyFont: 'Outfit',
  headingFont: 'Outfit',
  headingWeight: FontWeight.w600,
  radius: 26,
  radiusScale: 1.1,
  feedCards: true,
  navRounded: true,
);

// ------------------------------------------------------------ D · Neşeli
// Oyunsu: kalın mürekkep kenarlıklar, sert gölgeler, şeker renkleri.
const _neseli = DesignTokens(
  brightness: Brightness.light,
  background: Color(0xFFF6F3FF),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFEFEAFF),
  ink: Color(0xFF2A2540),
  muted: Color(0xFF5C5675),
  primary: Color(0xFF6656CC),
  onPrimary: Colors.white,
  primarySoft: Color(0xFFE4DEFF),
  deep: Color(0xFF6656CC),
  accent: Color(0xFFFFB38A),
  onAccent: Color(0xFF2A2540),
  flame: Color(0xFFD9622B),
  outline: Color(0xFF2A2540),
  danger: Color(0xFFB3402F),
  onDanger: Colors.white,
  tiles: [Color(0xFF8ED9C3), Color(0xFFFFB38A), Color(0xFFFFE08A), Color(0xFFE4DEFF)],
  games: [Color(0xFF8ED9C3), Color(0xFFFFB38A), Color(0xFFFFE08A), Color(0xFFE4DEFF)],
  kindDay: Color(0xFF8ED9C3),
  struggledDay: Color(0xFFFFE08A),
  hardDay: Color(0xFFFFCDB8),
  hero: HeroStyle.chunky,
  breath: BreathStyle.puff,
  bodyFont: 'Nunito',
  headingFont: 'Nunito',
  headingWeight: FontWeight.w900,
  radius: 22,
  radiusScale: 0.9,
  minRadius: 10,
  borderWidth: 2,
  hardShadow: true,
  stadiumButtons: false,
  tileFilled: true,
  feedCards: true,
  squareDays: true,
  navTopBorder: true,
);

// ------------------------------------------------------------ E · Defter (yeni)
// Kâğıt günlük: krem sayfa, mürekkep mavisi, serif başlıklar, ince çizgiler.
const _defter = DesignTokens(
  brightness: Brightness.light,
  background: Color(0xFFF7F1E3),
  surface: Color(0xFFFFFCF5),
  surfaceAlt: Color(0xFFF1E9D7),
  ink: Color(0xFF22314A),
  muted: Color(0xFF5A6273),
  primary: Color(0xFF2E4A7D),
  onPrimary: Colors.white,
  primarySoft: Color(0xFFE2E7F1),
  deep: Color(0xFF22314A),
  accent: Color(0xFFE0B13A),
  onAccent: Color(0xFF22314A),
  flame: Color(0xFFB07A12),
  outline: Color(0xFFD8CCB4),
  danger: Color(0xFF9E4234),
  onDanger: Colors.white,
  tiles: [Color(0xFF2E4A7D), Color(0xFF7A5C3E), Color(0xFF4F7A5A), Color(0xFF8A4F6A)],
  games: [Color(0xFF7A5C3E), Color(0xFF2E4A7D), Color(0xFF8A4F6A), Color(0xFF4F7A5A)],
  kindDay: Color(0xFF2E4A7D),
  struggledDay: Color(0xFFE0B13A),
  hardDay: Color(0xFFD9C6AF),
  hero: HeroStyle.notebook,
  breath: BreathStyle.ink,
  bodyFont: 'Inter',
  headingFont: 'Lora',
  headingWeight: FontWeight.w600,
  radius: 8,
  radiusScale: 0.35,
  minRadius: 4,
  maxRadius: 10,
  borderWidth: 1,
  stadiumButtons: false,
  feedCards: true,
  squareDays: true,
  navTopBorder: true,
);

// ------------------------------------------------------------ F · Net (yeni)
// Yüksek karşıtlık: siyah-beyaz, kalın kenarlık, sarı vurgu, büyük ve
// okunaklı yazı (Atkinson Hyperlegible: az gören okurlar için tasarlandı).
const _net = DesignTokens(
  brightness: Brightness.light,
  background: Color(0xFFFFFFFF),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFF1F1F1),
  ink: Color(0xFF000000),
  muted: Color(0xFF2E2E2E),
  primary: Color(0xFF0038A8),
  onPrimary: Colors.white,
  primarySoft: Color(0xFFDDE6FF),
  deep: Color(0xFF000000),
  accent: Color(0xFFFFD000),
  onAccent: Color(0xFF000000),
  flame: Color(0xFF6E5200),
  outline: Color(0xFF000000),
  danger: Color(0xFF8A2F12),
  onDanger: Colors.white,
  tiles: [Color(0xFF0038A8), Color(0xFF000000), Color(0xFF5B2A9E), Color(0xFF005C45)],
  games: [Color(0xFF000000), Color(0xFF0038A8), Color(0xFF8A2F12), Color(0xFF005C45)],
  kindDay: Color(0xFF0038A8),
  struggledDay: Color(0xFFFFD000),
  hardDay: Color(0xFFBDBDBD),
  hero: HeroStyle.block,
  breath: BreathStyle.bold,
  bodyFont: 'AtkinsonNext',
  headingFont: 'AtkinsonNext',
  headingWeight: FontWeight.w800,
  radius: 10,
  radiusScale: 0.5,
  minRadius: 6,
  maxRadius: 12,
  borderWidth: 2,
  stadiumButtons: false,
  feedCards: true,
  squareDays: true,
  navTopBorder: true,
  fontScale: 1.08,
);
