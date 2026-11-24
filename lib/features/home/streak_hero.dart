import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/streak.dart';
import '../../data/models/month_log.dart';
import '../../l10n/l10n.dart';
import '../../l10n/tx.dart';

/// Duolingo tarzı günlük seri kartı: alev + gün sayısı + bu haftanın noktaları.
/// Şefkatli fark: bir gün kaçırmak seriyi bozmaz, "zordu" kaydı da sayılır.
///
/// Her tasarımın kendi seri kartı var (Sis: büyük sayı, Gece Limanı: ışık
/// halkası, Bahçe: büyüyen fidan, Neşeli: kalın kart, Defter: çizgili sayfa,
/// Net: yüksek karşıtlıklı blok). Klasik orijinal karttır.
class StreakHero extends StatelessWidget {
  const StreakHero({super.key, required this.daily, required this.today, required this.week, required this.doneToday});

  final DailyStreak daily;
  final String today;
  final List<DayStatus> week;
  final bool doneToday;

  static List<String> get _days => weekdayShort();

  @override
  Widget build(BuildContext context) {
    final s = HavenStyle.of(context);
    final data = _HeroData(
      live: daily.live(today),
      best: daily.longest,
      week: week,
      todayIndex: DateTime.now().weekday - 1,
      days: _days,
    );
    return switch (s.t.hero) {
      HeroStyle.gradient => _classic(context),
      HeroStyle.number => _NumberHero(data),
      HeroStyle.ring => _RingHero(data),
      HeroStyle.plant => _PlantHero(data),
      HeroStyle.chunky => _ChunkyHero(data),
      HeroStyle.notebook => _NotebookHero(data),
      HeroStyle.block => _BlockHero(data),
    };
  }

