/// Tarihleri cihazın YEREL saatine göre string anahtara çevirir.
///
/// Neden Timestamp yerine string? Firestore Timestamp'leri UTC'dir.
/// Türkiye'de gece 01:30'da yapılan bir check-in UTC'de bir önceki güne
/// düşer ve seri hesabı bozulur. `2026-11-17` gibi bir anahtar ise doğrudan
/// "kullanıcının yaşadığı gün"dür; sıralanabilir ve sorgulanabilir.
library;

String _two(int v) => v.toString().padLeft(2, '0');

/// `2026-11-17`
String dayKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// `2026-11` — takvim dokümanının ID'si (bir ay = bir doküman).
String monthKey(DateTime d) => '${d.year}-${_two(d.month)}';

/// `07` — ay dokümanı içindeki gün alanının adı.
String dayOfMonthKey(DateTime d) => _two(d.day);

String todayKey() => dayKey(DateTime.now());

DateTime parseDayKey(String key) {
  final p = key.split('-');
  // UTC kullanıyoruz ki yaz saati geçişleri gün farkını bozmasın.
  return DateTime.utc(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// `from` ile `to` arasındaki takvim günü farkı (dün → bugün = 1).
int daysBetween(String from, String to) =>
    parseDayKey(to).difference(parseDayKey(from)).inDays;
