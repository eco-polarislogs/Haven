import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/tx.dart';

/// Profil → Tasarım: yedi görünümün küçük önizlemeleri. Her önizleme o
/// tasarımın kendi renkleri, köşeleri, kenarlıkları ve yazı tipiyle çizilir;
/// dokununca tüm uygulama o tasarıma geçer.
class DesignPicker extends StatefulWidget {
  const DesignPicker({super.key, required this.selected, required this.classicPreset, required this.onSelect});

  final HavenDesign selected;

  /// Klasik önizlemesi seçili renk temasıyla çizilir.
  final ThemePreset classicPreset;
  final ValueChanged<HavenDesign> onSelect;

  @override
  State<DesignPicker> createState() => _DesignPickerState();
}

class _DesignPickerState extends State<DesignPicker> {
  static const _tileWidth = 108.0;
  static const _gap = 12.0;

  // Seçili tasarım görünür olsun diye liste ona kaydırılmış açılır.
  late final _controller = ScrollController(
    initialScrollOffset: (widget.selected.index - 1).clamp(0, HavenDesign.values.length) * (_tileWidth + _gap),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 186,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        itemCount: HavenDesign.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: _gap),
        itemBuilder: (context, i) {
          final d = HavenDesign.values[i];
          return _DesignTile(
            design: d,
            preset: widget.classicPreset,
            selected: d == widget.selected,
            onTap: () => widget.onSelect(d),
          );
        },
      ),
    );
  }
}

class _DesignTile extends StatelessWidget {
  const _DesignTile({required this.design, required this.preset, required this.selected, required this.onTap});

  final HavenDesign design;
  final ThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = design.tokens;
    final classic = design.isClassic;
    // Önizleme renkleri: Klasik'te seçili renk teması.
    final bg = classic ? preset.surface : c.background;
    final card = classic ? preset.card : c.surface;
    final ink = classic ? (preset.brightness == Brightness.dark ? const Color(0xFFE6ECEF) : HavenColors.ink) : c.ink;
    final primary = classic ? preset.primary : c.primary;
    final accent = classic ? preset.accent : c.accent;
    final border = classic || c.borderWidth == 0
        ? null
        : Border.all(color: c.outline, width: c.borderWidth.clamp(1, 2));
    final shadow = c.hardShadow && !classic ? [BoxShadow(color: c.ink, offset: const Offset(0, 2))] : null;
    double r(double base) => classic ? base : (base * c.radiusScale).clamp(c.minRadius, c.maxRadius).toDouble();

    final heroColor = switch (c.hero) {
      HeroStyle.gradient => classic ? preset.deep : c.deep,
      HeroStyle.number || HeroStyle.notebook || HeroStyle.ring => card,
      HeroStyle.plant => c.surfaceAlt,
      HeroStyle.chunky => c.primary,
      HeroStyle.block => c.deep,
    };
    final numberColor = switch (c.hero) {
      HeroStyle.gradient || HeroStyle.chunky => Colors.white,
      HeroStyle.number => c.ink,
      HeroStyle.ring || HeroStyle.block => c.accent,
      HeroStyle.plant || HeroStyle.notebook => c.primary,
    };

    return Semantics(
      button: true,
      selected: selected,
      label: tx('Tasarım: {p}', {'p': design.label}),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _DesignPickerState._tileWidth,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? scheme.primary : Colors.transparent, width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              color: bg,
              padding: const EdgeInsets.fromLTRB(9, 10, 9, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seri kartı
                  Container(
                    height: 52,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: BoxDecoration(
                      color: heroColor,
                      gradient: c.hero == HeroStyle.gradient
                          ? LinearGradient(colors: [preset.deep, Color.lerp(preset.deep, preset.primary, 0.75)!])
                          : null,
                      borderRadius: BorderRadius.circular(r(14)),
                      border: c.hero == HeroStyle.block || c.hero == HeroStyle.gradient ? null : border,
                      boxShadow: shadow,
                    ),
                    child: Row(
                      children: [
                        if (c.hero == HeroStyle.ring)
                          Container(
                            width: 26,
                            height: 26,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: c.accent, width: 3),
                              boxShadow: [BoxShadow(color: c.accent.withValues(alpha: 0.4), blurRadius: 8)],
                            ),
                          ),
                        if (c.hero == HeroStyle.plant)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.eco_rounded, size: 22, color: c.primary),
                          ),
                        Text(
                          '12',
                          style: TextStyle(
                            fontFamily: classic ? null : c.headingFont,
                            fontSize: 24,
                            height: 1,
                            fontWeight: classic ? FontWeight.w700 : c.headingWeight,
                            color: numberColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // İki kart satırı
                  for (final w in [1.0, 0.72])
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: w,
                      child: Container(
                        height: 18,
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(r(8)),
                          border: border,
                          boxShadow: shadow,
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  // Kısayol renkleri
                  Row(
                    children: [
                      for (final color in [primary, accent, if (!classic) c.tiles[2] else HavenColors.slate])
                        Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            color: color,
                            shape: c.squareDays && !classic ? BoxShape.rectangle : BoxShape.circle,
                            borderRadius: c.squareDays && !classic ? BorderRadius.circular(r(5)) : null,
                            border: c.hardShadow && !classic ? Border.all(color: c.ink, width: 1.5) : null,
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            design.label,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: classic ? null : c.headingFont,
                              fontSize: 14,
                              fontWeight: classic ? FontWeight.w700 : c.headingWeight,
                              color: ink,
                            ),
                          ),
                        ),
                      ),
                      if (selected) Icon(Icons.check_circle_rounded, size: 18, color: primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
