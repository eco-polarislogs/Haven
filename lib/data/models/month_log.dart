import '../../core/utils/streak.dart';

enum DayStatus { none, kind, hard }

/// `users/{uid}/checkins/{yyyy-MM}` dokümanı.
///
/// Bir ayın tüm check-in'leri TEK dokümanda: takvim ekranı = 1 okuma.
/// ```
/// days: { "07": { "trichotillomania": "kind", "anorexia": "hard" } }
/// ```
class MonthLog {
  const MonthLog(this.days);

  /// gün (1-31) → { typeId → sonuç }
  final Map<int, Map<String, CheckInResult>> days;

  static const empty = MonthLog({});

  factory MonthLog.fromMap(Map<String, dynamic>? data) {
    final raw = (data?['days'] as Map<String, dynamic>?) ?? const {};
    final results = CheckInResult.values.asNameMap();
    final out = <int, Map<String, CheckInResult>>{};
    raw.forEach((key, value) {
      final day = int.tryParse(key);
      if (day == null || value is! Map) return;
      out[day] = {
        // Bilinmeyen sonuç değerleri (null) sessizce atlanır.
        for (final e in value.entries) e.key as String: ?results[e.value],
      };
    });
    return MonthLog(out);
  }

  /// O gün herhangi bir alanda "zordu" denildiyse `hard`, sadece iyi
  /// günler varsa `kind`, kayıt yoksa `none`.
  DayStatus statusOf(int day) {
    final entries = days[day];
    if (entries == null || entries.isEmpty) return DayStatus.none;
    return entries.values.contains(CheckInResult.hard) ? DayStatus.hard : DayStatus.kind;
  }
}
