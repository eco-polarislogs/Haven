import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/ad_ids.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/day_key.dart';
import '../../core/widgets/avatar_badge.dart';
import '../../data/models/app_user.dart';
import '../../data/services/ad_service.dart';
import '../../l10n/l10n.dart';
import '../../providers.dart';
import '../../l10n/tx.dart';

/// "Hediyelerim": temalar ve hediye avatarlar SERİYLE kendiliğinden açılır —
/// kendine her gün geri dönmenin küçük ödülleri. Kısa bir ödüllü reklam
/// yalnızca isteğe bağlı ikinci yoldur.
///
/// Reklam güvenliği:
/// - Hassas kategorilerdeki (yeme, kendine zarar, madde, davranışsal) kullanıcılar
///   için reklam VARSAYILAN OLARAK KAPALI; kullanıcı isterse açar.
/// - İstekler kişiselleştirilmemiş ve G (genel izleyici) içerik sınırında.
/// - Banner/geçiş reklamı yok; kriz, nefes, oyun ve topluluk ekranlarında reklam yok.
class GiftsScreen extends ConsumerStatefulWidget {
  const GiftsScreen({super.key});

  @override
  ConsumerState<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends ConsumerState<GiftsScreen> {
  RewardedAd? _ad;
  bool _adStarted = false;

  void _maybeLoadAd(AppUser user) {
    if (_adStarted || !user.adsAllowed) return;
    _adStarted = true;
    AdService.ensureReady().then((ok) {
      if (!ok || !mounted) return;
      _loadAd();
    });
  }

  void _loadAd() {
    if (!mounted) return;
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(nonPersonalizedAds: true),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => mounted ? setState(() => _ad = ad) : ad.dispose(),
        onAdFailedToLoad: (e) => debugPrint('Ödüllü reklam yüklenemedi: ${e.code}'),
      ),
    );
  }

  /// Hediyeyi reklamla aç. Gereken her şey ŞİMDİ alınır (geri çağrıda ref yok).
  void _unlockWithAd(String giftId, String thanks) {
    final ad = _ad;
    final uid = ref.read(uidProvider);
    if (ad == null || uid == null) return;
    final repo = ref.read(repositoryProvider);
    final analytics = ref.read(analyticsProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _ad = null);
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (earned) messenger.showSnackBar(SnackBar(content: Text(thanks)));
        _loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadAd();
      },
    );
    ad.show(
      onUserEarnedReward: (_, _) {
        earned = true;
        if (giftId == 'extra_note') {
          repo.unlockDailyQuote(uid, todayKey());
        } else {
          repo.unlockGift(uid, giftId);
        }
        analytics.rewardEarned(giftId);
      },
    );
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final user = ref.watch(appUserProvider).value;
    final uid = ref.watch(uidProvider);
    final best = ref.watch(bestStreakProvider);
    final current = ref.watch(themePresetProvider);
    if (user == null || uid == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    _maybeLoadAd(user);
    final repo = ref.read(repositoryProvider);

    bool unlocked(int streak, String id) => isGiftUnlocked(unlockStreak: streak, id: id, best: best, user: user);

    // Sıradaki hediye: en yakın kilitli eşik.
    final thresholds = <(int, String)>[
      for (final p in ThemePreset.values)
        if (p.isGift && !unlocked(p.unlockStreak, p.name)) (p.unlockStreak, tx('{label} teması', {'label': p.label})),
      for (var i = 0; i < kAvatars.length; i++)
        if (kAvatars[i].isGift && !unlocked(kAvatars[i].unlockStreak, 'avatar_$i'))
          (kAvatars[i].unlockStreak, '${kAvatars[i].emoji} ${kAvatars[i].name}'),
    ]..sort((a, b) => a.$1 - b.$1);
    final next = thresholds.isEmpty ? null : thresholds.first;
    final adReady = _ad != null && user.adsAllowed;

    return Scaffold(
      appBar: AppBar(title: Text(l.giftsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text(l.giftsIntro, style: t.bodyMedium),
          const SizedBox(height: 14),
          _NextGiftCard(best: best, next: next),
          SectionTitle(l.themes),
          for (final p in ThemePreset.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ThemeTile(
                preset: p,
                selected: p == current,
                unlocked: unlocked(p.unlockStreak, p.name),
                best: best,
                adReady: adReady,
                onUse: () => repo.setTheme(uid, p.name),
                onAd: () => _unlockWithAd(p.name, tx('{label} teması açıldı. Teşekkürler!', {'label': p.label})),
              ),
            ),
          SectionTitle(l.avatars),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (var i = 0; i < kAvatars.length; i++)
                _AvatarGift(
                  index: i,
                  unlocked: unlocked(kAvatars[i].unlockStreak, 'avatar_$i'),
                  selected: user.avatar == i,
                  best: best,
                  adReady: adReady,
                  onUse: () {
                    repo.updateIdentity(uid, nickname: user.nickname ?? kAvatars[i].name, avatar: i);
                    final profile = ref.read(myProfileProvider).value;
                    if (profile != null) {
                      ref
                          .read(communityRepositoryProvider)
                          .ensureProfile(uid, nickname: profile.nickname, avatar: i, daily: user.daily)
                          .catchError((Object _) {});
                    }
                  },
                  onAd: () =>
                      _unlockWithAd('avatar_$i', tx('{p} avatarı açıldı. Teşekkürler!', {'p': kAvatars[i].name})),
                ),
            ],
          ),
          if (user.adsAllowed) ...[
            SectionTitle(tx('Günün ek sözü')),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: user.quoteUnlockedDay == todayKey()
                    ? Text(
                        '“${noteOfTheDay(txList(kGeneralAffirmations), DateTime.now(), offset: 7)}”',
                        style: t.titleMedium?.copyWith(fontStyle: FontStyle.italic),
                      )
                    : Row(
                        children: [
                          Expanded(child: Text(tx('Günün sözüne ek olarak bugüne özel bir cümle.'))),
                          FilledButton.tonal(
                            onPressed: adReady ? () => _unlockWithAd('extra_note', tx('Günün ek sözü açıldı.')) : null,
                            child: Text(adReady ? tx('Reklamla aç') : tx('Hazırlanıyor…')),
                          ),
                        ],
                      ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _AdSafetyCard(user: user, onAllow: (v) => repo.setAdsOptIn(uid, v)),
        ],
      ),
    );
  }
}

