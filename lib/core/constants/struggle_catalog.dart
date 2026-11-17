/// Mücadele alanları kataloğu.
///
/// Sınıflandırma DSM-5-TR (APA) ve ICD-11 (DSM-Ö) gruplarına dayanır.
/// Rakamlar yalnızca doğrulanabilen resmi kaynaklardan alınmıştır (WHO, NIMH);
/// rakamı doğrulanamayan alanlarda rakam verilmez.
///
/// Neden Firestore'da değil de kodda? Katalog nadiren değişir; kodda durması
/// offline çalışmayı ve sıfır okuma maliyetini garanti eder. `category.name`
/// değerleri Cloud Functions'taki mesaj havuzlarıyla birebir aynıdır.
///
/// `avoidWords`: O kategorideki birini tetikleyebilecek kelimeler. Hem bu
/// dosyadaki metinlerde (test/tone_test.dart) hem de o çemberdeki topluluk
/// notlarında (ContentModerator) engellenir. "=" ile başlayan terim yalnızca
/// tam kelime olarak eşleşir (ör. "=kan", "kanepe"yi engellemez).
library;

import 'package:flutter/material.dart';

import '../../l10n/tx.dart';

enum StruggleCategory {
  bfrb(
    title: 'Bedene yönelik tekrarlayan davranışlar',
    shortTitle: 'Tekrarlayan davranışlar',
    subtitle: 'Saç, deri, tırnak',
    icon: Icons.back_hand_outlined,
    careLevel: 2,
    checkInQuestion: 'Bugün ellerine ve kendine nazik davranabildin mi?',
    hardDayMessage:
        'Zor bir gün müydü? Ellerinin yorulması senin suçun değil. '
        'İstersen birlikte nefes alalım ya da ellerini kısa bir oyunla meşgul edelim.',
    calmTips: [
      'Ellerini meşgul et: bir stres topu, yumuşak bir kumaş ya da kalem tut.',
      'Ellerini birkaç saniye serin suyun altında tut.',
      'Rahatla sekmesindeki baloncuk oyunu ellerine güvenli bir uğraş verir.',
      'Dürtü bir dalga gibidir: yükselir, zirve yapar ve geçer.',
    ],
    affirmations: [
      'Ellerin seni anlatmaz; çaban anlatır.',
      'Bugün kendine gösterdiğin sabır, yarının gücü.',
      'Dürtüyü fark etmek bile büyük bir adım.',
      'Mükemmel olmak zorunda değilsin; nazik olman yeter.',
      'Her denemen, kendine verdiğin bir söz.',
      'Yavaş ilerlemek de ilerlemektir.',
    ],
    avoidWords: ['yoldum', 'kopardım', 'koparmak', 'kanattım', 'kabuk', 'sivilce sık'],
    info:
        'Saç yolma (trikotillomani), deri yolma (dermatillomani) ve benzeri '
        'davranışlar DSM-5-TR\'de "obsesif-kompulsif ve ilişkili bozukluklar" '
        'arasında sınıflanır. Bir irade zayıflığı değildir; alışkanlık tersine '
        'çevirme eğitimi gibi terapilerle iyileşme mümkündür.',
    source: 'APA, DSM-5-TR',
  ),
  ocd(
    title: 'Takıntılar ve kompulsiyonlar',
    shortTitle: 'Takıntılar',
    subtitle: 'Kontrol etme, tekrarlama, istenmeyen düşünceler',
    icon: Icons.repeat_rounded,
    careLevel: 4,
    checkInQuestion: 'Bugün düşüncelerinle biraz mesafe koyabildin mi?',
    hardDayMessage:
        'Takıntılı düşünceler çok yorucu olabilir. Bugün zor geçtiyse '
        'bu senin hatan değil; düşüncelerin sen değilsin.',
    calmTips: [
      'Düşünceyi fark et ve adını koy: "Bu bir takıntılı düşünce."',
      'Hemen tepki vermek yerine beş dakika beklemeyi dene.',
      'Dikkatini ellerini kullanan bir uğraşa ver: hafıza kartları oyunu gibi.',
      'Belirsizliğe biraz alan açmak, zamanla kaygıyı azaltır.',
    ],
    affirmations: [
      'Düşüncelerin sen değilsin.',
      'Belirsizliğe katlanabildiğin her an, güçlendiğin bir an.',
      'Kendinle sabırlı olman en büyük adım.',
      'Bugün bir dürtüyü ertelediysen, bu gerçek bir başarı.',
      'Zihnin yorulduğunda dinlenmek de bir beceridir.',
      'Kusursuz olmak yok; yeterince iyi olmak var.',
    ],
    avoidWords: ['kontrol et', 'emin misin', 'tekrar bak', 'mikrop', 'pislik'],
    info:
        'Obsesif-kompulsif bozukluk (OKB); istenmeyen, tekrarlayan düşünceler ve '
        'bunları yatıştırmaya yönelik tekrarlayan davranışlarla seyreder. Bilişsel '
        'davranışçı terapi, özellikle maruz bırakma ve tepki önleme, etkili bir tedavidir.',
    fact: 'ABD\'de yetişkinlerin yaklaşık %1,2\'si son bir yılda OKB yaşamış.',
    source: 'NIMH',
  ),
  anxiety(
    title: 'Kaygı ve panik',
    shortTitle: 'Kaygı',
    subtitle: 'Sürekli endişe, panik atak, sosyal kaygı',
    icon: Icons.air_rounded,
    careLevel: 4,
    checkInQuestion: 'Bugün kaygınla birlikte de olsa kendine alan açabildin mi?',
    hardDayMessage:
        'Kaygı bazen bedeni de yorar. Bugün zor geçtiyse, bu da geçecek. '
        'Birlikte yavaşça nefes alalım mı?',
    calmTips: [
      'Nefes verişini nefes alışından uzun tut: 4 saniye al, 6 saniye ver.',
      '5-4-3-2-1 topraklanma egzersizini dene (Rahatla sekmesinde).',
      'Ayaklarını yere bastır ve zeminin seni taşıdığını hisset.',
      'Panik dalgası genellikle birkaç dakika içinde zirve yapıp azalır.',
    ],
    affirmations: [
      'Bu his geçici; sen kalıcısın.',
      'Şu an güvendesin. Bir nefes daha.',
      'Kaygı seni korumaya çalışıyor; ona teşekkür edip bırakabilirsin.',
      'Her şeyi bugün çözmek zorunda değilsin.',
      'Yavaşlamak da bir cesaret biçimi.',
      'Kendine tanıdığın her mola, sinir sistemine bir hediye.',
    ],
    avoidWords: ['sakin ol', 'abartma', 'boşver', 'takma kafana', 'kalp krizi', 'ölüyorum'],
    info:
        'Kaygı bozuklukları dünyada en yaygın ruh sağlığı sorunlarıdır. Bilişsel '
        'davranışçı terapi ve gerektiğinde ilaç tedavisiyle iyileşme mümkündür.',
    fact: 'Dünyada 359 milyon kişi bir kaygı bozukluğuyla yaşıyor (2021 verisi).',
    source: 'WHO, 2025',
  ),
  mood(
    title: 'Depresif duygu durum',
    shortTitle: 'Duygu durum',
    subtitle: 'Çökkünlük, isteksizlik, tükenmişlik',
    icon: Icons.wb_twilight_rounded,
    careLevel: 8,
    checkInQuestion: 'Bugün kendine küçük de olsa bir iyilik yapabildin mi?',
    hardDayMessage:
        'Bazı günler yataktan kalkmak bile büyük bir iş. Bugün zor '
        'geçtiyse, burada olman yeterli. Sadece bir sonraki küçük adıma bak.',
    calmTips: [
      'Bugünü tek bir küçük hedefe indir: bir bardak su, beş dakika pencere önü.',
      'Güvendiğin birine kısa bir mesaj at; uzun konuşmak zorunda değilsin.',
      'Gün ışığında birkaç dakika geçirmek iyi gelebilir.',
      'Bu duygular iki haftadan uzun sürüyorsa bir uzmana danışmak önemli.',
    ],
    affirmations: [
      'Bugün sadece var olman bile yeterli.',
      'Küçük adımlar da sayılır; hatta en çok onlar sayılır.',
      'Hissettiklerin gerçek ve geçici.',
      'Yardım istemek güçsüzlük değil, cesarettir.',
      'Karanlık günler, ışığın yok olduğu anlamına gelmez.',
      'Kendine bugün bir arkadaşına göstereceğin şefkati göster.',
    ],
    // Emir kipleri tam kelime: "gülümsedim" gibi olumlu paylaşımlar engellenmesin.
    avoidWords: ['=neşelen', 'pozitif düşün', '=gülümse', 'dert etme', 'tembel', '=şükret', 'senden kötüleri'],
    info:
        'Depresyon tedavi edilebilir bir sağlık sorunudur; bir karakter kusuru '
        'değildir. Psikoterapi ve gerektiğinde ilaç tedavisi etkilidir. Tükenmişlik '
        '(burnout) ICD-11\'de mesleki bir olgu olarak tanımlanır.',
    fact: 'Dünyada 280 milyon kişi depresyonla yaşıyor (2019 verisi).',
    source: 'WHO',
  ),
  eating(
    title: 'Yeme ve beden algısı',
    shortTitle: 'Beden algısı',
    subtitle: 'Anoreksiya, bulimiya, tıkınırcasına yeme, beden algısı',
    icon: Icons.accessibility_new_rounded,
    careLevel: 9,
    checkInQuestion: 'Bugün bedenine şefkatle yaklaşabildin mi?',
    hardDayMessage:
        'Bazı günler bedeninle ilişkin daha zor hissettirir; bu seni '
        'asla daha az değerli yapmaz. Bugün kendine biraz yumuşaklık göster.',
    calmTips: [
      'Kendine yüksek sesle nazik bir cümle söyle: "Elimden geleni yapıyorum."',
      'Güvendiğin biriyle birkaç dakika konuş ya da mesajlaş.',
      'Bedeninin bugün senin için yaptığı bir şeyi düşün: nefes almak, yürümek, sarılmak.',
      '5-4-3-2-1 topraklanma egzersizi zihni şimdiye getirir.',
    ],
    affirmations: [
      'Değerin bir sayıyla ölçülemez.',
      'Bedenin bir proje değil, senin evin.',
      'Bugün kendine gösterdiğin şefkat, iyileşmenin ta kendisi.',
      'Ayna sana hikâyenin sadece bir sayfasını gösterir.',
      'Bedenini dinlemek bir beceridir ve zamanla gelişir.',
      'İyileşme düz bir çizgi değil; her gün yeniden başlayabilirsin.',
    ],
    avoidWords: [
      // "kilo" tam kelime ve ekli halleri: "kilometre" engellenmesin.
      'kalori', '=kilo', '=kilom', '=kiloyu', '=kilolar', '=kiloya', '=kiloda', '=kg',
      'diyet', 'zayıf', 'şişman', 'yemek', 'öğün',
      'porsiyon', 'kusma', 'kustum', 'aç kal', 'beden ölçü', '=bmi', 'gram', '=yağ', 'ağır',
    ],
    info:
        'Yeme bozuklukları ICD-11 ve DSM-5-TR\'de tanımlanmış, tedavi edilebilir '
        'ruh sağlığı sorunlarıdır. Erken destek iyileşmeyi kolaylaştırır; bir '
        'uzmanla konuşmak güçlü bir adımdır.',
  ),
  behavioral(
    title: 'Davranışsal bağımlılıklar',
    shortTitle: 'Davranışsal',
    subtitle: 'Ekran, oyun, alışveriş, kumar',
    icon: Icons.smartphone_outlined,
    careLevel: 3,
    checkInQuestion: 'Bugün zihnine nefes alacak bir alan açabildin mi?',
    hardDayMessage:
        'Zihnin çok yorulmuş olabilir. Tökezlemek yolun bir parçası; '
        'önemli olan yeniden denemek.',
    calmTips: [
      'Telefonu başka bir odaya bırakıp beş dakika yürü.',
      'Dürtüye bir isim ver ve geçmesini izle: "Bu sadece bir dalga."',
      'Bildirimleri bir saatliğine kapatmayı dene.',
      'Ellerini meşgul edecek kısa bir uğraş seç.',
    ],
    affirmations: [
      'Dikkatini geri almak, kendini geri almaktır.',
      'Bugün bir dürtüye "şimdi değil" dediysen, bu gerçek bir zafer.',
      'Sıkılmak tehlikeli değil; bazen yaratıcılığın kapısıdır.',
      'Zamanın senin; nereye harcayacağına sen karar verirsin.',
      'Tökezlemek seni geri götürmez, sadece yavaşlatır.',
      'Gerçek dünyadaki küçük anlar da değerlidir.',
    ],
    avoidWords: ['kupon', 'bahis', '=oran', 'jackpot', 'kazandım', 'indirim', 'sepet', 'kampanya'],
    info:
        'Kumar bozukluğu ve oyun bozukluğu (ICD-11: 6C50 ve 6C51), Dünya Sağlık '
        'Örgütü tarafından tanınan bağımlılık davranışlarıdır. Ekran ve alışveriş '
        'dürtüleri de benzer yöntemlerle ele alınabilir.',
    fact: 'Dünyada yetişkinlerin yaklaşık %1,2\'si kumar bozukluğu yaşıyor.',
    source: 'WHO',
  ),
  substance(
    title: 'Madde kullanımı',
    shortTitle: 'Madde',
    subtitle: 'Sigara, elektronik sigara, alkol, diğer maddeler',
    icon: Icons.smoke_free_rounded,
    careLevel: 6,
    checkInQuestion: 'Bugün kendine iyi gelen seçimler yapabildin mi?',
    hardDayMessage:
        'Bugün zordu ve yine de buraya gelip bunu paylaştın. Bu çok '
        'değerli bir adım. Yarın yeni bir sayfa.',
    calmTips: [
      'İsteğin şiddeti genellikle dalga gibi yükselip azalır; bu nefesle zaman kazan.',
      'Bir bardak su iç, ellerini ve ağzını meşgul et.',
      'Güvendiğin birine kısa bir mesaj at.',
      'İsteğin geldiği yeri ve saati fark et; tetikleyicini tanımak güç verir.',
    ],
    affirmations: [
      'Her "hayır", kendine verdiğin bir "evet".',
      'Bedenin her geçen saatte biraz daha toparlanıyor.',
      'Bugünü atlatmak için yarını düşünmen gerekmez.',
      'Tökezlemek yolun sonu değil.',
      'Dürtü bir dalga; sen o dalganın üstünde durmayı öğreniyorsun.',
      'Kendine güvenmeyi her gün biraz daha öğreniyorsun.',
    ],
    // "=" tam kelime: "bira" → "biraz", "rakı" → "rakip", "fırt" → "fırtına" engellenmesin.
    avoidWords: [
      'içki',
      'kadeh',
      '=bira',
      '=biralar',
      'şarap',
      '=rakı',
      'sarhoş',
      'kafam iyi',
      '=fırt',
      'duman',
      'nefes çek',
    ],
    info:
        'Madde kullanım bozuklukları tedavi edilebilir. Türkiye\'de Yeşilay '
        'Danışma Hattı (115) ücretsiz ve gizli destek sunar.',
    fact: 'Dünyada 400 milyon kişi alkol kullanım bozukluğuyla yaşıyor.',
    source: 'WHO, 2024',
  ),
  selfHarm(
    title: 'Kendine zarar verme',
    shortTitle: 'Kendini koruma',
    subtitle: 'Kendine zarar verme dürtüsü',
    icon: Icons.shield_outlined,
    careLevel: 10,
    checkInQuestion: 'Bugün kendini güvende tutabildin mi?',
    hardDayMessage:
        'Bunu paylaştığın için teşekkür ederiz. Yalnız değilsin. '
        'Şu an güvende hissetmiyorsan lütfen hemen 112\'yi ara.',
    calmTips: [
      'Elinde bir buz küpü tut: güçlü ama zararsız bir his.',
      'Güvendiğin birini ara ya da yanına git.',
      'Bulunduğun ortamı değiştir: başka bir odaya, insanların olduğu bir yere geç.',
      'Şu an güvende değilsen 112\'yi ara; bunu yapmak güç gerektirir.',
    ],
    affirmations: [
      'Acın gerçek ve yardımı hak ediyorsun.',
      'Bu an geçecek; sen kalacaksın.',
      'Kendini güvende tuttuğun her gün çok değerli.',
      'Bu yükü yalnız taşımak zorunda değilsin.',
      'Konuşmak yükü hafifletir.',
      'Sen önemlisin; bugün de, zor günlerde de.',
    ],
    avoidWords: ['jilet', 'kesik', 'kestim', '=kan', 'yara izi', 'bıçak', '=hap', 'intihar', 'ölmek'],
    info:
        'Kendine zarar verme çoğu zaman yoğun duygularla baş etme çabasıdır. '
        'Profesyonel destekle duygularla baş etmenin başka yolları öğrenilebilir; '
        'bir uzmanla konuşmak çok önemli.',
  ),
  anger(
    title: 'Öfke ve dürtü kontrolü',
    shortTitle: 'Öfke',
    subtitle: 'Öfke patlamaları, ani dürtüsel kararlar',
    icon: Icons.thermostat_outlined,
    careLevel: 5,
    checkInQuestion: 'Bugün öfkeni fark edip kendine bir an tanıyabildin mi?',
    hardDayMessage:
        'Öfke bazen bizi de şaşırtır. Bugün zor geçtiyse kendini '
        'yargılamadan, olanı fark etmek bile bir adım.',
    calmTips: [
      'Ortamdan birkaç dakikalığına uzaklaş; bu kaçmak değil, kendine alan açmak.',
      'Yüzünü serin suyla yıka.',
      'Nefes verişini uzat: 4 saniye al, 6 saniye ver.',
      'Hissettiğini bir kâğıda yaz, kimseye göndermeden.',
    ],
    affirmations: [
      'Öfke bir sinyal; ona nasıl yanıt vereceğini sen seçersin.',
      'Durup nefes aldığın her an, kendine verdiğin bir şans.',
      'Hata yapmak seni kötü biri yapmaz.',
      'Onarmak her zaman mümkündür.',
      'Sakinlik bir beceri; her gün biraz daha gelişir.',
      'Kendine sabırlı ol; değişim zaman alır.',
    ],
    avoidWords: ['intikam', 'kır geçir', 'patlat', '=döv', '=vur'],
    info:
        'DSM-5-TR\'de aralıklı patlayıcı bozukluk olarak tanımlanan tekrarlayan '
        'öfke patlamaları, öfke yönetimi ve bilişsel davranışçı terapiyle yönetilebilir.',
    source: 'APA, DSM-5-TR',
  ),
  trauma(
    title: 'Travma ve stres',
    shortTitle: 'Travma',
    subtitle: 'Geçmişin tetikleyicileri, ani anılar',
    icon: Icons.healing_outlined,
    careLevel: 7,
    checkInQuestion: 'Bugün kendine güvenli bir alan yaratabildin mi?',
    hardDayMessage:
        'Geçmiş bazen beklenmedik anlarda yoklar. Bugün zor geçtiyse, '
        'şu an güvende olduğunu kendine hatırlat: buradasın, şimdi.',
    calmTips: [
      'Etrafındaki beş şeyin adını yüksek sesle söyle; seni şimdiye getirir.',
      'Ayaklarını yere bastır, sırtını bir yere yasla.',
      'Sana güven veren bir nesneyi eline al.',
      'Travma odaklı terapiler (ör. EMDR, travma odaklı BDT) etkili seçeneklerdir.',
    ],
    affirmations: [
      'Şu an güvendesin.',
      'Olanlar senin suçun değildi.',
      'İyileşmek kendi hızında olur.',
      'Bugüne kadar gelmen, gücünün kanıtı.',
      'Sınır koymak kendini korumanın bir yolu.',
      'Kendine nazik olmak, yaraları sarmanın ilk adımı.',
    ],
    avoidWords: ['taciz', 'saldırı', 'şiddet', 'kaza anı', 'detaylı anlat', '=kan'],
    info:
        'Travma sonrası stres belirtileri, yaşananlara verilen anlaşılır tepkilerdir. '
        'Dünya Sağlık Örgütü travma odaklı terapileri önerir; iyileşme mümkündür.',
  ),
  sleep(
    title: 'Uyku',
    shortTitle: 'Uyku',
    subtitle: 'Uykusuzluk, düzensiz uyku',
    icon: Icons.bedtime_outlined,
    careLevel: 1,
    checkInQuestion: 'Bugün bedenine dinlenme fırsatı verebildin mi?',
    hardDayMessage:
        'Uykusuz geceler her şeyi daha zor gösterir. Bugün kendine '
        'yüklenme; dinlenmek de bir beceri.',
    calmTips: [
      'Yatmadan bir saat önce ekran ışığını azalt.',
      'Her gün aynı saatte kalkmayı dene; uyku düzeni buradan başlar.',
      'Uyuyamıyorsan yatakta zorlamak yerine kalkıp sakin bir şey yap.',
      'Yavaş nefes egzersizi bedeni dinlenmeye hazırlar.',
    ],
    affirmations: [
      'Dinlenmek bir ödül değil, bir ihtiyaç.',
      'Bu gece kusursuz olmak zorunda değil.',
      'Bedenin dinlenmeyi biliyor; ona alan aç.',
      'Yorgunluğun gerçek; kendine yumuşak davran.',
      'Her yeni gün, yeni bir başlangıç.',
      'Sessizlik de iyileştirir.',
    ],
    avoidWords: ['uyku ilacı', '=hap'],
    info:
        'Uykusuzluk ruh sağlığını derinden etkiler. Uykusuzluk için bilişsel '
        'davranışçı terapi (BDT-U) kanıtlanmış bir yöntemdir.',
  );

