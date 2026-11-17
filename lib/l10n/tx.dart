import 'package:flutter/foundation.dart';

import 'tx_tables.dart';

/// Haven'ın çeviri katmanı (gettext tarzı): Türkçe kaynak metin anahtardır.
///
///   tx('Paylaşım')                       → "Post" (en)
///   tx('{n} gün kaldı', {'n': 3})        → "3 days left" (en)
///
/// Çeviri tablosunda yer tutucular `{ad}` biçimindedir; tekil/çoğul ayrımı
/// gereken dillerde `{n|day|days}` yazılır (n == 1 ise ilk biçim).
///
/// Neden ARB değil? Uygulamanın içeriği (11 alanın bilgi metinleri, ipuçları,
/// olumlu sözler, günün sözleri, bildirimler) yüzlerce cümle; Türkçe metni
/// anahtar yapmak kodu okunur tutar ve eksik çeviriyi test kolayca yakalar
/// (test/translation_test.dart). Kısa arayüz etiketleri ARB'de kalmaya devam eder.
class Tx {
  Tx._();

  /// Etkin dil kodu: 'tr', 'en', 'es', 'zh', 'hi'. HavenApp her derlemede ayarlar.
  static String code = 'tr';

  static const _column = {'en': 0, 'es': 1, 'zh': 2, 'hi': 3};

  /// Yalnızca testler: istenen her anahtarı kaydeder.
  @visibleForTesting
  static void Function(String key)? onLookup;

  /// Bir anahtarın tablodaki satırı (testler için).
  static List<String>? row(String key) => kTx[key];
}

String tx(String tr, [Map<String, Object?> args = const {}]) {
  Tx.onLookup?.call(tr);
  var s = tr;
  final col = Tx._column[Tx.code];
  if (col != null) {
    final row = kTx[tr];
    if (row != null && row[col].isNotEmpty) {
      s = row[col];
    } else if (kDebugMode) {
      debugPrint('[tx] çeviri eksik (${Tx.code}): $tr');
    }
  }
  return fillPlaceholders(s, args);
}

/// Bir metin listesini etkin dile çevirir.
List<String> txList(Iterable<String> items) => [for (final s in items) tx(s)];

final _placeholder = RegExp(r'\{(\w+)(?:\|([^|}]*)\|([^}]*))?\}');

/// `{ad}` yer tutucularını ve `{n|tekil|çoğul}` biçimlerini doldurur.
@visibleForTesting
String fillPlaceholders(String s, Map<String, Object?> args) {
  if (args.isEmpty) return s;
  return s.replaceAllMapped(_placeholder, (m) {
    if (!args.containsKey(m[1])) return m[0]!;
    final v = args[m[1]];
    if (m[2] != null) return (v is num && v == 1) ? m[2]! : m[3]!;
    return '${v ?? ''}';
  });
}

/// Testler: bir metindeki yer tutucu adları.
@visibleForTesting
Set<String> placeholderNames(String s) => {for (final m in _placeholder.allMatches(s)) m[1]!};

const _weekdayShort = {
  'tr': ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'],
  'en': ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'],
  'es': ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do'],
  'zh': ['一', '二', '三', '四', '五', '六', '日'],
  'hi': ['सो', 'मं', 'बु', 'गु', 'शु', 'श', 'र'],
};

/// Pazartesiden başlayan kısa gün adları (etkin dilde).
List<String> weekdayShort() => _weekdayShort[Tx.code] ?? _weekdayShort['en']!;

/// Yüzde biçimi: Türkçede "%43", diğer dillerde "43%".
String formatPercent(int p) => Tx.code == 'tr' ? '%$p' : '$p%';
