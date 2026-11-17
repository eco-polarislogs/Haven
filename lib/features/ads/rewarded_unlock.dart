import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/ad_ids.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/avatar_badge.dart';
import '../../core/navigation.dart';
import '../../core/theme/theme_presets.dart';
import '../../data/services/ad_service.dart';
import '../../providers.dart';
import '../rewards/gifts_screen.dart';
import '../../l10n/tx.dart';

/// Kilitli bir tema düğmesine dokununca: seriyle açılma bilgisi ve (reklam
/// izni varsa) "Kısa bir reklam izle ve şimdi aç". Reklam tamamen isteğe bağlı.
Future<void> offerThemeUnlock(BuildContext context, WidgetRef ref, ThemePreset preset) {
  final repo = ref.read(repositoryProvider);
  final uid = ref.read(uidProvider);
  return offerGiftUnlock(
    context,
    ref,
    giftId: preset.name,
    title: preset.label,
    unlockStreak: preset.unlockStreak,
    leading: CircleAvatar(backgroundColor: preset.primary, radius: 14),
    onUnlocked: () {
      if (uid != null) repo.setTheme(uid, preset.name);
    },
  );
}

/// Kilitli bir avatara dokununca (profil düzenleme): aynı akış.
Future<void> offerAvatarUnlock(BuildContext context, WidgetRef ref, int index, {VoidCallback? onUnlocked}) {
  final a = kAvatars[index];
  return offerGiftUnlock(
    context,
    ref,
    giftId: 'avatar_$index',
    title: a.nick,
    unlockStreak: a.unlockStreak,
    leading: AvatarBadge(index: index, radius: 16),
    onUnlocked: onUnlocked,
  );
}

/// Ortak akış: bilgi sayfası → (isteğe bağlı) ödüllü reklam → hediye açılır.
Future<void> offerGiftUnlock(
  BuildContext context,
  WidgetRef ref, {
  required String giftId,
  required String title,
  required int unlockStreak,
  required Widget leading,
  VoidCallback? onUnlocked,
}) async {
  final user = ref.read(appUserProvider).value;
  final uid = ref.read(uidProvider);
  if (user == null || uid == null) return;
  final best = ref.read(bestStreakProvider);
  final left = (unlockStreak - best).clamp(1, 999);
  final repo = ref.read(repositoryProvider);
  final analytics = ref.read(analyticsProvider);
  final messenger = ScaffoldMessenger.of(context);

  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  leading,
                  const SizedBox(width: 10),
                  Expanded(child: Text(title, style: t.titleLarge)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                tx('{unlockStreak} günlük seride kendiliğinden açılır · {left} gün kaldı.', {
                  'unlockStreak': unlockStreak,
                  'left': left,
                }),
                style: t.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (user.adsAllowed)
                FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'ad'),
                  icon: const Icon(Icons.ondemand_video_rounded),
                  label: Text(tx('Kısa bir reklam izle ve şimdi aç')),
                )
              else
                Text(
                  tx('Reklamlar kapalı. İstersen Profil → "Filtreli reklamlar" ile açabilirsin.'),
                  style: t.bodySmall,
                ),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.pop(ctx, 'gifts'), child: Text(tx('Tüm hediyeleri gör'))),
            ],
          ),
        ),
      );
    },
  );
  if (!context.mounted) return;
  if (choice == 'gifts') {
    pushScreen(context, 'gifts', const GiftsScreen());
    return;
  }
  if (choice != 'ad') return;

  // Reklam yüklenirken küçük bir bekleme göstergesi.
  final nav = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    ),
  );
  final ad = await _loadRewarded();
  nav.pop();
  if (ad == null) {
    messenger.showSnackBar(SnackBar(content: Text(tx('Şu an reklam bulunamadı. Biraz sonra tekrar dener misin?'))));
    return;
  }
  var earned = false;
  ad.fullScreenContentCallback = FullScreenContentCallback(
    onAdDismissedFullScreenContent: (ad) {
      ad.dispose();
      if (earned) {
        messenger.showSnackBar(
          SnackBar(content: Text(tx('{label} açıldı ve uygulandı. Keyfini çıkar! 🎁', {'label': title}))),
        );
      }
    },
    onAdFailedToShowFullScreenContent: (ad, _) => ad.dispose(),
  );
  await ad.show(
    onUserEarnedReward: (_, _) {
      earned = true;
      repo.unlockGift(uid, giftId);
      onUnlocked?.call();
      analytics.rewardEarned(giftId);
    },
  );
}

Future<RewardedAd?> _loadRewarded() async {
  if (!await AdService.ensureReady()) return null;
  final done = Completer<RewardedAd?>();
  await RewardedAd.load(
    adUnitId: AdIds.rewarded,
    request: const AdRequest(nonPersonalizedAds: true),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      onAdLoaded: done.complete,
      onAdFailedToLoad: (e) {
        debugPrint('Ödüllü reklam yüklenemedi: ${e.code}');
        done.complete(null);
      },
    ),
  );
  return done.future.timeout(const Duration(seconds: 15), onTimeout: () => null);
}