  const StruggleCategory({
    required String title,
    required String shortTitle,
    required String subtitle,
    required this.icon,
    required this.careLevel,
    required String checkInQuestion,
    required String hardDayMessage,
    required List<String> calmTips,
    required List<String> affirmations,
    required this.avoidWords,
    required String info,
    String? fact,
    this.source,
  }) : titleTr = title,
       shortTitleTr = shortTitle,
       subtitleTr = subtitle,
       checkInQuestionTr = checkInQuestion,
       hardDayMessageTr = hardDayMessage,
       calmTipsTr = calmTips,
       affirmationsTr = affirmations,
       infoTr = info,
       factTr = fact;

  // Türkçe kaynak metinler (çeviri anahtarları). Ekranda getter'lar kullanılır:
  // `title`, `affirmations` vb. etkin dile çevrilmiş metni döndürür.
  final String titleTr;
  final String shortTitleTr;
  final String subtitleTr;
  final String checkInQuestionTr;
  final String hardDayMessageTr;
  final List<String> calmTipsTr;
  final List<String> affirmationsTr;
  final String infoTr;
  final String? factTr;

  final IconData icon;

  /// 1-10: Yüksek değer = daha hassas dil. Birden fazla alan seçildiyse
  /// bildirim tonu en yüksek değerli kategoriden alınır.
  final int careLevel;

