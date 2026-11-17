import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/streak.dart';
import '../../data/models/month_log.dart';
import '../../l10n/l10n.dart';
import '../../l10n/tx.dart';

/// Duolingo tarzı günlük seri kartı: alev + gün sayısı + bu haftanın noktaları.
/// Şefkatli fark: bir gün kaçırmak seriyi bozmaz, "zordu" kaydı da sayılır.
class StreakHero extends StatelessWidget {
  const StreakHero({super.key, required this.daily, required this.today, required this.week, required this.doneToday});

  final DailyStreak daily;
  final String today;
  final List<DayStatus> week;
  final bool doneToday;

  static List<String> get _days => weekdayShort();

  @override
  Widget build(BuildContext context) {
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
                          DayStatus.kind || DayStatus.hard => p.accent,
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
