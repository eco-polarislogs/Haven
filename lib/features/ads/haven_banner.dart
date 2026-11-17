import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/ad_ids.dart';
import '../../data/services/ad_service.dart';
import '../../l10n/tx.dart';
import '../../providers.dart';

/// Alt gezinme çubuğunun hemen üstünde ince bir banner (320x50).
///
/// Kullanıcı deneyimi ve güvenlik kuralları:
/// - Yalnızca reklam izni olan kullanıcıda yüklenir (`AppUser.adsAllowed`):
///   yeme, kendine zarar, madde ve davranışsal bağımlılık alanlarında
///   varsayılan KAPALI; kullanıcı Profil'den açabilir.
/// - "Sakinleş" sekmesinde (acil arama, nefes) gizlenir: [visible] false.
///   Reklam bellekte kalır, sekmeye dönünce yeniden yüklenmez.
/// - Kişiselleştirilmemiş istek + G içerik sınırı (AdService).
class HavenBanner extends ConsumerStatefulWidget {
  const HavenBanner({super.key, required this.visible, this.inline = false});

  final bool visible;

  /// Ana sayfa içi kart: biraz daha büyük (320×100) ve üstünde "Reklam" etiketi.
  final bool inline;

  @override
  ConsumerState<HavenBanner> createState() => _HavenBannerState();
}

class _HavenBannerState extends ConsumerState<HavenBanner> {
  BannerAd? _ad;
  bool _loading = false;
  bool _loaded = false;

  /// Yükleme başarısız olursa (reklam yok, internet yok) bir süre beklenir;
  /// her karede yeniden denenmez.
  DateTime? _retryAfter;

  void _backOff() {
    _retryAfter = DateTime.now().add(const Duration(seconds: 90));
    _loading = false;
    Future.delayed(const Duration(seconds: 91), () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _load() async {
    if (_loading || _ad != null) return;
    if (_retryAfter != null && DateTime.now().isBefore(_retryAfter!)) return;
    _loading = true;
    if (!await AdService.ensureReady() || !mounted) {
      _backOff();
      return;
    }
    // Alt çubuk: ince 320×50. Ana sayfa kartı: 320×100.
    final ad = BannerAd(
      adUnitId: widget.inline ? AdIds.homeBanner : AdIds.banner,
      size: widget.inline ? AdSize.largeBanner : AdSize.banner,
      request: const AdRequest(nonPersonalizedAds: true),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, e) {
          debugPrint('Banner yüklenemedi: ${e.code}');
          ad.dispose();
          _backOff();
          if (mounted) setState(() => _ad = null);
        },
      ),
    );
    setState(() => _ad = ad);
    await ad.load();
  }

  /// AdWidget ağaçtan çıktıktan SONRA reklamı serbest bırak.
  void _drop() {
    final old = _ad;
    _ad = null;
    _loaded = false;
    _loading = false;
    if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allowed = ref.watch(appUserProvider).value?.adsAllowed ?? false;
    if (!allowed) {
      // Kullanıcı reklamları kapattıysa banner hemen kalkar.
      if (_ad != null) _drop();
      return const SizedBox.shrink();
    }
    final ad = _ad;
    if (ad == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
      return const SizedBox.shrink();
    }
    if (widget.inline) {
      if (!_loaded) return const SizedBox.shrink();
      final t = Theme.of(context).textTheme;
      return Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tx('Reklam'), style: t.labelSmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
              const SizedBox(height: 6),
              Center(
                child: SizedBox(
                  width: ad.size.width.toDouble(),
                  height: ad.size.height.toDouble(),
                  child: AdWidget(ad: ad),
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Offstage: platform görünümü ağaçta kalır, gizliyken yer kaplamaz.
    return Offstage(
      offstage: !widget.visible || !_loaded,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        alignment: Alignment.center,
        width: double.infinity,
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
