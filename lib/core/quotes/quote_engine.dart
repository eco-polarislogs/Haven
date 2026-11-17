import '../constants/app_constants.dart';
import '../constants/struggle_catalog.dart';
import '../../l10n/tx.dart';

import 'package:flutter/foundation.dart';

/// Günün sözü: saate, güne, mevsime, özel günlere ve seri durumuna göre değişir.
/// Aynı saat diliminde aynı söz kalır (sayfa her açıldığında değişip
/// huzursuzluk yaratmasın); dilim değişince yenilenir.
class DailyQuote {
  const DailyQuote(this.text, this.context);

  final String text;

  /// Sözün neden seçildiği: "Günaydın · Kış" gibi küçük bir etiket.
  final String context;
}

class QuoteEngine {
  QuoteEngine._();

  static const _morning = [
    'Günaydın. Bugün kendine nazik davranmak için yepyeni bir sayfa.',
    'Güne yavaş başlamak da bir başlangıçtır.',
    'Bu sabah sadece bir şeye odaklan: kendine iyi davranmaya.',
    'Yeni gün, dünün yükünü taşımak zorunda değil.',
  ];
  static const _afternoon = [
    'Günün ortasında kısa bir mola ver; omuzlarını gevşet.',
    'Buraya kadar gelmen bile değerli. Bir nefes al.',
    'Öğleden sonraları zor olabilir; kendine biraz alan aç.',
    'Küçük bir yürüyüş, küçük bir su, küçük bir mola. Hepsi sayılır.',
  ];
  static const _evening = [
    'Akşam oldu. Bugün ne olursa olsun, burada olman yeterli.',
    'Günün yükünü yavaşça bırakmanın zamanı.',
    'Bugün kendin için yaptığın küçük bir şeyi hatırla.',
    'Akşamın sessizliği, kendini dinlemen için bir davet.',
  ];
  static const _night = [
    'Gece sessiz; zihnin de dinlenmeyi hak ediyor.',
    'Uyuyamıyorsan sorun değil. Yavaşça nefes al, liman burada.',
    'Bu gece kendine yumuşak davran. Yarın yeni bir gün.',
    'Karanlıkta bile bir fener yolu gösterir.',
  ];
  static const _winter = [
    'En uzun geceden sonra bile günler uzamaya başlar.',
    'Kış, içimizdeki sıcaklığı korumayı öğretir.',
  ];
  static const _spring = [
    'Her bahar, yeniden başlamanın mümkün olduğunu hatırlatır.',
    'Güneş her gün biraz daha erken doğuyor; sen de kendi hızında açılıyorsun.',
  ];
  static const _summer = [
    'Uzun günler, kendine ayıracak daha çok an demek.',
    'Sıcak günlerde kendine serin bir mola ver.',
  ];
  static const _autumn = [
    'Sonbahar, bırakmanın da bir güzellik olduğunu öğretir.',
    'Değişim yavaş olur; mevsimler bile acele etmez.',
  ];

  /// Testler: çevrilmesi gereken tüm söz havuzları (Türkçe kaynak).
  @visibleForTesting
  static List<String> get allPoolTexts => [
    ..._morning,
    ..._afternoon,
    ..._evening,
    ..._night,
    ..._winter,
    ..._spring,
    ..._summer,
    ..._autumn,
  ];

  static DailyQuote pick({
    required DateTime now,
    required int liveStreak,
    required int bestStreak,
    Iterable<StruggleCategory> categories = const [],
  }) {
    final h = now.hour;
    final (timePool, timeLabel) = switch (h) {
      >= 5 && < 12 => (_morning, tx('Günaydın')),
      >= 12 && < 18 => (_afternoon, tx('Gün ortası')),
      >= 18 && < 23 => (_evening, tx('İyi akşamlar')),
      _ => (_night, tx('Gece')),
    };
    final (seasonPool, seasonLabel) = switch (now.month) {
      12 || 1 || 2 => (_winter, tx('Kış')),
      3 || 4 || 5 => (_spring, tx('İlkbahar')),
      6 || 7 || 8 => (_summer, tx('Yaz')),
      _ => (_autumn, tx('Sonbahar')),
    };

    // Seri durumu her şeyden önce gelir: kişiye özel ve en motive edici.
    if (bestStreak > 0 && liveStreak == 0) {
      return DailyQuote(
        tx(
          'Daha önce {best} gün boyunca harika ilerledin. O güç hâlâ sende; bugün yeniden başlamak için güzel bir gün.',
          {'best': bestStreak},
        ),
        '$timeLabel · ${tx('Yeniden başlangıç')}',
      );
    }
    if (liveStreak > 0 && liveStreak >= bestStreak && bestStreak >= 3) {
      return DailyQuote(
        tx('Yeni bir rekor yazıyorsun: {n} gün! Kendinle gurur duyabilirsin.', {'n': liveStreak}),
        '$timeLabel · ${tx('Yeni rekor')}',
      );
    }
    if (liveStreak > 0 && bestStreak - liveStreak > 0 && bestStreak - liveStreak <= 2) {
      return DailyQuote(
        tx('Rekoruna {n} gün kaldı. Acele yok; kendi hızında, adım adım.', {'n': bestStreak - liveStreak}),
        '$timeLabel · ${tx('Rekora yakın')}',
      );
    }

    // Özel günler
    if (now.month == 1 && now.day == 1) {
      return DailyQuote(
        tx('Yeni yıl, yeni sayfalar. Geçen yılın her zor gününü de taşıyarak buraya geldin.'),
        tx('Yeni yıl'),
      );
    }
    if (now.weekday == DateTime.monday && h < 12) {
      return DailyQuote(
        tx('Haftanın ilk günü. Büyük hedefler yerine tek bir küçük adım yeter.'),
        tx('Pazartesi sabahı'),
      );
    }

    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final slot = dayOfYear * 4 + (h ~/ 6); // günde 4 dilim
    final pools = <List<String>>[
      timePool,
      seasonPool,
      [for (final c in categories) ...c.affirmationsTr],
      kGeneralAffirmations,
    ].where((p) => p.isNotEmpty).toList();
    final pool = pools[slot % pools.length];
    final label = identical(pool, seasonPool) ? '$timeLabel · $seasonLabel' : timeLabel;
    return DailyQuote(tx(pool[(slot ~/ pools.length) % pool.length]), label);
  }
}
