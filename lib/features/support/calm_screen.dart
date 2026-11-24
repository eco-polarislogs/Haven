import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/struggle_catalog.dart';
import '../../data/services/analytics_service.dart';
import '../../l10n/l10n.dart';
import '../../providers.dart';
import 'support_lines_card.dart';
import '../../l10n/tx.dart';
import '../../core/theme/app_theme.dart';

/// Sakinleşme köşesi: nefes egzersizi + kategoriye özel ipuçları + destek hatları.
/// Tamamen offline çalışır. REKLAM YOK.
class CalmScreen extends ConsumerStatefulWidget {
  const CalmScreen({super.key, this.category});

  final StruggleCategory? category;

  @override
  ConsumerState<CalmScreen> createState() => _CalmScreenState();
}

class _CalmScreenState extends ConsumerState<CalmScreen> with SingleTickerProviderStateMixin {
  // Al 4 sn · Tut 4 sn · Ver 6 sn: uzun nefes verme sinir sistemini yatıştırır.
  static const _inhaleSeconds = 4;
  static const _holdSeconds = 4;
  static const _exhaleSeconds = 6;
  static const _total = _inhaleSeconds + _holdSeconds + _exhaleSeconds;
  static const _inhaleEnd = _inhaleSeconds / _total;
  static const _holdEnd = (_inhaleSeconds + _holdSeconds) / _total;

  late final AnimationController _controller;
  // dispose() içinde `ref` kullanılamaz (Riverpod 3), bu yüzden baştan al.
  late final AnalyticsService _analytics;
  int _cycles = 0;
  double _lastValue = 0;

  @override
  void initState() {
    super.initState();
    _analytics = ref.read(analyticsProvider);
    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(seconds: _total),
          )
          ..addListener(_countCycles)
          ..repeat();
    _analytics.supportOpened(widget.category?.name ?? 'general');
  }

  void _countCycles() {
    if (_controller.value < _lastValue) setState(() => _cycles++);
    _lastValue = _controller.value;
  }

  @override
  void dispose() {
    if (_cycles > 0) _analytics.breathingFinished(_cycles);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final category = widget.category;
    final tips =
        category?.calmTips ??
        [
          tx('5-4-3-2-1: Gördüğün 5, duyduğun 4, dokunabildiğin 3 şeyi say.'),
          tx('Bir bardak su iç ve omuzlarını gevşet.'),
          tx('Ayaklarını yere bastır ve zeminin seni taşıdığını hisset.'),
        ];
    final supportFirst = category == StruggleCategory.selfHarm;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.breathingTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (supportFirst) ...[const SupportLinesCard(), const SizedBox(height: 24)],
          Text(tx('Birlikte nefes alalım'), textAlign: TextAlign.center, style: text.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 270,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                final l = context.l10n;
                final (phase, progress, secondsLeft) = t < _inhaleEnd
                    ? (
                        l.breatheIn,
                        Curves.easeInOut.transform(t / _inhaleEnd),
                        (_inhaleSeconds * (1 - t / _inhaleEnd)).ceil(),
                      )
                    : t < _holdEnd
                    ? (l.hold, 1.0, (_holdSeconds * (1 - (t - _inhaleEnd) / (_holdEnd - _inhaleEnd))).ceil())
                    : (
                        l.breatheOut,
                        1 - Curves.easeInOut.transform((t - _holdEnd) / (1 - _holdEnd)),
                        (_exhaleSeconds * (1 - (t - _holdEnd) / (1 - _holdEnd))).ceil(),
                      );
                final style = HavenStyle.of(context);
                if (!style.isClassic) {
                  return Center(
                    child: _BreathVisual(style: style, progress: progress, phase: phase, secondsLeft: secondsLeft),
                  );
                }
                final primary = Theme.of(context).colorScheme.primary;
                final size = 140 + 110 * progress;
                return Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // dış halka: hedef boyut
                      Container(
                        width: 252,
                        height: 252,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primary.withValues(alpha: 0.18), width: 2),
                        ),
                      ),
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [Color.lerp(primary, Colors.white, 0.65)!, primary]),
                          boxShadow: [
                            BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 40 * progress + 10),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              phase,
                              style: text.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                            Text('$secondsLeft', style: text.headlineSmall?.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _cycles == 0
                ? tx('Kendi hızında. Acele yok.')
                : tx('{cycles} nefes. Çok iyi gidiyorsun.', {'cycles': _cycles}),
            textAlign: TextAlign.center,
            style: text.bodyMedium,
          ),
          const SizedBox(height: 28),
          HavenCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx('Şu an işe yarayabilecekler'), style: text.titleMedium),
                  const SizedBox(height: 12),
                  for (final tip in tips)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(tip, style: text.bodyMedium)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!supportFirst) ...[const SizedBox(height: 16), const SupportLinesCard()],
        ],
      ),
    );
  }
}

/// Tasarıma özel nefes animasyonu (Klasik'te orijinal daire kullanılır).
/// [progress] 0 → 1: nefes alırken büyür, tutarken sabit, verirken küçülür.
class _BreathVisual extends StatelessWidget {
  const _BreathVisual({required this.style, required this.progress, required this.phase, required this.secondsLeft});

