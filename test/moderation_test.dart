import 'package:flutter_test/flutter_test.dart';
import 'package:haven/core/constants/struggle_catalog.dart';
import 'package:haven/core/moderation/content_moderator.dart';

ModerationVerdict v(String text, [StruggleCategory? circle]) =>
    ContentModerator.check(text, circle: circle).verdict;

void main() {
  group('izin verilen nazik notlar', () {
    for (final note in [
      'Bugün 3. günüm, kendimle gurur duyuyorum.',
      'Zor bir gündü ama nefes egzersizi gerçekten iyi geldi.',
      'Yeni başlayan herkese: küçük adımlar da sayılır!',
      'Kanepede dinlenip biraz müzik dinledim.',
      'Ama bugün kendime nazik davrandım.',
      'Şikayet etmeden kendime alan açtım.',
    ]) {
      test(note, () => expect(v(note, StruggleCategory.selfHarm), ModerationVerdict.ok));
    }
  });

  group('küfür ve hakaret engellenir', () {
    test('düz küfür', () => expect(v('sen tam bir şerefsizsin'), ModerationVerdict.profanity));
    test('Türkçe karaktersiz yazım', () => expect(v('serefsiz biri'), ModerationVerdict.profanity));
    test('rakamlarla gizleme', () => expect(v('ne kadar s4l4k'), ModerationVerdict.insult));
    test('harf tekrarı', () => expect(v('saaaalak mısın'), ModerationVerdict.insult));
    test('harf harf yazım', () => expect(v('o r o s p u'), ModerationVerdict.profanity));
    test('küçümseme', () => expect(v('bence abartıyorsun'), ModerationVerdict.insult));
    test('yetersiz hissettirme', () => expect(v('sen bunu başaramazsın'), ModerationVerdict.insult));
  });

  group('tetikleyici ayrıntılar engellenir', () {
    test('kilo sayısı', () => expect(v('bu hafta 3 kilo verdim'), ModerationVerdict.trigger));
    test('kalori', () => expect(v('bugün kalori saymadım'), ModerationVerdict.trigger));
    test('para tutarı', () => expect(v('dün 500 tl kazandım'), ModerationVerdict.trigger));
    test('yöntem', () => expect(v('jilet aklıma geldi'), ModerationVerdict.trigger));
    test('çembere özel: OKB\'de güvence arama',
        () => expect(v('kapıyı kontrol et bence', StruggleCategory.ocd), ModerationVerdict.trigger));
    test('aynı ifade başka çemberde serbest',
        () => expect(v('kapıyı kontrol et bence', StruggleCategory.mood), ModerationVerdict.ok));
    test('çembere özel: depresyonda toksik pozitiflik',
        () => expect(v('biraz pozitif düşün', StruggleCategory.mood), ModerationVerdict.trigger));
  });

  group('yanlış pozitif yok (kelime başı eşleşme tuzakları)', () {
    test('"biraz" ≠ bira', () => expect(v('biraz daha iyiyim', StruggleCategory.substance), ModerationVerdict.ok));
    test('"fırtına" ≠ fırt', () => expect(v('fırtına dindi sanki', StruggleCategory.substance), ModerationVerdict.ok));
    test('"rakip" ≠ rakı', () => expect(v('kendimle rakip değilim', StruggleCategory.substance), ModerationVerdict.ok));
    test('"kilometre" ≠ kilo', () => expect(v('iki kilometre yürüdüm', StruggleCategory.eating), ModerationVerdict.ok));
    test('"gülümsedim" serbest', () => expect(v('bugün gülümsedim', StruggleCategory.mood), ModerationVerdict.ok));
    test('ama emir kipi engellenir', () => expect(v('biraz gülümse', StruggleCategory.mood), ModerationVerdict.trigger));
    test('"bira" yine engellenir', () => expect(v('bir bira içsem', StruggleCategory.substance), ModerationVerdict.trigger));
  });

  group('kriz işaretleri paylaşılmaz, destek gösterilir', () {
    for (final s in ['artık yaşamak istemiyorum', 'intihar etmeyi düşünüyorum', 'Ölmek istiyorum']) {
      test(s, () => expect(v(s), ModerationVerdict.crisis));
    }
  });

  group('kişisel bilgi paylaşılmaz', () {
    test('link', () => expect(v('şuraya bak www.ornek.com'), ModerationVerdict.personalInfo));
    test('telefon', () => expect(v('beni ara 0532 123 45 67'), ModerationVerdict.personalInfo));
    test('kullanıcı adı', () => expect(v('instadan yaz @birisi123'), ModerationVerdict.personalInfo));
  });

  test('uzunluk sınırları', () {
    expect(v('  '), ModerationVerdict.empty);
    expect(v('ab'), ModerationVerdict.tooShort);
    expect(v('a' * 281), ModerationVerdict.tooLong);
  });
}
