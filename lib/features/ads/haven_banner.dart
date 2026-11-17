import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/ad_ids.dart';
import '../../data/services/ad_service.dart';
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
  const HavenBanner({super.key, required this.visible});

  final bool visible;

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
    // Standart ince banner (320×50): ekranı kalabalıklaştırmaz.
    final ad = BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
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