  /// Topluluk denetimi için (çevrilmez; ContentModerator kullanır).
  final List<String> avoidWords;

  /// Kaynak adı (APA, WHO…): özel ad, çevrilmez.
  final String? source;

  String get title => tx(titleTr);
  String get shortTitle => tx(shortTitleTr);
  String get subtitle => tx(subtitleTr);
  String get checkInQuestion => tx(checkInQuestionTr);
  String get hardDayMessage => tx(hardDayMessageTr);
  List<String> get calmTips => txList(calmTipsTr);
  List<String> get affirmations => txList(affirmationsTr);
  String get info => tx(infoTr);
  String? get fact => factTr == null ? null : tx(factTr!);
}

class StruggleType {
  const StruggleType(this.id, this.category, String label) : labelTr = label;

  /// Firestore doküman ID'si: `users/{uid}/struggles/{id}`
  final String id;
  final StruggleCategory category;

  /// Türkçe kaynak ad (çeviri anahtarı).
  final String labelTr;

  String get label => tx(labelTr);
}

const kStruggleTypes = <StruggleType>[
  StruggleType('trichotillomania', StruggleCategory.bfrb, 'Saç / kaş / kirpik yolma'),
  StruggleType('skin_picking', StruggleCategory.bfrb, 'Deri yolma'),
  StruggleType('nail_biting', StruggleCategory.bfrb, 'Tırnak yeme'),
  StruggleType('cheek_biting', StruggleCategory.bfrb, 'Dudak / yanak ısırma'),
  StruggleType('ocd_checking', StruggleCategory.ocd, 'Kontrol etme, tekrarlama'),
  StruggleType('intrusive_thoughts', StruggleCategory.ocd, 'İstenmeyen takıntılı düşünceler'),
  StruggleType('generalized_anxiety', StruggleCategory.anxiety, 'Sürekli endişe'),
  StruggleType('panic_attacks', StruggleCategory.anxiety, 'Panik atak'),
  StruggleType('social_anxiety', StruggleCategory.anxiety, 'Sosyal kaygı'),
  StruggleType('depression', StruggleCategory.mood, 'Depresif dönemler'),
  StruggleType('burnout', StruggleCategory.mood, 'Tükenmişlik'),
  StruggleType('anorexia', StruggleCategory.eating, 'Anoreksiya'),
  StruggleType('bulimia', StruggleCategory.eating, 'Bulimiya'),
  StruggleType('binge_eating', StruggleCategory.eating, 'Tıkınırcasına yeme'),
  StruggleType('body_image', StruggleCategory.eating, 'Beden algısı kaygısı'),
  StruggleType('doomscrolling', StruggleCategory.behavioral, 'Ekran / sosyal medya'),
  StruggleType('gaming', StruggleCategory.behavioral, 'Oyun'),
  StruggleType('shopping', StruggleCategory.behavioral, 'Kontrolsüz alışveriş'),
  StruggleType('gambling', StruggleCategory.behavioral, 'Kumar / bahis'),
  StruggleType('smoking', StruggleCategory.substance, 'Sigara'),
  StruggleType('vaping', StruggleCategory.substance, 'Elektronik sigara'),
  StruggleType('alcohol', StruggleCategory.substance, 'Alkol'),
  StruggleType('other_substances', StruggleCategory.substance, 'Diğer maddeler'),
  StruggleType('self_harm', StruggleCategory.selfHarm, 'Kendine zarar verme dürtüsü'),
  StruggleType('anger', StruggleCategory.anger, 'Öfke patlamaları'),
  StruggleType('impulsivity', StruggleCategory.anger, 'Ani dürtüsel kararlar'),
  StruggleType('trauma_triggers', StruggleCategory.trauma, 'Travma tetikleyicileri'),
  StruggleType('insomnia', StruggleCategory.sleep, 'Uykusuzluk'),
];

final Map<String, StruggleType> _typesById = {for (final t in kStruggleTypes) t.id: t};

StruggleType? struggleTypeById(String id) => _typesById[id];

Iterable<StruggleType> typesOf(StruggleCategory c) => kStruggleTypes.where((t) => t.category == c);

StruggleCategory? categoryByName(String? name) => name == null ? null : StruggleCategory.values.asNameMap()[name];

/// Birden fazla alan seçildiyse en hassas (careLevel en yüksek) kategori.
StruggleCategory? highestCare(Iterable<StruggleCategory> categories) {
  StruggleCategory? best;
  for (final c in categories) {
    if (best == null || c.careLevel > best.careLevel) best = c;
  }
  return best;
}
