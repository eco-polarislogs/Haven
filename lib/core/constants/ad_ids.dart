import 'package:flutter/foundation.dart';

/// AdMob reklam birimi kimlikleri.
///
/// UYARI: Geliştirme sırasında SADECE Google'ın test kimliklerini kullan.
/// Kendi gerçek reklamına tıklamak/izlemek AdMob hesabının kapatılmasına
/// yol açabilir. Gerçek kimlikler yalnızca release derlemede ve
/// placeholder değiştirildiyse devreye girer.
class AdIds {
  AdIds._();

  // TODO(Gün 8): AdMob → Uygulamalar → Reklam birimleri → Ödüllü
  static const _androidRewardedReal = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const _iosRewardedReal = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  // Google'ın resmi test kimlikleri.
  static const _androidRewardedTest = 'ca-app-pub-3940256099942544/5224354917';
  static const _iosRewardedTest = 'ca-app-pub-3940256099942544/1712485313';

  static String get rewarded {
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final real = isIos ? _iosRewardedReal : _androidRewardedReal;
    if (kReleaseMode && !real.contains('XXXX')) return real;
    return isIos ? _iosRewardedTest : _androidRewardedTest;
  }
}
