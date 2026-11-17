import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/analytics_service.dart';
import '../../../providers.dart';
import '../../../l10n/tx.dart';

/// Baloncuk patlat: yavaşça yükselen baloncuklara dokun. Süre yok, kaybetmek
/// yok. Ellere güvenli bir uğraş (saç/deri yolma dürtüsü anları için).
class BubblePopGame extends ConsumerStatefulWidget {
  const BubblePopGame({super.key});

  @override
  ConsumerState<BubblePopGame> createState() => _BubblePopGameState();
}

class _Bubble {
  _Bubble(this.x, this.y, this.r, this.speed, this.color, this.phase);
  double x, y;
  final double r, speed, phase;
  final Color color;
}

class _Pop {
  _Pop(this.x, this.y, this.r, this.color);
  final double x, y, r;
  final Color color;
  double age = 0;
}

class _BubblePopGameState extends ConsumerState<BubblePopGame> with SingleTickerProviderStateMixin {
  static const _colors = [
    Color(0xFF2B6B73),
    Color(0xFF5B7DB1),
    Color(0xFF3E8E9B),
    Color(0xFFE3A64F),
    Color(0xFF6B7F5E),
  ];

  final _rand = Random();
  final _bubbles = <_Bubble>[];
  final _pops = <_Pop>[];
  late final Ticker _ticker;
  late final AnalyticsService _analytics;
  Duration _last = Duration.zero;
  Size _size = Size.zero;
  int _popped = 0;

  @override
  void initState() {
    super.initState();
    _analytics = ref.read(analyticsProvider);
    _ticker = createTicker(_tick)..start();
  }

  _Bubble _spawn({bool initial = false}) {
    final r = 24 + _rand.nextDouble() * 24;
    final w = max(_size.width, 2 * r + 1);
    return _Bubble(
      r + _rand.nextDouble() * (w - 2 * r),
      initial ? _rand.nextDouble() * _size.height : _size.height + r + _rand.nextDouble() * 80,
      r,
      28 + _rand.nextDouble() * 38,
      _colors[_rand.nextInt(_colors.length)],
      _rand.nextDouble() * pi * 2,
    );
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (_size.isEmpty) return;
    while (_bubbles.length < 10) {
      _bubbles.add(_spawn(initial: _bubbles.length < 6 && _popped == 0));
    }
    for (var i = 0; i < _bubbles.length; i++) {
      final b = _bubbles[i];
      b.y -= b.speed * dt;
      b.x += sin(b.phase + b.y / 45) * 0.35;
      if (b.y + b.r < 0) _bubbles[i] = _spawn();
    }
    for (final p in _pops) {
      p.age += dt;
    }
    _pops.removeWhere((p) => p.age > 0.4);
    setState(() {});
  }

  void _tap(Offset pos) {
    for (var i = _bubbles.length - 1; i >= 0; i--) {
      final b = _bubbles[i];
      if ((Offset(b.x, b.y) - pos).distance <= b.r + 6) {
        _pops.add(_Pop(b.x, b.y, b.r, b.color));
        _bubbles[i] = _spawn();
        _popped++;
        HapticFeedback.lightImpact();
        return;
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    if (_popped > 0) _analytics.gameFinished('bubbles', _popped);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(tx('Baloncuk patlat'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(tx('Acele yok, kaybetmek yok. Sadece dokun ve nefesini izle.'), style: t.bodyMedium),
                ),
                Chip(avatar: const Icon(Icons.bubble_chart_outlined, size: 18), label: Text('$_popped')),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                _size = c.biggest;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _tap(d.localPosition),
                  child: CustomPaint(size: Size.infinite, painter: _BubblePainter(_bubbles, _pops)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.bubbles, this.pops);
  final List<_Bubble> bubbles;
  final List<_Pop> pops;

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final c = Offset(b.x, b.y);
      canvas.drawCircle(c, b.r, Paint()..color = b.color.withValues(alpha: 0.18));
      canvas.drawCircle(
        c,
        b.r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = b.color.withValues(alpha: 0.7),
      );
      canvas.drawCircle(
        c + Offset(-b.r * 0.35, -b.r * 0.35),
        b.r * 0.18,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
    }
    for (final p in pops) {
      final k = p.age / 0.4;
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.r * (1 + k * 0.8),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - k)
          ..color = p.color.withValues(alpha: (1 - k) * 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => true;
}
