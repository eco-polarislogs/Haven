import 'dart:math';

import 'day_key.dart';

/// `kind`  = "Bugün iyi geçti" (dürtüye yenik düşmedim / kendime zarar vermedim)
/// `hard`  = "Bugün zordu"     (cezalandırmıyoruz, sadece kaydediyoruz)
enum CheckInResult { kind, hard }

/// Şefkat payı: Bir günü kaçırmak seriyi BOZMAZ.
const int kGraceDays = 1;

/// Günlük serinin kutlanan kilometre taşları (bildirim + arkadaşlara haber).
const kStreakMilestones = {3, 7, 14, 30, 60, 100, 180, 365};

// ------------------------------------------------------------ alan serisi

/// Biten bir seri — SİLİNMEZ. "I Am Sober" mantığı: geçmiş başarı hatırlatılır
/// ve kullanıcı kendi rekoruyla yarışır.
class PastStreak {
  const PastStreak(this.days, this.endDay);
  final int days;
  final String? endDay;

  Map<String, Object?> toMap() => {'days': days, 'end': endDay};

  static PastStreak? fromMap(Object? m) {
    if (m is! Map) return null;
    final days = (m['days'] as num?)?.toInt();
    return days == null ? null : PastStreak(days, m['end'] as String?);
  }
}

class StreakState {
  const StreakState({
    this.current = 0,
    this.longest = 0,
    this.totalKindDays = 0,
    this.lastKindDay,
    this.lastCheckInDay,
    this.history = const [],
  });

  final int current;
  final int longest;

  /// Toplam nazik gün — ASLA azalmaz. Zor bir gün emeği silmez.
  final int totalKindDays;
  final String? lastKindDay;
  final String? lastCheckInDay;

  /// Biten seriler (en yeni sonda, en fazla 20).
  final List<PastStreak> history;

  PastStreak? get lastPast => history.isEmpty ? null : history.last;
}

const _maxHistory = 20;

List<PastStreak> _withPast(List<PastStreak> h, PastStreak p) {
  final list = [...h, p];
  return list.length > _maxHistory ? list.sublist(list.length - _maxHistory) : list;
}

/// Saf fonksiyon: test edilebilir ve OFFLINE çalışır (transaction yok).
/// `null` dönerse bu alan için bugün zaten kayıt yapılmıştır.
StreakState? applyCheckIn(StreakState s, String today, CheckInResult result) {
  if (s.lastCheckInDay == today) return null;

  if (result == CheckInResult.hard) {
    return StreakState(
      current: 0,
      longest: s.longest,
      totalKindDays: s.totalKindDays,
      lastKindDay: s.lastKindDay,
      lastCheckInDay: today,
      // Biten seri geçmişe yazılır; silinmez.
      history: s.current > 0 ? _withPast(s.history, PastStreak(s.current, today)) : s.history,
    );
  }

  final continues = s.current > 0 &&
      s.lastKindDay != null &&
      daysBetween(s.lastKindDay!, today) <= 1 + kGraceDays;
  final current = continues ? s.current + 1 : 1;
  // Uzun bir aradan sonra dönüldüyse, önceki seri de geçmişe yazılır.
  final history = (!continues && s.current > 0)
      ? _withPast(s.history, PastStreak(s.current, s.lastKindDay))
      : s.history;

  return StreakState(
    current: current,
    longest: max(s.longest, current),
    totalKindDays: s.totalKindDays + 1,
    lastKindDay: today,
    lastCheckInDay: today,
    history: history,
  );
}

/// "Kendi rekorunla yarış" durumu: ekranda nazik karşılaştırma için.
class RecordRace {
  const RecordRace({required this.live, required this.best, this.lastPast});

  final int live;
  final int best;
  final PastStreak? lastPast;

  /// Seri dinlenmede ama daha önce güzel bir seri vardı → "tümsek" kartı.
  bool get isComeback => live == 0 && best > 0;
  bool get isNewRecord => live > 0 && live >= best && best >= 3;
  int get toRecord => max(0, best - live);

  /// Rekora doğru ilerleme (0..1).
  double get progress => best == 0 ? (live > 0 ? 1 : 0) : (live / best).clamp(0, 1).toDouble();
}

RecordRace recordRaceOf(StreakState s, String today) =>
    RecordRace(live: liveStreak(s, today), best: s.longest, lastPast: s.lastPast);

int liveStreak(StreakState s, String today) {
  final last = s.lastKindDay;
  if (s.current == 0 || last == null) return 0;
  return daysBetween(last, today) <= 1 + kGraceDays ? s.current : 0;
}

// ------------------------------------------------------------ günlük seri

/// Duolingo mantığında "uygulama serisi": herhangi bir alanda kayıt yapılan
/// ardışık günler. "Zordu" kaydı da sayılır: amaç mükemmellik değil,
/// her gün kendine dönmek. Bir günü kaçırmak seriyi bozmaz (kGraceDays).
class DailyStreak {
  const DailyStreak({this.current = 0, this.longest = 0, this.lastDay});

  final int current;
  final int longest;
  final String? lastDay;

  int live(String today) {
    final last = lastDay;
    if (current == 0 || last == null) return 0;
    return daysBetween(last, today) <= 1 + kGraceDays ? current : 0;
  }
}

/// `null` → bugün zaten sayıldı.
DailyStreak? applyDailyActivity(DailyStreak s, String today) {
  if (s.lastDay == today) return null;
  final continues = s.current > 0 &&
      s.lastDay != null &&
      daysBetween(s.lastDay!, today) <= 1 + kGraceDays;
  final current = continues ? s.current + 1 : 1;
  return DailyStreak(current: current, longest: max(s.longest, current), lastDay: today);
}
