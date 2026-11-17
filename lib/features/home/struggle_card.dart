import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/day_key.dart';
import '../../core/utils/streak.dart';
import '../../data/models/community.dart';
import '../../data/models/struggle.dart';
import '../../data/services/local_notifier.dart';
import '../../l10n/l10n.dart';
import '../../providers.dart';
import '../onboarding/struggle_selector.dart';
import '../support/hard_day_sheet.dart';

const _milestones = <int, String>{
  1: 'İlk iyi günün! Her yolculuk tek bir adımla başlar.',
  3: '3 gün üst üste! Kendine gösterdiğin özen görülüyor.',
  7: 'Bir haftalık seri! Kendine bir teşekkür borçlusun.',
  14: 'İki hafta! Bu emek gerçekten çok değerli.',
  30: 'Bir ay! Kendinle gurur duyabilirsin.',
};

/// Bir alanın bugünkü kaydı: başlık + rekora doğru ince çubuk + iki düğme.
/// Kompakt tutuldu; bugün kaydı yapılan alanlar ana sayfada tek bir özet
/// kartta toplanır ([DoneTodayCard]), böylece sayfa kalabalıklaşmaz.
class StruggleCard extends ConsumerWidget {
  const StruggleCard({super.key, required this.struggle, required this.recentHardDays});

  final Struggle struggle;

  /// Son 7 günde "zordu" denilen gün sayısı (profesyonel destek önerisi için).
  final int recentHardDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    final accent = categoryAccent(struggle.category);
    final race = recordRaceOf(struggle.streak, todayKey());

    return Card(
      color: categoryCardColor(struggle.category, scheme),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CategoryIcon(category: struggle.category, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(struggle.type.label, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text(raceLine(context, race), style: t.bodySmall, maxLines: 2),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: LinearProgressIndicator(
                value: race.best == 0 ? 0 : race.progress,
                minHeight: 6,
                color: accent,
                backgroundColor: accent.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: 12),
            Text(struggle.category.checkInQuestion, style: t.bodyMedium),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () => checkIn(context, ref, struggle, CheckInResult.kind, recentHardDays),
                  icon: const Icon(Icons.light_mode_rounded, size: 18),
                  label: Text(l.wentWell),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () => checkIn(context, ref, struggle, CheckInResult.hard, recentHardDays),
                  icon: const Icon(Icons.cloud_outlined, size: 18),
                  label: Text(l.wasHard),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Rekor yarışını tek satırda, şefkatle anlatır (I Am Sober mantığı).
String raceLine(BuildContext context, RecordRace race) {
  final l = context.l10n;
  if (race.isNewRecord) return l.newRecordBody(race.live);
  if (race.best == 0) return l.journeyStart;
  if (race.isComeback) {
    return 'Geçen sefer ${race.lastPast?.days ?? race.best} gün harika ilerledin; '
        'şimdi ${race.best} günlük rekorunla yarışıyoruz.';
  }
  if (race.toRecord == 0) return l.recordReached;
  return '${l.daysCount(race.live)} · ${l.raceBody(race.toRecord)}';
}

/// Bugün kaydı yapılan alanlar: tek kartta, satır satır.
class DoneTodayCard extends StatelessWidget {
  const DoneTodayCard({super.key, required this.items});
  final List<Struggle> items;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final today = todayKey();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bugün kaydettiklerin', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          for (final s in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                CategoryIcon(category: s.category, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.type.label, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Text(raceLine(context, recordRaceOf(s.streak, today)), style: t.bodySmall, maxLines: 2),
                  ]),
                ),
                Icon(
                  s.lastResult == CheckInResult.hard ? Icons.favorite_border_rounded : Icons.check_circle_rounded,
                  color: s.lastResult == CheckInResult.hard ? HavenColors.clay : categoryAccent(s.category),
                ),
              ]),
            ),
          if (items.any((s) => s.lastResult == CheckInResult.hard))
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Text('Zor geçen bir gün de olsa buradasın. Bu da bir adım.', style: t.bodySmall),
            ),
        ]),
      ),
    );
  }
}

/// Kayıt mantığı (kart ve kısayollar ortak kullanır).
void checkIn(BuildContext context, WidgetRef ref, Struggle struggle, CheckInResult result, int recentHardDays) {
  final uid = ref.read(uidProvider);
  final user = ref.read(appUserProvider).value;
  if (uid == null || user == null) return;
  final repo = ref.read(repositoryProvider);
  final outcome = repo.checkIn(uid, struggle, result, daily: user.daily);
  if (outcome == null) return;

  // Kayıt yapıldı: akşam hatırlatmasını iptal et, merdiveni yeniden kur.
  LocalNotifier.scheduleGentleNudges(enabled: user.notificationsEnabled, checkedInToday: true);

  final daily = outcome.daily;
  ref.read(analyticsProvider).checkIn(struggle.category, result,
      gapDays: outcome.gapDays, dailyStreak: daily?.current);

  if (daily != null) {
    final profile = ref.read(myProfileProvider).value;
    final community = ref.read(communityRepositoryProvider);
    if (profile != null) community.syncStreak(uid, profile, daily);
    if (kStreakMilestones.contains(daily.current)) {
      repo.addInbox(uid, InboxType.streakMilestone, value: daily.current);
      if (profile != null) {
        community.notifyFriendsOfMilestone(profile, ref.read(friendIdsProvider).value ?? const [], daily.current);
      }
    }
  }

  if (result == CheckInResult.hard) {
    final last = user.lastSupportSuggestionDay;
    final today = todayKey();
    if (recentHardDays + 1 >= 3 && (last == null || daysBetween(last, today) >= 7)) {
      repo.addInbox(uid, InboxType.supportSuggestion);
      repo.markSupportSuggested(uid, today);
    }
    // Biten seri silinmez; şefkatle hatırlatılır.
    showHardDaySheet(context, struggle.category, endedStreak: struggle.streak.current);
  } else {
    final message =
        _milestones[outcome.state.current] ?? 'Bugünü kaydettin. Küçük adımlar da gerçek adımlardır.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
