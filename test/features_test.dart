import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haven/l10n/tx.dart';
import 'package:haven/core/constants/app_constants.dart';
import 'package:haven/core/constants/struggle_catalog.dart';
import 'package:haven/core/moderation/content_moderator.dart';
import 'package:haven/core/quotes/quote_engine.dart';
import 'package:haven/core/theme/theme_presets.dart';
import 'package:haven/core/utils/streak.dart';
import 'package:haven/data/models/community.dart';
import 'package:haven/data/services/local_notifier.dart';

void main() {
  group('I Am Sober mantığı: biten seriler silinmez', () {
    const empty = StreakState();

    test('zor gün seriyi geçmişe yazar, rekor korunur', () {
      var s = empty;
      for (var d = 1; d <= 7; d++) {
        s = applyCheckIn(s, '2026-11-0$d', CheckInResult.kind)!;
      }
      s = applyCheckIn(s, '2026-11-08', CheckInResult.hard)!;
      expect(s.current, 0);
      expect(s.longest, 7);
      expect(s.history.single.days, 7);
      expect(s.totalKindDays, 7);
    });

    test('uzun aradan sonra dönünce önceki seri de geçmişe yazılır', () {
      var s = applyCheckIn(empty, '2026-11-01', CheckInResult.kind)!;
      s = applyCheckIn(s, '2026-11-02', CheckInResult.kind)!;
      s = applyCheckIn(s, '2026-11-10', CheckInResult.kind)!;
      expect(s.history.single.days, 2);
      expect(s.current, 1);
    });

    test('geçmiş en fazla 20 seri tutar', () {
      var s = empty;
      for (var i = 0; i < 25; i++) {
        final day = DateTime(2026, 1, 1).add(Duration(days: i * 2));
        String key(DateTime d) =>
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        s = applyCheckIn(s, key(day), CheckInResult.kind)!;
        s = applyCheckIn(s, key(day.add(const Duration(days: 1))), CheckInResult.hard)!;
      }
      expect(s.history.length, 20);
    });

    test('rekor yarışı: tümsek, ilerleme, yeni rekor', () {
      var s = empty;
      for (var d = 1; d <= 7; d++) {
        s = applyCheckIn(s, '2026-11-0$d', CheckInResult.kind)!;
      }
      s = applyCheckIn(s, '2026-11-08', CheckInResult.hard)!;
      var race = recordRaceOf(s, '2026-11-08');
      expect(race.isComeback, isTrue);
      expect(race.lastPast!.days, 7);

      s = applyCheckIn(s, '2026-11-09', CheckInResult.kind)!;
      race = recordRaceOf(s, '2026-11-09');
      expect(race.isComeback, isFalse);
      expect(race.toRecord, 6);
      expect(race.progress, closeTo(1 / 7, 0.001));
    });
  });

  group('günün sözü', () {
    test('saat, mevsim ve seri durumuna göre her söz denetimden geçer', () {
      final seen = <String>{};
      for (final month in [1, 4, 7, 10]) {
        for (var hour = 0; hour < 24; hour += 3) {
          for (final (live, best) in [(0, 0), (0, 7), (3, 7), (6, 7), (8, 7), (2, 2)]) {
            final q = QuoteEngine.pick(
              now: DateTime(2026, month, 15, hour),
              liveStreak: live,
              bestStreak: best,
              categories: StruggleCategory.values,
            );
            seen.add(q.text);
            final r = ContentModerator.check(q.text, maxLength: 400);
            expect(r.isOk, isTrue, reason: '${r.verdict} (${r.term}) → ${q.text}');
          }
        }
      }
      expect(seen.length, greaterThan(15), reason: 'sözler yeterince çeşitli değil');
    });

    test('tümsekten sonra eski başarı nazikçe hatırlatılır', () {
      final q = QuoteEngine.pick(now: DateTime(2026, 11, 17, 9), liveStreak: 0, bestStreak: 7);
      expect(q.text, contains('7 gün'));
    });
  });

  group('telefon bildirimleri', () {
    test('şefkatli mesajlar denetimden geçer ve sorunu ifşa etmez', () {
      for (final m in [...LocalNotifier.nudges, LocalNotifier.eveningReminder]) {
        expect(ContentModerator.check(m, maxLength: 400).isOk, isTrue, reason: m);
        for (final w in ['bozul', 'kaybet', 'başarısız', 'kilo', 'kaygı', 'zarar', 'depres']) {
          expect(m.toLowerCase().contains(w), isFalse, reason: '"$w" → $m');
        }
      }
    });

    test('gün içi bildirim: her gün 13:00, 7 gün, değişen ve sorunu adlandırmayan mesaj', () {
      final plan = LocalNotifier.dailyPlan(DateTime(2026, 11, 18, 9), checkedInToday: false);
      expect(plan.length, 7);
      expect(plan.every((p) => p.when.hour == 13 && p.when.minute == 0), isTrue);
      expect(plan.first.body, LocalNotifier.checkInInvite); // bugün kayıt yoksa davet
      expect(plan.map((p) => p.body).toSet().length, greaterThan(3)); // her gün farklı
      for (final p in plan) {
        expect(LocalNotifier.withinWindow(p.when), p.when, reason: "sessiz saat dışında");
        for (final c in StruggleCategory.values) {
          expect(p.body.toLowerCase(), isNot(contains(c.shortTitle.toLowerCase())), reason: p.body);
        }
      }
    });

    test('gün içi bildirim: 13:00 geçtiyse bugünkü atlanır, kayıt varsa davet yerine söz gelir', () {
      final late = LocalNotifier.dailyPlan(DateTime(2026, 11, 18, 15), checkedInToday: false);
      expect(late.length, 6);
      expect(late.first.when.day, 19);
      final done = LocalNotifier.dailyPlan(DateTime(2026, 11, 18, 9), checkedInToday: true);
      expect(done.first.body, isNot(LocalNotifier.checkInInvite));
    });

    test('gün içi bildirim kişiye göre: kendi alanlarının sözleri, kendi serisi, takma adı', () {
      final cats = [StruggleCategory.sleep];
      final plan = LocalNotifier.dailyPlan(
        DateTime(2026, 11, 18, 9),
        checkedInToday: false,
        categories: cats,
        streak: 5,
        nickname: 'Deniz',
      );
      expect(plan.first.body, LocalNotifier.checkInInviteStreak);
      expect(plan.first.title, LocalNotifier.greetingTitle);
      expect(plan.first.args, {'name': 'Deniz', 'n': 5});
      final bodies = plan.skip(1).map((p) => p.body).toList();
      expect(bodies.any(StruggleCategory.sleep.affirmationsTr.contains), isTrue, reason: 'kendi alanından söz');
      expect(bodies.any(kGeneralAffirmations.contains), isTrue, reason: 'genel söz de gelir');
      // Uyku alanı seçmeyen birine uyku sözleri gelmez.
      final other = LocalNotifier.dailyPlan(DateTime(2026, 11, 18, 9), checkedInToday: true, categories: [StruggleCategory.anger]);
      expect(other.map((p) => p.body).any(StruggleCategory.sleep.affirmationsTr.contains), isFalse);
      // Davet metni baskı kurmaz, sorunu adlandırmaz.
      for (final m in [LocalNotifier.checkInInviteStreak, LocalNotifier.greetingTitle]) {
        for (final w in ['bozul', 'kaybet', 'başarısız', 'sıfırlan']) {
          expect(m.toLowerCase().contains(w), isFalse, reason: m);
        }
      }
      expect(fillPlaceholders(LocalNotifier.checkInInviteStreak, plan.first.args), contains('5 günlük'));
    });

    test('sessiz saatler: yalnızca 10:00–20:59', () {
      expect(LocalNotifier.withinWindow(DateTime(2026, 11, 18, 7)), DateTime(2026, 11, 18, 10, 30));
      expect(LocalNotifier.withinWindow(DateTime(2026, 11, 18, 22)), DateTime(2026, 11, 19, 10, 30));
      expect(LocalNotifier.withinWindow(DateTime(2026, 11, 18, 15)), DateTime(2026, 11, 18, 15));
    });

    test('push bildirimleri de yukarıdan kayan (yüksek öncelikli) kanala düşer', () {
      // Kanal belirtilmezse Android FCM bildirimini "Diğer" kanalına koyar ve
      // yalnızca durum çubuğunda simge gösterir (uygulama kapalıyken de).
      final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(
        RegExp(r'default_notification_channel_id"\s+android:value="(\w+)"').firstMatch(manifest)?.group(1),
        LocalNotifier.gentleChannel.id,
      );
      expect(LocalNotifier.gentleChannel.importance, Importance.high);
      final functions = File('functions/index.js').readAsStringSync();
      expect(functions, contains('inbox: "${LocalNotifier.socialChannel.id}"'));
      expect(functions, contains('gentle_nudge: "${LocalNotifier.gentleChannel.id}"'));
    });
  });

  group('avatarlar, takma adlar ve temalar', () {
    test('avatara göre takma ad önerisi: "Sevimli Panda" gibi', () {
      for (var i = 0; i < kAvatars.length; i++) {
        final nick = suggestNickname(avatar: i);
        expect(nick, endsWith(kAvatars[i].name));
        expect(ContentModerator.check(nick, minLength: 2, maxLength: 24).isOk, isTrue, reason: nick);
      }
    });

    test('her avatarın değiştirilebilir varsayılan adı var ("Sevimli Kurbağa" gibi)', () {
      expect(kAvatars.length, greaterThanOrEqualTo(30));
      final names = <String>{};
      for (var i = 0; i < kAvatars.length; i++) {
        final nick = defaultNickname(i);
        expect(nick.length, inInclusiveRange(2, 24), reason: nick);
        expect(ContentModerator.check(nick, minLength: 2, maxLength: 24).isOk, isTrue, reason: nick);
        expect(nick.toLowerCase(), isNot(contains('nazik')));
        names.add(nick);
      }
      expect(names.length, kAvatars.length, reason: 'varsayılan adlar benzersiz');
      expect(kAvatars.map((a) => a.nick), contains('Sevimli Kurbağa'));
    });

    test('ücretsiz avatarlar önce, hediyeler artan seride açılır', () {
      expect(kFreeAvatarCount, greaterThanOrEqualTo(15));
      expect(kAvatars.take(kFreeAvatarCount).every((a) => !a.isGift), isTrue);
      final gifts = kAvatars.skip(kFreeAvatarCount).map((a) => a.unlockStreak).toList();
      expect(gifts, orderedEquals([...gifts]..sort()));
    });

    test('eski tema kayıtları uyumlu', () {
      expect(ThemePreset.parse('light'), ThemePreset.ocean);
      expect(ThemePreset.parse('night'), ThemePreset.night);
      expect(ThemePreset.parse(null), ThemePreset.ocean);
    });

    test('renk temaları: kırmızı, turuncu, yeşil, mavi, okyanus, pembe ücretsiz', () {
      final free = ThemePreset.values.where((p) => !p.isGift).toSet();
      expect(
          free,
          containsAll(
              [ThemePreset.crimson, ThemePreset.sunset, ThemePreset.forest, ThemePreset.sky, ThemePreset.ocean, ThemePreset.rose]));
      final ids = ThemePreset.values.map((p) => p.name).toSet();
      expect(ids.length, ThemePreset.values.length);
    });
  });

  group('topluluk yanıtları', () {
    test('yanıtlar da gönderinin çemberine göre denetlenir', () {
      expect(ContentModerator.check('Çok güzel bir adım, gurur duydum', circle: StruggleCategory.substance, minLength: 2).isOk,
          isTrue);
      expect(ContentModerator.check('bir bira içsen geçer', circle: StruggleCategory.substance, minLength: 2).isOk,
          isFalse);
      expect(ContentModerator.check('aptal mısın', minLength: 2).isOk, isFalse);
    });

    test('bildirim metni: yanıt bildirimi', () {
      final item = InboxItem(
        id: 'x',
        type: InboxType.noteReply,
        fromNickname: 'Sevimli Kurbağa',
        createdAt: null,
        read: false,
      );
      expect(item.title, contains('Sevimli Kurbağa'));
      expect(item.title, contains('yanıt'));
    });
  });
}
