import 'package:flutter_test/flutter_test.dart';
import 'package:haven/core/constants/struggle_catalog.dart';
import 'package:haven/core/moderation/content_moderator.dart';

/// Okuyan tarafı koruma: başkasının paylaşımındaki, okuyanın alanları için
/// tetikleyici ifadeler "•••" ile gizlenir.
void main() {
  const eating = [StruggleCategory.eating];

  test('yeme alanındaki okuyan için diyet/kalori ifadeleri gizlenir', () {
    final m = ContentModerator.maskFor('Bugün diyet düşünmeden yürüdüm, kalori saymadım.', eating);
    expect(m.text, 'Bugün ••• düşünmeden yürüdüm, ••• saymadım.');
    expect(m.hidden, 2);
  });

  test('sayı + birim ("5 kilo") bütün olarak gizlenir', () {
    final m = ContentModerator.maskFor('Bu ay 5 kilo fark var dediler.', eating);
    expect(m.text, isNot(contains('5')));
    expect(m.text, isNot(contains('kilo')));
    expect(m.hidden, greaterThanOrEqualTo(1));
  });

  test('tam kelime terimleri yanlış pozitif vermez ("kilometre")', () {
    final m = ContentModerator.maskFor('Bugün 3 kilometre yürüdüm, çok iyi geldi.', eating);
    expect(m.hidden, 0);
    expect(m.text, 'Bugün 3 kilometre yürüdüm, çok iyi geldi.');
  });

  test('başka alandaki okuyan için o alanın kelimeleri gizlenmez', () {
    final m = ContentModerator.maskFor('Bugün diyet düşünmeden yürüdüm.', const [StruggleCategory.sleep]);
    expect(m.hidden, 0);
  });

  test('herkes için tetikleyici ayrıntılar her okuyana gizlenir', () {
    final m = ContentModerator.maskFor('Eski jilet izlerime bakmadım bugün.', const [StruggleCategory.sleep]);
    expect(m.text, contains('•••'));
    expect(m.text, isNot(contains('jilet')));
  });

  test('Türkçe büyük İ harfi konumları kaydırmaz', () {
    final m = ContentModerator.maskFor('İyi bir gün; DİYET yok, sadece İçimden geleni yaptım.', eating);
    expect(m.text, 'İyi bir gün; ••• yok, sadece İçimden geleni yaptım.');
  });

  test("gönderen tarafı: \"3 kilometre\" ve \"5 grup\" engellenmez, \"5 kilo\" engellenir", () {
    expect(ContentModerator.check("Bugün 3 kilometre yürüdüm").isOk, isTrue);
    expect(ContentModerator.check("5 grup arkadaşla buluştum").isOk, isTrue);
    expect(ContentModerator.check("5 kilo verdim").isOk, isFalse);
    expect(ContentModerator.check("10 kg fark var").isOk, isFalse);
  });
}
