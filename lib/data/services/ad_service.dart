import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Reklam SDK'sı ancak kullanıcı "Küçük hediyeler" ekranını KENDİSİ açtığında
/// başlatılır. Uygulamanın geri kalanında (özellikle kriz/sakinleşme
/// ekranlarında) reklamla ilgili hiçbir şey yüklenmez.
///
/// Sıra önemli: önce rıza (UMP — AB/İngiltere için yasal zorunluluk;
/// Türkiye'de form genelde hiç gösterilmez), sonra SDK başlatma.
class AdService {
  AdService._();

  static Future<bool>? _ready;

  static Future<bool> ensureReady() => _ready ??= _init();

  static Future<bool> _init() async {
    try {
      final consentDone = Completer<void>();
      void done([Object? _]) {
        if (!consentDone.isCompleted) consentDone.complete();
      }

      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => ConsentForm.loadAndShowConsentFormIfRequired(done),
        done,
      );
      await consentDone.future;

      if (!await ConsentInformation.instance.canRequestAds()) return false;
      // İçerik güvenliği: yalnızca genel izleyiciye (G) uygun reklamlar.
      // Zayıflama, bahis, alkol gibi kategoriler ayrıca AdMob → Engelleme
      // kontrolleri → Hassas kategoriler bölümünden engellenmelidir (README).
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.g),
      );
      await MobileAds.instance.initialize();
      return true;
    } catch (e) {
      debugPrint('Reklam SDK başlatılamadı: $e');
      _ready = null; // bir dahaki sefere tekrar denensin
      return false;
    }
  }
}
