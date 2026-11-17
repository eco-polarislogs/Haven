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
import '../../core/navigation.dart';
import '../support/calm_screen.dart';
import '../support/hard_day_sheet.dart';
import '../../l10n/tx.dart';

// Getter: dil değişince yenilenir.
Map<int, String> get _milestones => {
  1: tx('İlk iyi günün! Her yolculuk tek bir adımla başlar.'),
  3: tx('3 gün üst üste! Kendine gösterdiğin özen görülüyor.'),
  7: tx('Bir haftalık seri! Kendine bir teşekkür borçlusun.'),
  14: tx('İki hafta! Bu emek gerçekten çok değerli.'),
  30: tx('Bir ay! Kendinle gurur duyabilirsin.'),
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
    final last = struggle.lastResult;

    return Card(
      color: categoryCardColor(struggle.category, scheme),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryIcon(category: struggle.category, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(struggle.type.label, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${struggle.streak.totalKindDays}',
                      style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: accent),
                    ),
                    Text(l.kindDays, style: t.labelSmall),
                  ],
                ),
              ],
            ),
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
              // Üç dürüst seçenek: başardım / zorlandım ama dayandım / başaramadım.
              // IntrinsicHeight: açıklaması uzun olan düğme diğerlerini de uzatır.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _ResultButton(
                        icon: Icons.check_circle_rounded,
                        label: tx('Başardım'),
                        hint: tx('Bugün iyi geçti'),
                        color: accent,
                        filled: true,
                        onTap: () => checkIn(context, ref, struggle, CheckInResult.kind, recentHardDays),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ResultButton(
                        icon: Icons.bolt_rounded,
                        label: tx('Zorlandım'),
                        hint: tx('Zor oldu ama dayandım'),
                        color: HavenColors.struggledDay,
                        onTap: () => checkIn(context, ref, struggle, CheckInResult.struggled, recentHardDays),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ResultButton(
                        icon: Icons.favorite_border_rounded,
                        label: tx('Başaramadım'),
                        hint: tx('Bugün olmadı'),
                        color: HavenColors.clay,
                        onTap: () => checkIn(context, ref, struggle, CheckInResult.hard, recentHardDays),
                      ),
                    ),
                  ],
                ),
              ),
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
                child: Row(
                  children: [
                    Icon(
                      switch (last) {
                        CheckInResult.hard => Icons.favorite_border_rounded,
                        CheckInResult.struggled => Icons.bolt_rounded,
                        _ => Icons.check_circle_outline_rounded,
                      },
                      size: 20,
                      color: switch (last) {
                        CheckInResult.hard => HavenColors.clay,
                        CheckInResult.struggled => HavenColors.struggledDay,
                        _ => accent,
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(switch (last) {
                        CheckInResult.hard => tx('Bugün zor bir gündü ve yine de buradasın. Bu da bir adım.'),
                        CheckInResult.struggled => tx('Zorlandın ama dayandın. Bu, en değerli başarılardan biri.'),
                        _ => tx('Bugünü kaydettin. Yarın yine buradayız.'),
                      }, style: t.bodyMedium),
                    ),
                  ],
                ),
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
    return tx('Geçen sefer {p} gün harika ilerledin; şimdi {best} günlük rekorunla yarışıyoruz.', {
      'p': race.lastPast?.days ?? race.best,
      'best': race.best,
    });
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
  LocalNotifier.scheduleFor(user, checkedInToday: true);

  final daily = outcome.daily;
  ref.read(analyticsProvider).checkIn(struggle.category, result, gapDays: outcome.gapDays, dailyStreak: daily?.current);

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
  } else if (result == CheckInResult.struggled) {
    // Dayanmak gerçek bir başarı: seri sürer; sakinleşme araçlarına kısa yol.
    final milestone = _milestones[outcome.state.current];
    final message = tx('Zorlandın ama dayandın; serin devam ediyor. Bu gerçek bir güç.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(milestone == null ? message : '$message $milestone'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: tx('Sakinleş'),
          onPressed: () => pushScreen(context, 'calm', CalmScreen(category: struggle.category)),
        ),
      ),
    );
  } else {
    final message = _milestones[outcome.state.current] ?? tx('Bugünü kaydettin. Küçük adımlar da gerçek adımlardır.');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Değerlendirme düğmesi: simge, kısa etiket ve altında ne anlama geldiği.
class _ResultButton extends StatelessWidget {
  const _ResultButton({
    required this.icon,
    required this.label,
    required this.hint,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final String hint;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final fg = filled ? Colors.white : HavenColors.ink;
    return Material(
      color: filled ? color : color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: filled ? Colors.white : color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: t.labelSmall?.copyWith(color: fg.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
