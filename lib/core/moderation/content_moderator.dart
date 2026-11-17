import '../constants/struggle_catalog.dart';

/// Topluluk notlarının ve takma adların denetimi.
///
/// Amaç: Haven'daki hiçbir paylaşım, aynı yolda yürüyen birini incitmesin,
/// tetiklemesin ya da yetersiz hissettirmesin. Denetim iki katmanlı:
///  1. İstemci (bu dosya): ayrıntılı, Türkçeye özel kontrol; kullanıcıya
///     nazik bir açıklama gösterilir.
///  2. Sunucu (firestore.rules → clean()): en ağır ifadeleri istemci
///     atlatılsa bile reddeder.
/// Ayrıca kullanıcılar notları bildirebilir; 3 bildirimde not gizlenir.
///
/// Kelime listesi bir başlangıçtır; hiçbir filtre kusursuz değildir.
enum ModerationVerdict { ok, empty, tooShort, tooLong, crisis, personalInfo, profanity, insult, trigger }

class ModerationResult {
  const ModerationResult(this.verdict, [this.term]);

  final ModerationVerdict verdict;
  final String? term;

  bool get isOk => verdict == ModerationVerdict.ok;

  String get message => switch (verdict) {
        ModerationVerdict.ok => '',
        ModerationVerdict.empty => 'Bir şeyler yazmayı dener misin?',
        ModerationVerdict.tooShort => 'Biraz daha uzun yazmayı dener misin?',
        ModerationVerdict.tooLong => 'Notlar en fazla ${ContentModerator.maxNoteLength} karakter olabilir.',
        ModerationVerdict.crisis =>
          'Yazdıkların şu an çok zorlandığını gösteriyor. Bu notu paylaşmak yerine '
              'sana destek olmak istiyoruz.',
        ModerationVerdict.personalInfo =>
          'Güvenliğin için notlarda link, telefon, e-posta ya da kullanıcı adı paylaşılamıyor.',
        ModerationVerdict.profanity || ModerationVerdict.insult =>
          'Bu metinde kırıcı olabilecek bir ifade var. Haven herkes için güvenli bir liman '
              'olsun diye bunu paylaşamıyoruz. Aynı şeyi daha yumuşak kelimelerle anlatmayı dener misin?',
        ModerationVerdict.trigger =>
          'Bu not, aynı yolda yürüyen birini tetikleyebilecek bir ayrıntı içeriyor '
              '(örneğin sayılar, yöntemler ya da tetikleyici kelimeler). Deneyimini '
              'ayrıntıya girmeden, hislerin üzerinden paylaşmayı dener misin?',
      };
}

class ContentModerator {
  ContentModerator._();

  static const maxNoteLength = 280;

  // "=" ile başlayan terim: yalnızca tam kelime. Boşluklu terim: tam ifade.
  // Diğerleri: kelime başı eşleşmesi (Türkçe ekleri yakalamak için).
  static const _profanity = [
    '=am', '=amk', '=aq', '=amq', '=mk', '=oc', 'amına', 'amcık', 'orospu', 'orosbu',
    'piç', 'siktir', 'sikerim', 'sikeyim', 'siktiğim', 'sikik', '=sik', 'yarrak', '=yarak',
    '=göt', 'götveren', 'pezevenk', 'kahpe', 'kaltak', 'ibne', 'puşt', 'gavat', 'yavşak',
    'şerefsiz', 'haysiyetsiz', 'dalyarak', 'sürtük', 'fahişe', 'ananı', 'ananın',
    '=bok', 'boktan', '=lan', '=mal',
  ];

  static const _insults = [
    'aptal', 'salak', 'gerizekalı', 'geri zekalı', 'ahmak', 'dangalak', 'embesil',
    'beyinsiz', 'ezik', 'zavallı', 'rezil', 'iğrenç', 'şişko', 'çirkin', 'şımarık',
    'psikopat', 'manyak', '=deli', 'acınası',
    // yetersiz hissettiren / küçümseyen ifadeler
    'abartıyorsun', 'abartma', 'ilgi çekmek', 'bahane', 'yapamazsın', 'başaramazsın',
    'utanmalısın', 'yazık sana', 'tembelsin', 'değersizsin', 'beceriksizsin',
    'işe yaramazsın', 'kaybedensin', 'senden iyiyim', 'benden kötü',
  ];

  /// Herkes için tetikleyici ayrıntılar (yöntemler, sayılar, övgü).
  static const _triggers = [
    '=kg', 'kilo verdim', 'kilo aldım', 'kalori', '=kcal', 'kustum', 'kusmak',
    'laksatif', 'müshil', 'aç kaldım', 'jilet', 'kesik', 'kestim', 'yara izi',
    'kanattım', 'kafam iyi', 'sarhoş', 'kupon', 'jackpot',
  ];

