import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/month_log.dart';
import '../../l10n/tx.dart';

/// "Bu ayın ışıkları": her nazik gün bir ışık yakar. Zor günler yumuşak kil
/// tonunda; kayıt olmayan günler boş. Kırmızı çarpı yok.
class MonthLights extends StatelessWidget {
  const MonthLights({super.key, required this.month, required this.log});

  final DateTime month;
  final MonthLog log;

  static List<String> get _weekdays => weekdayShort();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1;
    final now = DateTime.now();
    final isCurrent = now.year == month.year && now.month == month.month;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tx('İyi geçen her gün bir ışık yakar.'), style: t.bodySmall),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final w in _weekdays)
                  Expanded(
                    child: Text(w, textAlign: TextAlign.center, style: t.labelSmall),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                for (var i = 0; i < leading; i++) const SizedBox.shrink(),
                for (var d = 1; d <= daysInMonth; d++)
                  _Day(
                    day: d,
                    status: log.statusOf(d),
                    isToday: isCurrent && d == now.day,
                    isFuture: isCurrent && d > now.day,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _legend(context, HavenColors.kindDay, tx('İyi geçen gün')),
                const SizedBox(width: 14),
                _legend(context, HavenColors.hardDay, tx('Zor gün')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(BuildContext context, Color c, String label) => Row(
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

class _Day extends StatelessWidget {
  const _Day({required this.day, required this.status, required this.isToday, required this.isFuture});

  final int day;
  final DayStatus status;
  final bool isToday;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = switch (status) {
      DayStatus.kind => HavenColors.kindDay,
      DayStatus.hard => HavenColors.hardDay,
      DayStatus.none => Colors.transparent,
    };
    return Semantics(
      label: tx('{day}. gün, {p}', {
        'day': day,
        'p': switch (status) {
          DayStatus.kind => tx('iyi geçen gün'),
          DayStatus.hard => tx('zor gün'),
          DayStatus.none => tx('kayıt yok'),
        },
      }),
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: scheme.primary, width: 2)
              : status == DayStatus.none
              ? Border.all(color: scheme.outlineVariant)
              : null,
        ),
        alignment: Alignment.center,
        child: status == DayStatus.kind
            ? const Icon(Icons.light_mode_rounded, size: 16, color: Colors.white)
            : Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  color: isFuture
                      ? scheme.onSurface.withValues(alpha: 0.35)
                      : status == DayStatus.hard
                      ? HavenColors.ink
                      : scheme.onSurface,
                ),
              ),
      ),
    );
  }
}
