import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/struggle.dart';
import '../../l10n/tx.dart';
import '../../providers.dart';
import '../../core/theme/app_theme.dart';

/// Duolingo tarzı rozetler: küçük adımları görünür kılar. Hiçbiri kaybedilmez;
/// zor bir gün rozetleri silmez (I Am Sober mantığı: emek kalıcıdır).
class HavenBadge {
  const HavenBadge(this.emoji, this.titleTr, this.howTr, this.earned);
  final String emoji;
  final String titleTr;
  final String howTr;
  final bool earned;
  String get title => tx(titleTr);
  String get how => tx(howTr);
}

/// Saf hesap (testli).
List<HavenBadge> computeBadges({
  required int best,
  required int totalKind,
  required bool comeback,
  required int posts,
  required int supportsGiven,
  required int journal,
  required int friends,
}) => [
  HavenBadge('👣', 'İlk adım', 'İlk iyi gününü kaydet.', totalKind >= 1),
  HavenBadge('🔥', '3 günlük seri', '3 gün üst üste kendine geri dön.', best >= 3),
  HavenBadge('⭐', 'Bir hafta', '7 günlük seriye ulaş.', best >= 7),
  HavenBadge('🏅', 'İki hafta', '14 günlük seriye ulaş.', best >= 14),
  HavenBadge('🏆', 'Bir ay', '30 günlük seriye ulaş.', best >= 30),
  HavenBadge('💎', '100 gün', '100 günlük seriye ulaş.', best >= 100),
  HavenBadge('🌟', '50 iyi gün', 'Toplam 50 iyi geçen gün biriktir.', totalKind >= 50),
  HavenBadge('🔄', 'Yeniden başladın', 'Bir aradan sonra yeniden başla; bu en güçlü adımlardan biri.', comeback),
  HavenBadge('💬', 'İlk paylaşım', 'Toplulukta ilk paylaşımını yap.', posts >= 1),
  HavenBadge('🤝', 'Destek veren', 'Bir paylaşıma destek ver.', supportsGiven >= 1),
  HavenBadge('💙', 'Destek kalbi', '10 paylaşıma destek ver.', supportsGiven >= 10),
  HavenBadge('📓', 'Günlük yazarı', 'Kendine ilk notunu yaz.', journal >= 1),
  HavenBadge('✍️', 'Düzenli yazar', 'Kendine 10 not yaz.', journal >= 10),
  HavenBadge('👋', 'İlk arkadaş', 'Toplulukta bir arkadaş ekle.', friends >= 1),
];

/// Profildeki "Rozetlerim" bölümü.
class BadgesSection extends ConsumerWidget {
  const BadgesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(uidProvider);
    final user = ref.watch(appUserProvider).value;
    final struggles = ref.watch(strugglesProvider).value ?? const <Struggle>[];
    final named = uid == null ? 0 : (ref.watch(userNotesProvider(uid)).value?.length ?? 0);
    final anon = ref.watch(myAnonNoteIdsProvider).value?.length ?? 0;
    final badges = computeBadges(
      best: ref.watch(bestStreakProvider),
      totalKind: struggles.fold(0, (a, s) => a + s.streak.totalKindDays),
      comeback: struggles.any((s) => s.streak.history.isNotEmpty && s.streak.current > 0),
      posts: named + anon,
      supportsGiven: user?.supportedNotes.length ?? 0,
      journal: ref.watch(journalProvider).value?.length ?? 0,
      friends: ref.watch(friendIdsProvider).value?.length ?? 0,
    );
    final earned = badges.where((b) => b.earned).length;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return HavenCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(tx('Rozetlerim'), style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Text('$earned / ${badges.length}', style: t.labelLarge?.copyWith(color: scheme.primary)),
              ],
            ),
            const SizedBox(height: 4),
            Text(tx('Rozetler hiçbir zaman silinmez; zor bir gün emeğini götürmez.'), style: t.bodySmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final b in badges)
                  Tooltip(
                    message: b.title,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          icon: Text(b.emoji, style: const TextStyle(fontSize: 40)),
                          title: Text(b.title),
                          content: Text(b.earned ? tx('Kazandın! {how}', {'how': b.how}) : b.how),
                          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tx('Tamam')))],
                        ),
                      ),
                      child: Opacity(
                        opacity: b.earned ? 1 : 0.3,
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: b.earned ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                          child: Text(b.emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
