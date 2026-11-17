import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/struggle_catalog.dart';
import '../../core/navigation.dart';
import '../../core/quotes/quote_engine.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/day_key.dart';
import '../../core/utils/streak.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/avatar_badge.dart';
import '../../data/models/month_log.dart';
import '../../data/models/struggle.dart';
import '../../l10n/l10n.dart';
import '../../providers.dart';
import '../journal/journal_screen.dart';
import '../notifications/notification_bell.dart';
import '../support/calm_screen.dart';
import '../support/professional_support_screen.dart';
import 'month_lights.dart';
import 'streak_hero.dart';
import 'struggle_card.dart';

/// Ana ekran panosu: seri, rekor, ilerleme, günün sözü, notlar ve kayıtlar —
/// tek ekranda, dolu ama sakin.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final user = ref.watch(appUserProvider).value;
    final struggles = ref.watch(strugglesProvider);
    final now = DateTime.now();
    final today = dayKey(now);
    final month = ref.watch(monthLogProvider(monthKey(now))).value ?? MonthLog.empty;
    final prevMonthDate = DateTime(now.year, now.month - 1, 1);
    final prevMonth = ref.watch(monthLogProvider(monthKey(prevMonthDate))).value ?? MonthLog.empty;

    DayStatus statusOn(DateTime d) {
      if (d.isAfter(now)) return DayStatus.none;
      if (d.year == now.year && d.month == now.month) return month.statusOf(d.day);
      if (d.year == prevMonthDate.year && d.month == prevMonthDate.month) return prevMonth.statusOf(d.day);
      return DayStatus.none;
    }

    final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final week = [for (var i = 0; i < 7; i++) statusOn(weekStart.add(Duration(days: i)))];
    final last30 = [for (var i = 0; i < 30; i++) statusOn(DateTime(now.year, now.month, now.day - i))];
    final hardDays7 = last30.take(7).where((s) => s == DayStatus.hard).length;
    // Oran KAYIT bazında: aynı gün bir alanda "zordu", diğerinde "iyi geçti"
    // denildiyse ikisi de sayılır (gün tamamen "zor" sayılıp emek silinmesin).
    var kind30 = 0, tracked30 = 0;
    for (var i = 0; i < 30; i++) {
      final d = DateTime(now.year, now.month, now.day - i);
      final log = (d.year == now.year && d.month == now.month) ? month : prevMonth;
      final entries = log.days[d.day]?.values ?? const <CheckInResult>[];
      tracked30 += entries.length;
      kind30 += entries.where((r) => r == CheckInResult.kind).length;
    }

    final list = struggles.value ?? const <Struggle>[];
    final categories = list.map((s) => s.category).toSet();
    final mostCare = highestCare(categories);
    final daily = user?.daily ?? const DailyStreak();
    final best = ref.watch(bestStreakProvider);
    final doneToday = list.any((s) => s.checkedInOn(today));
    final quote = QuoteEngine.pick(
        now: now, liveStreak: daily.live(today), bestStreak: daily.longest, categories: categories);

    // "Tümsek" kartı: seri dinlenmede ama daha önce güzel bir seri vardı.
    final comeback = list
        .map((s) => (s, recordRaceOf(s.streak, today)))
        .where((e) => e.$2.isComeback)
        .fold<(Struggle, RecordRace)?>(null, (a, e) => a == null || e.$2.best > a.$2.best ? e : a);

    return Scaffold(
      appBar: AppBar(
        title: Text(_greeting(context, user?.nickname)),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_home',
        onPressed: () => ref.read(shellIndexProvider.notifier).select(2),
        icon: const Icon(Icons.favorite_rounded),
        label: Text(l.imStruggling),
      ),
      body: struggles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Kayıtlarına şu an ulaşamadık.')),
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 112),
          children: [
            StreakHero(daily: daily, today: today, week: week, doneToday: doneToday),
            const SizedBox(height: 14),
            _QuoteCard(quote: quote),
            if (comeback != null) ...[
              const SizedBox(height: 14),
              _ComebackCard(struggle: comeback.$1, race: comeback.$2),
            ],
            const SizedBox(height: 14),
            _QuickActions(mostCare: mostCare),
            if (hardDays7 >= 3) ...[
              const SizedBox(height: 14),
              const _SupportSuggestion(),
            ],
            SectionTitle(l.yourProgress),
            _ProgressRow(
              current: daily.live(today),
              best: best,
              percent30: kind30 == 0 ? null : (kind30 * 100 / tracked30).round(),
            ),
            SectionTitle(l.todayRecords),
            // Her alan için TEK kart: günün sorusu + "İyi geçti / Zordu".
            // (Eskiden her alan ayrıca "İlerlemen" altında rekor kutusu olarak
            // tekrar görünüyordu; rekor bilgisi artık bu kartın içinde.)
            for (final s in items) ...[
              StruggleCard(struggle: s, recentHardDays: hardDays7),
              const SizedBox(height: 12),
            ],
            SectionTitle(l.myNotes,
                trailing: TextButton(
                  onPressed: () => pushScreen(context, 'journal', const JournalScreen()),
                  child: Text(l.seeAll),
                )),
            const _NotesPreview(),
            SectionTitle(l.monthLights),
            MonthLights(month: now, log: month),
            const SizedBox(height: 16),
            Text('$kGlobalFact  (Kaynak: $kGlobalFactSource)',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  static String _greeting(BuildContext context, String? nickname) {
    final l = context.l10n;
    final h = DateTime.now().hour;
    final base = h < 6
        ? l.greetingNight
        : h < 12
            ? l.greetingMorning
            : h < 18
                ? l.greetingDay
                : l.greetingEvening;
    final first = nickname?.trim() ?? '';
    return first.isEmpty ? base : '$base, $first';
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});
  final DailyQuote quote;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.format_quote_rounded, color: scheme.tertiary, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${context.l10n.quoteTitle} · ${quote.context}',
                  style: t.labelLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(quote.text, style: t.titleMedium?.copyWith(height: 1.35)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// I Am Sober mantığı, şefkatle: geçmiş başarı hatırlatılır, kişi kendi
/// rekoruyla yarışır. Suçlama, "sıfırlandı" ya da kırmızı yok.
class _ComebackCard extends StatelessWidget {
  const _ComebackCard({required this.struggle, required this.race});
  final Struggle struggle;
  final RecordRace race;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final p = HavenPalette.of(context);
    final past = race.lastPast?.days ?? race.best;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: p.accent.withValues(alpha: 0.14),
        border: Border.all(color: p.accent.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.landscape_outlined, color: p.accent),
          const SizedBox(width: 10),
          Expanded(child: Text(l.comebackTitle, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 4),
        Text(struggle.type.label, style: t.labelMedium),
        const SizedBox(height: 8),
        Text(l.comebackBody(past, race.best), style: t.bodyMedium?.copyWith(height: 1.4)),
        const SizedBox(height: 12),
        _RaceBar(live: race.live, best: race.best),
      ]),
    );
  }
}