  /// Kriz işaretleri: not paylaşılmaz, kullanıcıya destek gösterilir.
  static const _crisis = [
    'intihar', 'kendimi öldür', 'ölmek istiyorum', 'yaşamak istemiyorum',
    'hayatıma son', 'canıma kıy', 'kendimi kes', 'kendime zarar vereceğim',
    'yok olmak istiyorum', 'artık dayanamıyorum',
  ];

  static final _numberUnit = RegExp(r'\d+[.,]?\d*\s*(kg|kilo|kalori|kcal|gr|gram|tl|lira|₺)');
  static final _url = RegExp(r'(https?://|www\.|\.(com|net|org|tr|io|me)\b)', caseSensitive: false);
  static final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');
  static final _handle = RegExp(r'(^|\s)@\w{3,}');
  static final _phone = RegExp(r'(\d[\s-]?){10,}');

  static ModerationResult check(
    String raw, {
    StruggleCategory? circle,
    int minLength = 3,
    int maxLength = maxNoteLength,
  }) {
    final text = raw.trim();
    if (text.isEmpty) return const ModerationResult(ModerationVerdict.empty);
    if (text.length < minLength) return const ModerationResult(ModerationVerdict.tooShort);
    if (text.length > maxLength) return const ModerationResult(ModerationVerdict.tooLong);

    final norm = normalize(text);
    final toks = tokenize(norm);
    // "s a l a k" gibi harf harf yazılmış kelimeleri birleştir (sadece tek
    // harflik ardışık parçalar; "yara kapandı" gibi cümleler etkilenmez).
    final merged = _mergeSingleLetters(toks);

    String? hit(List<String> terms) {
      for (final t in terms) {
        if (containsTerm(toks, t) || containsTerm(merged, t)) return t;
      }
      return null;
    }

    final crisis = hit(_crisis);
    if (crisis != null) return ModerationResult(ModerationVerdict.crisis, crisis);

    final lower = text.toLowerCase();
    if (_url.hasMatch(lower) || _email.hasMatch(lower) || _handle.hasMatch(lower) || _phone.hasMatch(lower)) {
      return const ModerationResult(ModerationVerdict.personalInfo);
    }

    final prof = hit(_profanity);
    if (prof != null) return ModerationResult(ModerationVerdict.profanity, prof);

    final ins = hit(_insults);
    if (ins != null) return ModerationResult(ModerationVerdict.insult, ins);

    // Rakam + birim ("5 kilo", "500 tl") rakamlar harfe çevrilmeden önce aranır.
    if (_numberUnit.hasMatch(lower)) {
      return const ModerationResult(ModerationVerdict.trigger, 'sayı');
    }
    final trig = hit(_triggers) ?? (circle == null ? null : hit(circle.avoidWords));
    if (trig != null) return ModerationResult(ModerationVerdict.trigger, trig);

    return const ModerationResult(ModerationVerdict.ok);
  }

  /// Küçük harf (Türkçe), leetspeak çözümü, Türkçe karakterleri sadeleştirme
  /// ve tekrarlanan harfleri teke indirme ("saaalak" → "salak").
  static String normalize(String s) {
    var t = s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
    const map = {
      '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '7': 't', '@': 'a', r'$': 's', '€': 'e',
      'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u', 'â': 'a', 'î': 'i', 'û': 'u',
    };
    final b = StringBuffer();
    String? prev;
    for (final ch in t.split('')) {
      final c = map[ch] ?? ch;
      if (c == prev && _letter.hasMatch(c)) continue;
      b.write(c);
      prev = c;
    }
    t = b.toString();
    return t;
  }

  static final _letter = RegExp(r'[a-z]');

  static List<String> _mergeSingleLetters(List<String> toks) {
    final out = <String>[];
    final run = StringBuffer();
    var runLen = 0;
    void flush() {
      if (runLen >= 3) {
        out.add(run.toString());
      } else if (runLen > 0) {
        out.addAll(run.toString().split(''));
      }
      run.clear();
      runLen = 0;
    }

    for (final w in toks) {
      if (w.length == 1) {
        run.write(w);
        runLen++;
      } else {
        flush();
        out.add(w);
      }
    }
    flush();
    return out;
  }

  static List<String> tokenize(String normalized) => normalized
      .split(RegExp(r'[^a-z0-9₺]+'))
      .where((w) => w.isNotEmpty)
      .toList();

  static bool containsTerm(List<String> toks, String rawTerm) {
    final exact = rawTerm.startsWith('=');
    final term = normalize(exact ? rawTerm.substring(1) : rawTerm);
    final parts = tokenize(term);
    if (parts.isEmpty) return false;
    if (parts.length == 1) {
      final p = parts.first;
      return toks.any((w) => exact ? w == p : w.startsWith(p));
    }
    // Çok kelimeli ifade: ardışık tam eşleşme
    for (var i = 0; i + parts.length <= toks.length; i++) {
      var ok = true;
      for (var j = 0; j < parts.length; j++) {
        if (toks[i + j] != parts[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }
}
