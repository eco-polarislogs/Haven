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

  // TODO(Gün 8): AdMob → Reklam birimleri → Banner (320x50)
  static const _androidBannerReal = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const _iosBannerReal = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const _androidBannerTest = 'ca-app-pub-3940256099942544/6300978111';
  static const _iosBannerTest = 'ca-app-pub-3940256099942544/2934735716';

  // TODO(Gün 8): AdMob → Reklam birimleri → Banner (ana sayfa kartı, 320x100)
  static const _androidHomeReal = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const _iosHomeReal = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  /// Ana sayfadaki reklam kartı (test kimliği banner ile aynı).
  static String get homeBanner => _pick(_iosHomeReal, _androidHomeReal, _iosBannerTest, _androidBannerTest);

  static String get rewarded => _pick(_iosRewardedReal, _androidRewardedReal, _iosRewardedTest, _androidRewardedTest);

  /// Alt çubuğun hemen üstündeki ince banner (320x50).
  static String get banner => _pick(_iosBannerReal, _androidBannerReal, _iosBannerTest, _androidBannerTest);

  static String _pick(String iosReal, String androidReal, String iosTest, String androidTest) {
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final real = isIos ? iosReal : androidReal;
    if (kReleaseMode && !real.contains('XXXX')) return real;
    return isIos ? iosTest : androidTest;
  }
}