  /// Orijinal (Klasik) seri kartı: değiştirilmedi.
  Widget _classic(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final p = HavenPalette.of(context);
    final live = daily.live(today);
    final todayIndex = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.deep, Color.lerp(p.deep, p.primary, 0.75)!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.local_fire_department_rounded, size: 38, color: live > 0 ? p.accent : Colors.white54),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$live',
                          style: t.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Text(l.dailyStreak, style: t.titleMedium?.copyWith(color: Colors.white)),
                      ],
                    ),
                    Text(l.bestStreak(daily.longest), style: t.bodySmall?.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: switch (week[i]) {
                          DayStatus.kind || DayStatus.struggled || DayStatus.hard => p.accent,
                          DayStatus.none => Colors.white.withValues(alpha: 0.1),
                        },
                        border: i == todayIndex ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                      child: week[i] == DayStatus.none ? null : Icon(Icons.check_rounded, size: 18, color: p.deep),
                    ),
                    const SizedBox(height: 4),
                    Text(_days[i], style: t.labelSmall?.copyWith(color: Colors.white70)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            doneToday ? '${l.streakDoneToday} ✓' : l.streakNotDone,
            style: t.bodyMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _HeroData {
  const _HeroData({
    required this.live,
    required this.best,
    required this.week,
    required this.todayIndex,
    required this.days,
  });

  final int live;
  final int best;
  final List<DayStatus> week;
  final int todayIndex;
  final List<String> days;

  bool done(int i) => week[i] != DayStatus.none;

  /// Rekora doğru ilerleme (rekor yoksa bir haftaya göre).
  double get progress => (live / math.max(best, 7)).clamp(0, 1).toDouble();
}

/// Haftanın günleri: her tasarım kendi gün kutusunu çizer.
class _WeekRow extends StatelessWidget {
  const _WeekRow(this.d, {required this.cell, required this.labelColor});

  final _HeroData d;
  final Widget Function(int i) cell;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          Column(
            children: [
              cell(i),
              const SizedBox(height: 6),
              Text(
                d.days[i],
                style: t.labelSmall?.copyWith(
                  color: labelColor,
                  fontWeight: i == d.todayIndex ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ------------------------------------------------------------ A · Sis
class _NumberHero extends StatelessWidget {
  const _NumberHero(this.d);
  final _HeroData d;

  @override
  Widget build(BuildContext context) {
    final s = HavenStyle.of(context);
    final c = s.t;
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: s.box(color: c.surface, radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${d.live}',
                style: TextStyle(
                  fontFamily: c.headingFont,
                  fontSize: 72,
                  height: 0.95,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -3,
                  color: c.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.dailyStreak, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text(l.bestStreak(d.best), style: t.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _WeekRow(
            d,
            labelColor: c.muted,
            cell: (i) => Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: d.done(i) ? c.primary : Colors.transparent,
                border: Border.all(
                  color: d.done(i) ? c.primary : (i == d.todayIndex ? c.ink : c.outline),
                  width: i == d.todayIndex ? 2 : 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ B · Gece Limanı
class _RingHero extends StatelessWidget {
  const _RingHero(this.d);
  final _HeroData d;

  @override
  Widget build(BuildContext context) {
    final s = HavenStyle.of(context);
    final c = s.t;
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: s.box(color: c.surface, radius: 26),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 128,
                height: 128,
                child: CustomPaint(
                  painter: _RingPainter(progress: d.progress, color: c.accent, track: const Color(0xFF1F3542)),
                  child: Center(
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.background,
                        boxShadow: [BoxShadow(color: c.accent.withValues(alpha: 0.22), blurRadius: 30)],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${d.live}',
                        style: TextStyle(
                          fontFamily: c.headingFont,
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: c.accent,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.dailyStreak, style: t.titleLarge?.copyWith(color: c.ink)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.emoji_events_outlined, size: 18, color: c.accent),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(l.bestStreak(d.best), style: t.bodyMedium?.copyWith(color: c.muted)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _WeekRow(
            d,
            labelColor: c.muted,
            cell: (i) => Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: d.done(i) ? c.accent : const Color(0xFF1B3341),
                border: i == d.todayIndex ? Border.all(color: c.ink, width: 2) : null,
                boxShadow: d.done(i) ? [BoxShadow(color: c.accent.withValues(alpha: 0.45), blurRadius: 12)] : null,
              ),
              child: d.done(i) ? Icon(Icons.check_rounded, size: 16, color: c.onAccent) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color, required this.track});
  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(6);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = track;
    canvas.drawArc(r, 0, math.pi * 2, false, base);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = color;
    final sweep = math.pi * 2 * progress;
    canvas.drawArc(r, -math.pi / 2, sweep, false, glow);
    canvas.drawArc(r, -math.pi / 2, sweep, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}

// ------------------------------------------------------------ C · Bahçe
class _PlantHero extends StatelessWidget {
  const _PlantHero(this.d);
  final _HeroData d;

  @override
  Widget build(BuildContext context) {
    final s = HavenStyle.of(context);
    final c = s.t;
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
      decoration: s.box(color: c.surfaceAlt, radius: 28),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 132,
                child: CustomPaint(
                  painter: _PlantPainter(
                    days: d.live,
                    leaf: const Color(0xFF7BA889),
                    stem: const Color(0xFF5E8A6C),
                    pot: const Color(0xFFC98F6B),
                    sun: c.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${d.live}',
                      style: TextStyle(
                        fontFamily: c.headingFont,
                        fontSize: 56,
                        height: 1,
                        fontWeight: FontWeight.w600,
                        color: c.primary,
                      ),
                    ),
                    Text(
                      l.dailyStreak,
                      style: t.titleMedium?.copyWith(color: c.ink, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(l.bestStreak(d.best), style: t.bodyMedium?.copyWith(color: c.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
            child: _WeekRow(
              d,
              labelColor: c.muted,
              cell: (i) => Icon(
                d.done(i) ? Icons.eco_rounded : Icons.eco_outlined,
                size: 26,
                color: d.done(i) ? c.primary : (i == d.todayIndex ? c.ink : const Color(0xFF9FB39D)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fidan: gövde seriyle uzar, her iki günde bir yaprak çıkar (en fazla 10).
class _PlantPainter extends CustomPainter {
  _PlantPainter({required this.days, required this.leaf, required this.stem, required this.pot, required this.sun});
  final int days;
  final Color leaf;
  final Color stem;
  final Color pot;
  final Color sun;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // güneş
    canvas.drawCircle(Offset(w * 0.82, h * 0.14), 12, Paint()..color = sun);
    // saksı
    final potTop = h - 34;
    final potPath = Path()
      ..moveTo(w * 0.28, potTop)
      ..lineTo(w * 0.72, potTop)
      ..lineTo(w * 0.66, h - 2)
      ..lineTo(w * 0.34, h - 2)
      ..close();
    canvas.drawPath(potPath, Paint()..color = pot);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.24, potTop - 8, w * 0.52, 10), const Radius.circular(4)),
      Paint()..color = Color.lerp(pot, Colors.black, 0.12)!,
    );
    // gövde
    final grow = (days / 21).clamp(0.15, 1.0);
    final stemTop = potTop - 8 - (potTop - 18) * grow;
    final cx = w * 0.5;
    final stemPaint = Paint()
      ..color = stem
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final stemPath = Path()
      ..moveTo(cx, potTop - 8)
      ..quadraticBezierTo(cx - 6, (potTop + stemTop) / 2, cx, stemTop);
    canvas.drawPath(stemPath, stemPaint);
    // yapraklar
    final count = math.min(10, math.max(1, (days / 2).ceil()));
    final leafPaint = Paint()..color = leaf;
    for (var i = 0; i < count; i++) {
      final y = potTop - 16 - (potTop - 16 - stemTop) * (i + 1) / (count + 1);
      final left = i.isEven;
      canvas.save();
      canvas.translate(cx, y);
      canvas.rotate(left ? -0.7 : 0.7);
      final len = 16.0 + 4 * (1 - i / 10);
      canvas.drawOval(Rect.fromLTWH(left ? -len * 1.6 : len * 0.1, -len * 0.35, len * 1.5, len * 0.7), leafPaint);
      canvas.restore();
    }
    // tepe tomurcuğu
    canvas.drawCircle(Offset(cx, stemTop), 6, Paint()..color = sun);
  }

  @override
  bool shouldRepaint(_PlantPainter old) => old.days != days;
}

// ------------------------------------------------------------ D · Neşeli
class _ChunkyHero extends StatelessWidget {
  const _ChunkyHero(this.d);
  final _HeroData d;

  @override
  Widget build(BuildContext context) {
    final s = HavenStyle.of(context);
    final c = s.t;
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: s.box(color: c.primary, radius: 26, raised: true),
      child: Column(
        children: [
          Row(
            children: [
              Transform.rotate(
                angle: -0.06,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: s.box(color: c.accent, radius: 22, raised: true),
                  child: Icon(Icons.local_fire_department_rounded, size: 44, color: c.ink),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${d.live}',
                          style: TextStyle(
                            fontFamily: c.headingFont,
                            fontSize: 52,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l.dailyStreak,
                            style: t.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: c.ink, width: 2),
                      ),
                      child: Text(
                        l.bestStreak(d.best),
                        style: t.labelMedium?.copyWith(color: c.ink, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _WeekRow(
            d,
            labelColor: Colors.white,
            cell: (i) => Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: d.done(i) ? c.tiles[0] : Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: c.ink, width: i == d.todayIndex ? 3 : 2),
              ),
              child: d.done(i) ? Icon(Icons.check_rounded, size: 20, color: c.ink) : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ E · Defter
class _NotebookHero extends StatelessWidget {
  const _NotebookHero(this.d);
  final _HeroData d;

  @override
  Widget build(BuildContext context) {
    final s = HavenStyle.of(context);
    final c = s.t;
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    return Container(
      decoration: s.box(color: c.surface, radius: 8),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _RuledPainter(line: const Color(0xFFC9D6EA)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${d.live}',
                    style: TextStyle(
                      fontFamily: c.headingFont,
                      fontSize: 64,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l.dailyStreak,
                        style: TextStyle(
                          fontFamily: c.headingFont,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: c.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Fosforlu kalemle işaretlenmiş rekor.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                color: c.accent.withValues(alpha: 0.45),
                child: Text(
                  l.bestStreak(d.best),
                  style: t.bodyMedium?.copyWith(color: c.ink, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              _WeekRow(
                d,
                labelColor: c.muted,
                cell: (i) => Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: i == d.todayIndex ? c.primary : c.ink.withValues(alpha: 0.55),
                      width: i == d.todayIndex ? 2 : 1.2,
                    ),
                  ),
                  child: d.done(i) ? Icon(Icons.check_rounded, size: 20, color: c.primary) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuledPainter extends CustomPainter {
  _RuledPainter({required this.line});
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var y = 30.0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_RuledPainter old) => old.line != line;
}

// ------------------------------------------------------------ F · Net
class _BlockHero extends StatelessWidget {
  const _BlockHero(this.d);
  final _HeroData d;

  @override
  Widget build(BuildContext context) {
    final s = HavenStyle.of(context);
    final c = s.t;
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(color: c.deep, borderRadius: BorderRadius.circular(s.r(26))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${d.live}',
                style: TextStyle(
                  fontFamily: c.headingFont,
                  fontSize: 76,
                  height: 0.95,
                  fontWeight: FontWeight.w800,
                  color: c.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.dailyStreak,
                        style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      Text(l.bestStreak(d.best), style: t.bodyLarge?.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _WeekRow(
            d,
            labelColor: Colors.white,
            cell: (i) => Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: d.done(i) ? c.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: d.done(i) ? c.accent : Colors.white, width: i == d.todayIndex ? 3 : 2),
              ),
              child: d.done(i) ? Icon(Icons.check_rounded, size: 22, color: c.onAccent) : null,
            ),
          ),
        ],
      ),
    );
  }
}
