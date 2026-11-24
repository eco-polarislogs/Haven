import 'package:flutter/material.dart';

import 'designs.dart';

/// Seçili tasarımın biçim kuralları; widget'lar kutu, köşe, kenarlık ve renk
/// kararlarını buradan alır. Classic'te her yardımcı, orijinal koddaki
/// değeri AYNEN döndürür (orijinal tasarım bozulmaz).
class HavenStyle extends ThemeExtension<HavenStyle> {
  const HavenStyle(this.design);

  final HavenDesign design;

  static const classic = HavenStyle(HavenDesign.classic);

  static HavenStyle of(BuildContext context) => Theme.of(context).extension<HavenStyle>() ?? classic;

  DesignTokens get t => design.tokens;
  bool get isClassic => design.isClassic;
  bool get dark => t.dark;

  /// Orijinal koddaki köşe yarıçapının bu tasarımdaki karşılığı.
  double r(double base) => isClassic ? base : (base * t.radiusScale).clamp(t.minRadius, t.maxRadius).toDouble();
  BorderRadius br(double base) => BorderRadius.circular(r(base));

  /// Kart ve kutu kenarlığı (classic'te yok).
  BorderSide get side =>
      isClassic || t.borderWidth == 0 ? BorderSide.none : BorderSide(color: t.outline, width: t.borderWidth);
  Border? get border => side == BorderSide.none ? null : Border.fromBorderSide(side);

  /// Neşeli'nin sert gölgesi (diğerlerinde yok).
  List<BoxShadow>? shadow([double depth = 4]) =>
      t.hardShadow ? [BoxShadow(color: t.ink, offset: Offset(0, depth))] : null;

  /// Genel kutu süslemesi. Classic'te `BoxDecoration(color, borderRadius)`
  /// ile birebir aynıdır; tasarımlarda köşe ölçeklenir, kenarlık ve gölge eklenir.
  BoxDecoration box({Color? color, double radius = 24, bool outlined = true, bool raised = false, Border? border}) {
    if (isClassic) {
      return BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius), border: border);
    }
    return BoxDecoration(
      color: color == null ? null : _opaque(color),
      borderRadius: br(radius),
      border: border ?? (outlined ? this.border : null),
      boxShadow: raised ? shadow(radius >= 20 ? 4 : 3) : null,
    );
  }

  /// Sert gölgenin altından görünmesin diye yarı saydam renkleri zeminle
  /// karıştırır (yalnızca gölgeli tasarımda).
  Color _opaque(Color c) => t.hardShadow && c.a < 1 ? Color.alphaBlend(c, t.surface) : c;

  /// Kısayol / oyun kutusunun zemini ve simge rengi.
  Color tile(int i) => t.tiles[i % t.tiles.length];
  Color game(int i) => t.games[i % t.games.length];

  BoxDecoration tileBox(Color color, {double radius = 20, BoxShape shape = BoxShape.rectangle}) {
    if (isClassic) {
      return shape == BoxShape.circle
          ? BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle)
          : BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(radius));
    }
    final fill = t.tileFilled ? color : color.withValues(alpha: dark ? 0.2 : 0.12);
    return BoxDecoration(
      color: _opaque(fill),
      shape: shape,
      borderRadius: shape == BoxShape.circle ? null : br(radius),
      border: t.tileFilled ? border : null,
      boxShadow: t.tileFilled ? shadow(3) : null,
    );
  }

  Color tileIcon(Color color) => !isClassic && t.tileFilled ? t.ink : color;

  /// Kategori vurgu rengi koyu tasarımda zemin üstünde okunsun diye açılır.
  Color readable(Color c) => !isClassic && dark ? Color.lerp(c, Colors.white, 0.45)! : c;

  /// Seri kartı dışındaki "zor gün / acil" tonu.
  Color get danger => t.danger;

  @override
  HavenStyle copyWith({HavenDesign? design}) => HavenStyle(design ?? this.design);

  @override
  HavenStyle lerp(HavenStyle? other, double t) => other == null || t < 0.5 ? this : other;
}

/// Uygulamadaki tüm kartlar: classic'te sıradan `Card` (değişiklik yok);
/// sert gölgeli tasarımda kartın altına mürekkep gölgesi eklenir.
class HavenCard extends StatelessWidget {
  const HavenCard({super.key, this.color, this.margin, this.clipBehavior, this.shape, this.elevation, this.child});

  final Color? color;
  final EdgeInsetsGeometry? margin;
  final Clip? clipBehavior;
  final ShapeBorder? shape;
  final double? elevation;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final s = HavenStyle.of(context);
    if (!s.t.hardShadow || s.isClassic) {
      return Card(
        color: color,
        margin: margin,
        clipBehavior: clipBehavior,
        shape: shape,
        elevation: elevation,
        child: child,
      );
    }
    final radius = s.t.radius;
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), boxShadow: s.shadow()),
        child: Card(
          color: color == null ? null : s._opaque(color!),
          margin: EdgeInsets.zero,
          clipBehavior: clipBehavior,
          shape: shape,
          elevation: elevation,
          child: child,
        ),
      ),
    );
  }
}
