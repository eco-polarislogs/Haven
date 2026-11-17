import 'package:flutter_test/flutter_test.dart';
import 'package:haven/core/constants/app_constants.dart';
import 'package:haven/core/constants/struggle_catalog.dart';
import 'package:haven/core/moderation/content_moderator.dart';

/// Uygulama içi metinler için DİL DENETİMİ.
/// Her kategorinin metinleri, topluluk notlarına uygulanan denetimin AYNISINDAN
/// geçmeli: küfür/hakaret yok, genel tetikleyici yok, O KATEGORİNİN kendi
/// tetikleyici kelimeleri yok. Sunucu tarafındaki eşi: functions/nudges.test.js
const _judgmental = ['başarısız', 'kaybet', 'bozul', 'sıfırla', 'hayal kırıklığı', 'yine mi'];

void main() {
  for (final c in StruggleCategory.values) {
    group(c.name, () {
      final texts = <String>[c.checkInQuestion, c.hardDayMessage, ...c.calmTips, ...c.affirmations];
      for (final text in texts) {
        test(text, () {
          final r = ContentModerator.check(text, circle: c, maxLength: 400);
          // selfHarm destek metinleri 112'yi ve güvende olmayı anar; kriz değil, yardım yönlendirmesi.
          expect(r.verdict, ModerationVerdict.ok, reason: '${r.verdict} (${r.term}) → $text');
          final lower = text.toLowerCase();
          for (final w in _judgmental) {
            expect(lower.contains(w), isFalse, reason: '"$w" → $text');
          }
        });
      }
    });
  }

  test('genel olumlu sözler ve cesaret notları denetimden geçer', () {
    for (final s in [...kGeneralAffirmations, ...kKudosMessages, ...kNotePrompts.map((p) => '$p iyi geldi')]) {
      final r = ContentModerator.check(s, maxLength: 400);
      expect(r.isOk, isTrue, reason: '${r.verdict} (${r.term}) → $s');
    }
  });

  test('her kategoride en az 6 olumlu söz ve 4 sakinleşme önerisi var', () {
    for (final c in StruggleCategory.values) {
      expect(c.affirmations.length, greaterThanOrEqualTo(6), reason: c.name);
      expect(c.calmTips.length, greaterThanOrEqualTo(4), reason: c.name);
      expect(typesOf(c), isNotEmpty, reason: c.name);
    }
  });

  test('kendine zarar verme kategorisi her zaman acil yardım yolunu gösterir', () {
    expect(StruggleCategory.selfHarm.hardDayMessage, contains('112'));
    expect(kSupportLines.any((l) => l.number == '112'), isTrue);
  });

  test('en hassas kategori en yüksek bakım seviyesine sahip', () {
    final maxCare = StruggleCategory.values.map((c) => c.careLevel).reduce((a, b) => a > b ? a : b);
    expect(StruggleCategory.selfHarm.careLevel, maxCare);
  });

  test('arkadaş kodu karışan karakter içermez', () {
    for (var i = 0; i < 200; i++) {
      final code = generateFriendCode();
      expect(code.length, 6);
      expect(RegExp(r'[01OI]').hasMatch(code), isFalse);
    }
  });

  test('önerilen takma adlar denetimden geçer', () {
    for (var i = 0; i < 100; i++) {
      final nick = suggestNickname();
      expect(ContentModerator.check(nick, minLength: 2, maxLength: 24).isOk, isTrue, reason: nick);
    }
  });
}
