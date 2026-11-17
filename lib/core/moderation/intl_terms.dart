import '../constants/struggle_catalog.dart';

/// Türkçe dışındaki diller (İngilizce, İspanyolca, Çince, Hintçe) için
/// denetim terimleri. Türkçe listelerle aynı kurallar:
///  - "=" ile başlayan terim yalnızca tam kelime eşleşir,
///  - boşluklu terim tam ifade olarak aranır,
///  - diğerleri kelime başı eşleşmesidir.
/// Latin dışı yazılı terimler (Çince, Hintçe) metnin içinde doğrudan aranır.
///
/// Bu listeler bir başlangıçtır; her dilde anadili konuşan biri tarafından
/// genişletilmelidir. Kriz terimleri en kritik olanlardır.
abstract final class IntlTerms {
  /// Kriz işaretleri: paylaşım yayınlanmaz, destek paneli açılır.
  static const crisis = [
    // en
    'suicide', 'suicidal', 'kill myself', 'want to die', 'end my life', 'end it all',
    'better off dead', 'no reason to live', "don't want to live", 'dont want to live',
    // es
    'suicidio', 'suicidarme', 'matarme', 'quiero morir', 'no quiero vivir',
    'quitarme la vida', 'acabar con mi vida',
    // zh
    '自杀', '想死', '不想活', '结束生命', '轻生',
    // hi
    'आत्महत्या', 'मरना चाहता', 'मरना चाहती', 'जीना नहीं चाहता', 'जीना नहीं चाहती', 'खुद को मार',
  ];

  static const profanity = [
    // en
    'fuck', '=shit', 'shitty', 'bitch', '=cunt', 'asshole', 'bastard', '=dick', 'motherfucker',
    '=slut', '=whore',
    // es
    '=puta', '=puto', 'mierda', '=coño', 'gilipollas', 'cabrón', 'pendejo', '=joder',
    'hijo de puta', '=verga', 'chingada', 'culero',
    // zh
    '操你', '傻逼', '他妈的', '贱人', '婊子',
    // hi
    'चूतिया', 'मादरचोद', 'भेनचोद', 'बहनचोद', 'हरामी', 'गांडू',
  ];

  static const insults = [
    // en
    'stupid', 'idiot', '=dumb', 'loser', 'pathetic', '=ugly', '=fat', '=freak', 'worthless',
    'attention seeking', 'just get over it', 'you are weak', 'drama queen',
    // es
    'estúpido', 'estúpida', 'idiota', 'imbécil', '=feo', '=fea', '=gordo', '=gorda',
    'patético', 'patética', 'inútil', 'perdedor', 'perdedora',
    // zh
    '笨蛋', '白痴', '废物', '丑八怪', '胖子', '矫情',
    // hi
    'बेवकूफ', 'मूर्ख', 'बदसूरत', 'मोटा', 'मोटी', 'निकम्मा',
  ];

  /// Herkes için tetikleyici ayrıntılar (yöntemler, sayılar, övgü).
  static const triggers = [
    // en
    'calorie', 'lost weight', 'gained weight', 'threw up', 'purging', 'laxative', 'razor',
    '=blade', 'got drunk', 'got high', 'jackpot',
    // es
    'calorías', 'bajé de peso', 'subí de peso', 'vomité', 'laxante', 'cuchilla', 'navaja',
    'borracho', 'borracha',
    // zh
    '卡路里', '催吐', '泻药', '刀片', '喝醉',
    // hi
    'कैलोरी', 'उल्टी', 'रेज़र', 'ब्लेड', 'नशे में',
  ];

  /// Alana özel tetikleyiciler (en hassas alanlar).
  static const byCategory = <StruggleCategory, List<String>>{
    StruggleCategory.eating: [
      'diet',
      'skinny',
      '=thin',
      'calories',
      'meal',
      'portion',
      'binge',
      '=bmi',
      'weigh',
      'dieta',
      'delgada',
      'delgado',
      'comida',
      'porción',
      'atracón',
      'peso',
      '减肥',
      '节食',
      '瘦',
      '体重',
      '暴食',
      'डाइट',
      'वजन',
      'पतला',
      'पतली',
      'खाना',
    ],
    StruggleCategory.selfHarm: [
      '=cut',
      'cutting',
      '=scar',
      '=scars',
      'bleed',
      'blood',
      'cortarme',
      'cicatriz',
      'sangre',
      '割',
      '伤疤',
      '流血',
      'काटना',
      'निशान',
      'खून',
    ],
    StruggleCategory.substance: [
      'beer',
      'vodka',
      'wine',
      'drunk',
      'cigarette',
      '=weed',
      '=vape',
      'cerveza',
      'vino',
      'cigarro',
      'porro',
      '啤酒',
      '喝酒',
      '香烟',
      '抽烟',
      'शराब',
      'बीयर',
      'सिगरेट',
    ],
    StruggleCategory.behavioral: [
      '=bet',
      'betting',
      'casino',
      'slot',
      'poker',
      'apuesta',
      'casino',
      'tragamonedas',
      '赌',
      '赌博',
      '下注',
      'सट्टा',
      'जुआ',
      'कैसीनो',
    ],
  };

  /// Sayı + birim (Latin dışı ve İngilizce/İspanyolca birimler).
  static final numberUnit = RegExp(
    r'\d+[.,]?\d*\s*(lbs?\b|pounds?\b|calories\b|cals?\b|libras\b|kilos\b|斤|公斤|千卡|卡路里|किलो)',
    caseSensitive: false,
  );

  static final _latin = RegExp(r'[a-zA-ZÀ-ɏ]');

  /// Latin dışı yazıyla (Çince, Hintçe) yazılmış terim mi?
  static bool isScriptTerm(String term) => !_latin.hasMatch(term);
}