class _NextGiftCard extends StatelessWidget {
  const _NextGiftCard({required this.best, required this.next});
  final int best;
  final (int, String)? next;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = HavenPalette.of(context);
    final n = next;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [p.deep, p.primary]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                tx('En iyi serin: {best} gün', {'best': best}),
                style: t.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (n == null)
            Text(
              tx('Bütün hediyeleri açtın! Kendine gösterdiğin özen gerçekten değerli.'),
              style: t.bodyMedium?.copyWith(color: Colors.white),
            )
          else ...[
            Text(tx('Sıradaki hediye: {p}', {'p': n.$2}), style: t.bodyMedium?.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: LinearProgressIndicator(
                value: (best / n.$1).clamp(0, 1).toDouble(),
                minHeight: 10,
                color: p.accent,
                backgroundColor: Colors.white24,
              ),
            ),
            const SizedBox(height: 6),
            Text(context.l10n.giftDaysLeft(n.$1 - best), style: t.labelMedium?.copyWith(color: Colors.white70)),
          ],
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.preset,
    required this.selected,
    required this.unlocked,
    required this.best,
    required this.adReady,
    required this.onUse,
    required this.onAd,
  });

  final ThemePreset preset;
  final bool selected;
  final bool unlocked;
  final int best;
  final bool adReady;
  final VoidCallback onUse;
  final VoidCallback onAd;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            // tema önizleme: zemin + ana renk + vurgu
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: preset.surface,
                shape: BoxShape.circle,
                border: Border.all(color: preset.primary, width: 3),
              ),
              child: Center(
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(color: preset.accent, shape: BoxShape.circle),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(preset.label, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    unlocked
                        ? (preset.isGift ? tx('Açıldı 🎉') : tx('Herkese açık'))
                        : '${l.giftUnlockAt(preset.unlockStreak)} · ${l.giftDaysLeft(preset.unlockStreak - best)}',
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded)
            else if (unlocked)
              FilledButton.tonal(onPressed: onUse, child: Text(tx('Kullan')))
            else if (adReady)
              OutlinedButton(onPressed: onAd, child: Text(tx('Reklamla aç')))
            else
              const Icon(Icons.lock_outline_rounded),
          ],
        ),
      ),
    );
  }
}

class _AvatarGift extends StatelessWidget {
  const _AvatarGift({
    required this.index,
    required this.unlocked,
    required this.selected,
    required this.best,
    required this.adReady,
    required this.onUse,
    required this.onAd,
  });

  final int index;
  final bool unlocked;
  final bool selected;
  final int best;
  final bool adReady;
  final VoidCallback onUse;
  final VoidCallback onAd;

  @override
  Widget build(BuildContext context) {
    final a = kAvatars[index];
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 74,
      child: Column(
        children: [
          GestureDetector(
            onTap: unlocked ? onUse : (adReady ? onAd : null),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? scheme.primary : Colors.transparent, width: 2.5),
              ),
              child: AvatarBadge(index: index, radius: 28, locked: !unlocked),
            ),
          ),
          const SizedBox(height: 4),
          Text(a.name, style: t.labelSmall, textAlign: TextAlign.center),
          if (!unlocked)
            Text(
              tx('{unlockStreak} gün', {'unlockStreak': a.unlockStreak}),
              style: t.labelSmall?.copyWith(color: scheme.outline),
            ),
        ],
      ),
    );
  }
}

class _AdSafetyCard extends StatelessWidget {
  const _AdSafetyCard({required this.user, required this.onAllow});
  final AppUser user;
  final ValueChanged<bool> onAllow;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final sensitive = user.categoryIds.any(AppUser.sensitiveForAds.contains);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_outlined),
                const SizedBox(width: 8),
                Text(tx('Reklam güvenliği'), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              sensitive
                  ? tx(
                      'Seçtiğin alanlar nedeniyle, tetikleyici olabilecek reklamlardan (ör. zayıflama, bahis, alkol) korunman için reklamları varsayılan olarak kapalı tuttuk. Hediyelerin hepsi serinle açılabilir.',
                    )
                  : tx(
                      'Reklamlar yalnızca bu ekranda, sen istediğinde gösterilir; kişiselleştirilmemiş ve genel izleyiciye uygun içerikle sınırlıdır.',
                    ),
              style: t.bodySmall,
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.only(right: 8),
              value: user.adsAllowed,
              onChanged: onAllow,
              title: Text(tx('Filtreli reklamlara izin ver')),
            ),
          ],
        ),
      ),
    );
  }
}
