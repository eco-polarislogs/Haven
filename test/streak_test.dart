import 'package:flutter_test/flutter_test.dart';
import 'package:haven/core/utils/day_key.dart';
import 'package:haven/core/utils/streak.dart';
import 'package:haven/data/models/month_log.dart';

void main() {
  group('alan serisi', () {
    const empty = StreakState();

    test('ilk nazik gün seriyi 1 yapar', () {
      final s = applyCheckIn(empty, '2026-11-17', CheckInResult.kind)!;
      expect([s.current, s.totalKindDays, s.longest], [1, 1, 1]);
    });

    test('bir gün uygulamaya girmemek seriyi BOZMAZ (şefkat payı)', () {
      var s = applyCheckIn(empty, '2026-11-15', CheckInResult.kind)!;
      s = applyCheckIn(s, '2026-11-17', CheckInResult.kind)!;
      expect(s.current, 2);
    });

    test('uzun aradan sonra seri 1\'den başlar, toplam ve en uzun korunur', () {
      var s = applyCheckIn(empty, '2026-11-01', CheckInResult.kind)!;
      s = applyCheckIn(s, '2026-11-02', CheckInResult.kind)!;
      s = applyCheckIn(s, '2026-11-10', CheckInResult.kind)!;
      expect([s.current, s.totalKindDays, s.longest], [1, 3, 2]);
    });

    test('"zordu" seriyi dinlendirir, toplam nazik günleri ASLA silmez', () {
      var s = applyCheckIn(empty, '2026-11-16', CheckInResult.kind)!;
      s = applyCheckIn(s, '2026-11-17', CheckInResult.hard)!;
      expect([s.current, s.totalKindDays, s.longest], [0, 1, 1]);
    });

    test('aynı gün ikinci kayıt yok sayılır', () {
      final s = applyCheckIn(empty, '2026-11-17', CheckInResult.kind)!;
      expect(applyCheckIn(s, '2026-11-17', CheckInResult.kind), isNull);
    });

    test('ekrandaki seri şefkat payı aşılınca 0 görünür', () {
      final s = applyCheckIn(empty, '2026-11-10', CheckInResult.kind)!;
      expect(liveStreak(s, '2026-11-12'), 1);
      expect(liveStreak(s, '2026-11-13'), 0);
    });
  });

  group('günlük seri (Duolingo mantığı)', () {
    test('ardışık günler artırır, aynı gün sayılmaz', () {
      var d = applyDailyActivity(const DailyStreak(), '2026-11-16')!;
      d = applyDailyActivity(d, '2026-11-17')!;
      expect(d.current, 2);
      expect(applyDailyActivity(d, '2026-11-17'), isNull);
    });

    test('bir gün kaçırmak bozmaz, iki gün kaçırmak yeniden başlatır', () {
      var d = applyDailyActivity(const DailyStreak(), '2026-11-10')!;
      d = applyDailyActivity(d, '2026-11-12')!; // 11'i kaçırdı
      expect(d.current, 2);
      d = applyDailyActivity(d, '2026-11-15')!; // 13 ve 14'ü kaçırdı
      expect([d.current, d.longest], [1, 2]);
    });

    test('canlı seri şefkat payından sonra 0 görünür', () {
      final d = applyDailyActivity(const DailyStreak(), '2026-11-10')!;
      expect(d.live('2026-11-11'), 1);
      expect(d.live('2026-11-12'), 1);
      expect(d.live('2026-11-13'), 0);
    });
  });

  test('ay ve yıl geçişleri doğru sayılır', () {
    expect(daysBetween('2026-10-31', '2026-11-01'), 1);
    expect(daysBetween('2026-12-31', '2027-01-01'), 1);
    expect(daysBetween('2028-02-28', '2028-03-01'), 2); // artık yıl
  });

  group('üç sonuç: başardım / zorlandım / başaramadım', () {
    test('"zorlandım ama dayandım" seriyi sürdürür ve iyi gün sayılır', () {
      var s = const StreakState();
      s = applyCheckIn(s, '2026-11-01', CheckInResult.kind)!;
      s = applyCheckIn(s, '2026-11-02', CheckInResult.struggled)!;
      s = applyCheckIn(s, '2026-11-03', CheckInResult.kind)!;
      expect(s.current, 3);
      expect(s.totalKindDays, 3);
      expect(s.history, isEmpty);
    });

    test('"başaramadım" seriyi dinlendirir, biten seri geçmişe yazılır', () {
      var s = const StreakState();
      s = applyCheckIn(s, '2026-11-01', CheckInResult.struggled)!;
      s = applyCheckIn(s, '2026-11-02', CheckInResult.struggled)!;
      s = applyCheckIn(s, '2026-11-03', CheckInResult.hard)!;
      expect(s.current, 0);
      expect(s.longest, 2);
      expect(s.history.single.days, 2);
    });

    test('ay takvimi: başaramadım > zorlandım > başardım önceliği', () {
      final log = MonthLog({
        1: {'a': CheckInResult.kind},
        2: {'a': CheckInResult.kind, 'b': CheckInResult.struggled},
        3: {'a': CheckInResult.struggled, 'b': CheckInResult.hard},
      });
      expect(log.statusOf(1), DayStatus.kind);
      expect(log.statusOf(2), DayStatus.struggled);
      expect(log.statusOf(3), DayStatus.hard);
      expect(log.statusOf(4), DayStatus.none);
      expect(CheckInResult.struggled.keepsStreak, isTrue);
      expect(CheckInResult.hard.keepsStreak, isFalse);
    });
  });
}
