import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/ad_ids.dart';
import '../../core/navigation.dart';
import '../../core/theme/theme_presets.dart';
import '../../data/services/ad_service.dart';
import '../../providers.dart';
import '../rewards/gifts_screen.dart';

/// Kilitli bir tema düğmesine dokununca: "seriyle açılır" bilgisi ve —
/// reklam izni varsa — "Kısa bir reklam izle ve şimdi aç" seçeneği.
/// Reklam tamamen isteğe bağlıdır; her tema seriyle de açılır.
Future<void> offerThemeUnlock(BuildContext context, WidgetRef ref, ThemePreset preset) async {
  final user = ref.read(appUserProvider).value;
  final uid = ref.read(uidProvider);
  if (user == null || uid == null) return;
  final best = ref.read(bestStreakProvider);
  final left = (preset.unlockStreak - best).clamp(1, 999);
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
                  CircleAvatar(backgroundColor: preset.primary, radius: 14),
                  const SizedBox(width: 10),
                  Expanded(child: Text(preset.label, style: t.titleLarge)),
                ],
              ),
              const SizedBox(height: 10),
              Text('${preset.unlockStreak} günlük seride kendiliğinden açılır · $left gün kaldı.', style: t.bodyMedium),
              const SizedBox(height: 16),
              if (user.adsAllowed)
                FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'ad'),
                  icon: const Icon(Icons.ondemand_video_rounded),
                  label: const Text('Kısa bir reklam izle ve şimdi aç'),
                )
              else
                Text('Reklamlar kapalı. İstersen Profil → "Filtreli reklamlar" ile açabilirsin.', style: t.bodySmall),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.pop(ctx, 'gifts'), child: const Text('Tüm hediyeleri gör')),
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
    messenger.showSnackBar(const SnackBar(content: Text('Şu an reklam bulunamadı. Biraz sonra tekrar dener misin?')));
    return;
  }
  var earned = false;
  ad.fullScreenContentCallback = FullScreenContentCallback(
    onAdDismissedFullScreenContent: (ad) {
      ad.dispose();
      if (earned) {
        messenger.showSnackBar(SnackBar(content: Text('${preset.label} açıldı ve uygulandı. Keyfini çıkar! 🎁')));
      }
    },
    onAdFailedToShowFullScreenContent: (ad, _) => ad.dispose(),
  );
  await ad.show(
    onUserEarnedReward: (_, _) {
      earned = true;
      repo.unlockGift(uid, preset.name);
      repo.setTheme(uid, preset.name);
      analytics.rewardEarned('theme_${preset.name}');
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
