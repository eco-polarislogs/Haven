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

/// Bir alanın günlük değerlendirme kartı. Her alan ana sayfada TEK kez
/// görünür: başlık, iyi geçen gün sayısı, rekor yarışı satırı ve ince çubuk,
/// altında o günün sorusu ve "İyi geçti / Zordu" düğmeleri. Bugün kaydı
/// yapıldıysa düğmelerin yerinde günün sonucu yazar; yarın düğmeler yine gelir.
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
    final today = todayKey();
    final race = recordRaceOf(struggle.streak, today);
    final done = struggle.checkedInOn(today);
    final hard = struggle.lastResult == CheckInResult.hard;

    return Card(
      color: categoryCardColor(struggle.category, scheme),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CategoryIcon(category: struggle.category, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Text(struggle.type.label, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${struggle.streak.totalKindDays}',
                    style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: accent)),
                Text(l.kindDays, style: t.labelSmall),
              ]),
            ]),
            const SizedBox(height: 6),
            Text(raceLine(context, race), style: t.bodySmall),
            if (race.best > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: LinearProgressIndicator(
                  value: race.progress,
                  minHeight: 6,
                  color: accent,
                  backgroundColor: accent.withValues(alpha: 0.15),
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (!done) ...[
              Text(struggle.category.checkInQuestion, style: t.bodyMedium),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: accent),
                    onPressed: () => checkIn(context, ref, struggle, CheckInResult.kind, recentHardDays),
                    icon: const Icon(Icons.light_mode_rounded, size: 18),
                    label: Text(l.wentWell),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => checkIn(context, ref, struggle, CheckInResult.hard, recentHardDays),
                    icon: const Icon(Icons.cloud_outlined, size: 18),
                    label: Text(l.wasHard),
                  ),
                ),
              ]),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: scheme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Icon(hard ? Icons.favorite_border_rounded : Icons.check_circle_outline_rounded,
                      size: 20, color: hard ? HavenColors.clay : accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hard
                          ? 'Bugün zor bir gündü ve yine de buradasın. Bu da bir adım.'
                          : 'Bugünü kaydettin. Yarın yine buradayız.',
                      style: t.bodyMedium,
                    ),
                  ),
                ]),
              ),
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