  final HavenStyle style;
  final double progress;
  final String phase;
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    final c = style.t;
    final size = 130 + 116 * progress;
    Widget label(Color color, {double fontSize = 28, FontWeight weight = FontWeight.w700}) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          phase,
          style: TextStyle(fontFamily: c.headingFont, fontSize: fontSize, fontWeight: weight, color: color),
        ),
        Text(
          '$secondsLeft',
          style: TextStyle(
            fontFamily: c.bodyFont,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: switch (c.breath) {
          // Sis: kesikli dış halka, adaçayı tonunda yumuşak daire.
          BreathStyle.ring => [
            CustomPaint(
              size: const Size(256, 256),
              painter: _DashedCircle(color: c.primary.withValues(alpha: 0.35)),
            ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primary.withValues(alpha: 0.12),
                border: Border.all(color: c.primary, width: 1.5),
              ),
            ),
            label(c.ink, weight: FontWeight.w400),
          ],
          // Gece Limanı: karanlıkta büyüyüp sönen kehribar ışık.
          BreathStyle.glow => [
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent.withValues(alpha: 0.06)),
            ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.accent.withValues(alpha: 0.18),
                boxShadow: [
                  BoxShadow(color: c.accent.withValues(alpha: 0.35), blurRadius: 30 + 40 * progress, spreadRadius: 4),
                ],
              ),
            ),
            Container(
              width: 96 + 30 * progress,
              height: 96 + 30 * progress,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.accent,
                boxShadow: [BoxShadow(color: c.accent, blurRadius: 24)],
              ),
              alignment: Alignment.center,
              child: label(c.onAccent, fontSize: 22, weight: FontWeight.w800),
            ),
          ],
          // Bahçe: nefesle açılıp kapanan çiçek.
          BreathStyle.bloom => [
            Container(
              width: 252,
              height: 252,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceAlt),
            ),
            Transform.rotate(
              angle: 0.4 * progress,
              child: CustomPaint(
                size: const Size(250, 250),
                painter: _Bloom(scale: 0.55 + 0.45 * progress, petal: const Color(0xFF7BA889)),
              ),
            ),
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.primary),
              alignment: Alignment.center,
              child: label(Colors.white, fontSize: 20, weight: FontWeight.w600),
            ),
          ],
          // Neşeli: kalın kenarlı, gölgeli, şişip inen balon.
          BreathStyle.puff => [
            CustomPaint(
              size: const Size(256, 256),
              painter: _DashedCircle(color: c.ink.withValues(alpha: 0.35), width: 2),
            ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.tiles[0],
                border: Border.all(color: c.ink, width: 2),
                boxShadow: [BoxShadow(color: c.ink, offset: const Offset(0, 6))],
              ),
            ),
            Positioned(
              top: 30,
              right: 34,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.accent,
                  border: Border.all(color: c.ink, width: 2),
                ),
              ),
            ),
            label(c.ink, fontSize: 34, weight: FontWeight.w900),
          ],
          // Defter: mürekkeple çizilmiş iç içe halkalar.
          BreathStyle.ink => [
            for (final k in [1.0, 0.8, 0.6])
              Container(
                width: 120 + 130 * progress * k,
                height: 120 + 130 * progress * k,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.primary.withValues(alpha: 0.25 + 0.5 * k), width: 1.2),
                ),
              ),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.surface,
                border: Border.all(color: c.primary, width: 1.5),
              ),
              alignment: Alignment.center,
              child: label(c.primary, fontSize: 22, weight: FontWeight.w600),
            ),
          ],
          // Net: kalın siyah halka, sarı dolgu, büyük yazı.
          BreathStyle.bold => [
            Container(
              width: 252,
              height: 252,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.ink, width: 4),
              ),
            ),
            Container(
              width: size - 8,
              height: size - 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.accent,
                border: Border.all(color: c.ink, width: 3),
              ),
            ),
            label(c.ink, fontSize: 34, weight: FontWeight.w800),
          ],
          BreathStyle.classic => const <Widget>[],
        },
      ),
    );
  }
}

class _DashedCircle extends CustomPainter {
  _DashedCircle({required this.color, this.width = 1.5});
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    final r = size.width / 2 - width;
    final center = size.center(Offset.zero);
    const dashes = 72;
    for (var i = 0; i < dashes; i++) {
      final a = 2 * math.pi * i / dashes;
      canvas.drawArc(Rect.fromCircle(center: center, radius: r), a, math.pi / dashes * 0.5, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCircle old) => old.color != color;
}

class _Bloom extends CustomPainter {
  _Bloom({required this.scale, required this.petal});
  final double scale;
  final Color petal;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = petal.withValues(alpha: 0.55);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    for (var i = 0; i < 8; i++) {
      canvas.save();
      canvas.rotate(math.pi / 4 * i);
      canvas.drawOval(Rect.fromCenter(center: const Offset(0, -74), width: 68, height: 124), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Bloom old) => old.scale != scale;
}
