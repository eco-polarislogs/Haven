import 'package:flutter_test/flutter_test.dart';
import 'package:haven/core/constants/country_support.dart';
import 'package:haven/core/constants/struggle_catalog.dart';
import 'package:haven/core/moderation/content_moderator.dart';
import 'package:haven/features/profile/badges.dart';

/// Evrensel kullanım: ülkeye göre destek hatları, çok dilli denetim, rozetler.
void main() {
  group('ülkeye göre destek hatları', () {
    test('telefonun bölgesi listede varsa o kullanılır', () {
      expect(guessCountry('US', 'tr'), 'US');
      expect(countrySupportFor('US').emergency, '911');
      expect(countrySupportFor('US').lines.first.number, '988');
      expect(countrySupportFor('GB').emergency, '999');
    });

    test('bölge bilinmiyorsa dilden tahmin; İngilizce → diğer ülkeler (112 + rehber)', () {
      expect(guessCountry(null, 'tr'), 'TR');
      expect(guessCountry('BR', 'es'), 'ES');
      expect(guessCountry(null, 'en'), 'XX');
      expect(countrySupportFor('XX').lines, isEmpty);
      expect(countrySupportFor('nope').code, 'XX');
    });

    test('her ülkenin acil numarası ilk sırada', () {
      for (final c in kCountrySupport) {
        expect(c.allLines.first.number, c.emergency);
        expect(c.emergency, isNotEmpty);
      }
      expect(countrySupportFor('TR').isTurkey, isTrue);
    });
  });

  group('çok dilli denetim', () {
    test('kriz ifadeleri her dilde destek paneline yönlendirir', () {
      for (final s in ['I want to die', 'quiero morir', '我想死了', 'मैं मरना चाहता हूँ']) {
        expect(ContentModerator.check(s, minLength: 2).verdict, ModerationVerdict.crisis, reason: s);
      }
    });

    test('İngilizce ve İspanyolca küfür / küçümseme engellenir', () {
      expect(ContentModerator.check('you are pathetic').verdict, ModerationVerdict.insult);
      expect(ContentModerator.check('qué mierda de día').verdict, ModerationVerdict.profanity);
      expect(ContentModerator.check('eres estúpido').verdict, ModerationVerdict.insult);
    });

    test('masum cümleler geçer', () {
      for (final s in ['I took a short walk and felt better', 'Hoy di un paseo corto', '今天我散步了，感觉好多了']) {
        expect(ContentModerator.check(s).isOk, isTrue, reason: s);
      }
    });

    test('İngilizce birim ("10 lbs") tetikleyici sayılır', () {
      expect(ContentModerator.check('lost 10 lbs this month').verdict, ModerationVerdict.trigger);
    });

    test('okuyan tarafı: Çince tetikleyici kelime metin içinde gizlenir', () {
      final m = ContentModerator.maskFor('今天我没有想减肥的事', const [StruggleCategory.eating]);
      expect(m.text, isNot(contains('减肥')));
      expect(m.hidden, 1);
    });
  });

  group('rozetler', () {
    List<HavenBadge> badges({int best = 0, int kind = 0, bool comeback = false, int posts = 0}) => computeBadges(
      best: best,
      totalKind: kind,
      comeback: comeback,
      posts: posts,
      supportsGiven: 0,
      journal: 0,
      friends: 0,
    );

    test('yeni kullanıcıda hiçbiri yok; ilerledikçe açılır', () {
      expect(badges().where((b) => b.earned), isEmpty);
      final b = badges(best: 7, kind: 9, comeback: true, posts: 1);
      final earned = b.where((x) => x.earned).map((x) => x.titleTr).toSet();
      expect(earned, containsAll(['İlk adım', '3 günlük seri', 'Bir hafta', 'Yeniden başladın', 'İlk paylaşım']));
      expect(earned, isNot(contains('İki hafta')));
    });

    test('rozet adlarında bitki emojisi yok', () {
      for (final b in badges()) {
        expect(b.emoji, isNot(anyOf('🌱', '🌿', '🌸', '🍃', '🌼')));
      }
    });
  });
}
