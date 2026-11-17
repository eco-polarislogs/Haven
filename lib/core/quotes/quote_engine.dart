import '../constants/app_constants.dart';
import '../constants/struggle_catalog.dart';

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

  static DailyQuote pick({
    required DateTime now,
    required int liveStreak,
    required int bestStreak,
    Iterable<StruggleCategory> categories = const [],
  }) {
    final h = now.hour;
    final (timePool, timeLabel) = switch (h) {
      >= 5 && < 12 => (_morning, 'Günaydın'),
      >= 12 && < 18 => (_afternoon, 'Gün ortası'),
      >= 18 && < 23 => (_evening, 'İyi akşamlar'),
      _ => (_night, 'Gece'),
    };
    final (seasonPool, seasonLabel) = switch (now.month) {
      12 || 1 || 2 => (_winter, 'Kış'),
      3 || 4 || 5 => (_spring, 'İlkbahar'),
      6 || 7 || 8 => (_summer, 'Yaz'),
      _ => (_autumn, 'Sonbahar'),
    };

    // Seri durumu her şeyden önce gelir: kişiye özel ve en motive edici.
    if (bestStreak > 0 && liveStreak == 0) {
      return DailyQuote('Daha önce $bestStreak gün boyunca harika ilerledin. O güç hâlâ sende; '
          'bugün yeniden başlamak için güzel bir gün.', '$timeLabel · Yeniden başlangıç');
    }
    if (liveStreak > 0 && liveStreak >= bestStreak && bestStreak >= 3) {
      return DailyQuote('Yeni bir rekor yazıyorsun: $liveStreak gün! Kendinle gurur duyabilirsin.',
          '$timeLabel · Yeni rekor');
    }
    if (liveStreak > 0 && bestStreak - liveStreak > 0 && bestStreak - liveStreak <= 2) {
      return DailyQuote('Rekoruna ${bestStreak - liveStreak} gün kaldı. Acele yok; '
          'kendi hızında, adım adım.', '$timeLabel · Rekora yakın');
    }

    // Özel günler
    if (now.month == 1 && now.day == 1) {
      return DailyQuote('Yeni yıl, yeni sayfalar. Geçen yılın her zor gününü de taşıyarak buraya geldin.',
          'Yeni yıl');
    }
    if (now.weekday == DateTime.monday && h < 12) {
      return const DailyQuote('Haftanın ilk günü. Büyük hedefler yerine tek bir küçük adım yeter.',
          'Pazartesi sabahı');
    }

    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final slot = dayOfYear * 4 + (h ~/ 6); // günde 4 dilim
    final pools = <List<String>>[
      timePool,
      seasonPool,
      [for (final c in categories) ...c.affirmations],
      kGeneralAffirmations,
    ].where((p) => p.isNotEmpty).toList();
    final pool = pools[slot % pools.length];
    final label = identical(pool, seasonPool) ? '$timeLabel · $seasonLabel' : timeLabel;
    return DailyQuote(pool[(slot ~/ pools.length) % pool.length], label);
  }
}