class _RaceBar extends StatelessWidget {
  const _RaceBar({required this.live, required this.best});
  final int live;
  final int best;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = HavenPalette.of(context);
    final value = best == 0 ? 0.0 : (live / best).clamp(0, 1).toDouble();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 10,
          color: p.accent,
          backgroundColor: p.accent.withValues(alpha: 0.18),
        ),
      ),
      const SizedBox(height: 6),
      Row(children: [
        Text(context.l10n.daysCount(live), style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
        const Spacer(),
        Icon(Icons.emoji_events_outlined, size: 16, color: p.accent),
        const SizedBox(width: 4),
        Text(context.l10n.recordLabel(best), style: t.labelMedium),
      ]),
    ]);
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.current, required this.best, required this.percent30});
  final int current;
  final int best;
  final int? percent30;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(children: [
      _StatTile(Icons.local_fire_department_rounded, '$current', l.currentStreak),
      const SizedBox(width: 10),
      _StatTile(Icons.emoji_events_outlined, '$best', l.personalBest),
      const SizedBox(width: 10),
      // Hiç nazik kayıt yoksa "%0" yerine yumuşak bir "Başlangıç".
      _StatTile(Icons.insights_rounded, percent30 == null ? l.beginning : '%$percent30', l.last30Days),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(children: [
            Icon(icon, color: scheme.tertiary),
            const SizedBox(height: 4),
            Text(value, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            Text(label, style: t.labelSmall, textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

class _NotesPreview extends ConsumerWidget {
  const _NotesPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final notes = ref.watch(journalProvider).value ?? const [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (notes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(l.noNotesYet, style: t.bodyMedium),
            )
          else
            for (final n in notes.take(2))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.edit_note_rounded, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(n.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodyMedium),
                      Text(timeAgo(n.createdAt), style: t.labelSmall),
                    ]),
                  ),
                ]),
              ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => showAddJournalSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(l.addNote),
            ),
          ),
        ]),
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions({required this.mostCare});
  final StruggleCategory? mostCare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    void tab(int i) => ref.read(shellIndexProvider.notifier).select(i);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _Action(Icons.air_rounded, l.quickBreath, const Color(0xFF2F7C93),
            () => pushScreen(context, 'calm', CalmScreen(category: mostCare))),
        _Action(Icons.extension_outlined, l.quickGames, const Color(0xFF5B7DB1), () => tab(2)),
        _Action(Icons.groups_outlined, l.quickCommunity, const Color(0xFF4E8063), () => tab(1)),
        _Action(Icons.volunteer_activism_outlined, l.quickSupport, const Color(0xFFA9783C),
            () => pushScreen(context, 'professional_support', const ProfessionalSupportScreen())),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ]),
      ),
    );
  }
}

class _SupportSuggestion extends StatelessWidget {
  const _SupportSuggestion();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.tertiary.withValues(alpha: 0.13),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.volunteer_activism_outlined, color: scheme.tertiary),
            const SizedBox(width: 10),
            Expanded(
                child: Text('Son günlerin zor geçmiş görünüyor',
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 8),
          Text('Bu bir sinyal, bir yargı değil. Bir uzmanla konuşmak gerçekten iyi gelebilir. '
              'Nereden başlayacağını birlikte bulalım.',
              style: t.bodyMedium),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => pushScreen(context, 'professional_support', const ProfessionalSupportScreen()),
            child: const Text('Destek seçeneklerine bak'),
          ),
        ]),
      ),
    );
  }
}
