import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/struggle_catalog.dart';
import '../../data/services/analytics_service.dart';
import '../../l10n/l10n.dart';
import '../../providers.dart';
import 'support_lines_card.dart';
import '../../l10n/tx.dart';

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
          Card(
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
