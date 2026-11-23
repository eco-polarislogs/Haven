import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/tx.dart';

/// Kaynak: site/gizlilik.html → `firebase deploy --only hosting`
/// Play Console'a da aynı link ve `/hesap-silme` linki girilir.
const kPrivacyPolicyUrl = 'https://ecren-7050e.web.app/gizlilik';

// ------------------------------------------------------------ kriz & destek

class SupportLine {
  const SupportLine({required String name, required this.number, required String description})
    : nameTr = name,
      descriptionTr = description;
  final String nameTr;
  final String number;
  final String descriptionTr;
  String get name => tx(nameTr);
  String get description => tx(descriptionTr);
}

/// Türkiye için. Yayından önce numaraları resmi kaynaklardan tekrar doğrula.
const kSupportLines = <SupportLine>[
  SupportLine(
    name: 'Acil Çağrı Merkezi',
    number: '112',
    description: 'Kendini güvende hissetmiyorsan. 7/24, ücretsiz.',
  ),
  SupportLine(
    name: 'Yeşilay Danışma Hattı (YEDAM)',
    number: '115',
    description:
        'Sigara, alkol, madde, kumar ve teknoloji bağımlılığı için '
        'ücretsiz ve gizli destek.',
  ),
];

class HelpResource {
  const HelpResource(this.icon, String title, String description) : titleTr = title, descriptionTr = description;
  final IconData icon;
  final String titleTr;
  final String descriptionTr;
  String get title => tx(titleTr);
  String get description => tx(descriptionTr);
}

/// "Profesyonel destek nasıl alınır?" (Türkiye).
const kHelpResources = <HelpResource>[
  HelpResource(
    Icons.local_hospital_outlined,
    'Aile hekimin',
    'Seni ücretsiz olarak bir psikiyatri polikliniğine yönlendirebilir.',
  ),
  HelpResource(
    Icons.event_available_outlined,
    'MHRS (182 veya mhrs.gov.tr)',
    'Devlet hastanelerinin psikiyatri bölümlerinden randevu alabilirsin.',
  ),
  HelpResource(
    Icons.diversity_3_outlined,
    'Toplum Ruh Sağlığı Merkezleri',
    'Birçok ilde ücretsiz ruh sağlığı desteği sunan kamu merkezleri.',
  ),
  HelpResource(
    Icons.school_outlined,
    'Üniversiten',
    'Öğrenciysen üniversitenin psikolojik danışmanlık merkezinden ücretsiz destek alabilirsin.',
  ),
];

const kGlobalFact = 'Dünyada 1 milyardan fazla insan bir ruh sağlığı sorunuyla yaşıyor. Yalnız değilsin.';
const kGlobalFactSource = 'WHO, 2025';

// ------------------------------------------------------------ günün sözleri

/// Her kullanıcıya uygun, genel sözler.
const kGeneralAffirmations = <String>[
  'İyileşme düz bir çizgi değil; dalgalı bir yol. Her dalga seni yine de ileri taşır.',
  'Bugün yalnızca nefes alabildiysen, bu da yeterli.',
  'Kendine, en sevdiğin arkadaşına davrandığın gibi davran.',
  'Tökezlemek, yoldan çıktığın anlamına gelmez.',
  'Yavaş ilerlemek de ilerlemektir.',
  'Zor günler, iyi günlerin değerini azaltmaz.',
  'Bugün kendine bir iyilik yap: kendini yargılamadan dinle.',
  'Her sabah yeni bir başlangıç hakkın var.',
  'Duygular geçicidir; sen kalıcısın.',
  'Fırtına ne kadar sürerse sürsün, liman hep orada.',
  'Yardım istemek, kendine verdiğin en güçlü sözlerden biri.',
  'Bugün attığın küçük adım, yarının yolunu aydınlatır.',
  'Kusursuz olmak zorunda değilsin; burada olman yeterli.',
  'Kendine sabırlı ol; büyüme sessizce olur.',
  'Dinlenmek, vazgeçmek değildir.',
  'Sen bir sorun değilsin; bir sorunla mücadele eden değerli bir insansın.',
  'Karanlıkta bile bir fener ışığı yolu gösterir.',
  'Bugünü atlatman için yarını çözmen gerekmez.',
  'Hissettiğin her şey anlaşılmayı hak ediyor.',
  'Bir adım geri gitmek, yolu kaybettiğin anlamına gelmez.',
];

String noteOfTheDay(List<String> pool, DateTime day, {int offset = 0}) {
  if (pool.isEmpty) return tx(kGeneralAffirmations.first);
  final dayOfYear = day.difference(DateTime(day.year)).inDays;
  return pool[(dayOfYear + offset) % pool.length];
}

// ------------------------------------------------------------ topluluk

/// Arkadaşlara gönderilebilen HAZIR cesaret mesajları. Serbest metin yok:
/// böylece arkadaşlık özelliği zorbalığa dönüşemez.
/// functions/inbox_messages.js içindeki liste ile AYNI sırada olmalı.
const kKudosMessages = <String>[
  'Seni düşünüyorum, yanındayım. 🤝',
  'Bugün de buradasın, bu çok değerli. 💙',
  'Küçük adımlar da sayılır. Devam!',
  'Zor bir günse, yalnız değilsin.',
  'Serin harika gidiyor, gurur duyuyorum. 🔥',
  'Nefes al, ben buradayım.',
  'Kendine nazik olmayı unutma.',
  'Seninle aynı yolda yürüdüğüm için mutluyum.',
];

/// Not yazarken ilham olacak başlangıçlar.
const kNotePrompts = <String>[
  'Bugün kendim için yaptığım küçük bir şey: ',
  'Zor anlarda bana iyi gelen: ',
  'Yeni başlayan birine söylemek istediğim: ',
  'Bugün fark ettiğim güzel bir şey: ',
];

/// Sevimli avatarlar (çoğu hayvan). Gerçek fotoğraf YOK: tetiklenmeyi ve
/// gizlilik ihlallerini önlemek için. Her birinin varsayılan bir adı var
/// ("Sevimli Kurbağa" gibi); kullanıcı isterse değiştirir.
/// Adlarda bedene/ağırlığa dair sıfat YOK (yeme bozukluğu tetikleyicisi olmasın).
class AvatarOption {
  const AvatarOption(this.emoji, String name, String nick, this.color, {this.unlockStreak = 0})
    : nameTr = name,
      nickTr = nick;
  final String emoji;
  final String nameTr;

  /// Varsayılan takma ad (Türkçe kaynak).
  final String nickTr;

  String get name => tx(nameTr);

  /// Varsayılan takma ad, etkin dilde ("Cute Frog", "Rana Simpática"…).
  String get nick => tx(nickTr);
  final Color color;

  /// 0 = ücretsiz; N = en iyi serin N güne ulaşınca açılır.
  final int unlockStreak;
  bool get isGift => unlockStreak > 0;
}

const kAvatars = <AvatarOption>[
  // ücretsiz
  AvatarOption('🐰', 'Tavşan', 'Neşeli Tavşan', Color(0xFFB98B6E)),
  AvatarOption('🐼', 'Panda', 'Sevimli Panda', Color(0xFF6F7F86)),
  AvatarOption('🐻', 'Ayı', 'Sıcacık Ayı', Color(0xFF9A7552)),
  AvatarOption('🐦', 'Kuş', 'Cesur Kuş', Color(0xFF5B7DB1)),
  AvatarOption('🐸', 'Kurbağa', 'Sevimli Kurbağa', Color(0xFF5F8F5A)),
  AvatarOption('🐱', 'Kedi', 'Sakin Kedi', Color(0xFFB9813A)),
  AvatarOption('🐶', 'Köpek', 'Sadık Köpek', Color(0xFF8A6E5A)),
  AvatarOption('🐨', 'Koala', 'Uykucu Koala', Color(0xFF7D8A8F)),
  AvatarOption('🐹', 'Hamster', 'Minik Hamster', Color(0xFFC09060)),
  AvatarOption('🦔', 'Kirpi', 'Utangaç Kirpi', Color(0xFF8C7660)),
  AvatarOption('🐧', 'Penguen', 'Dengeli Penguen', Color(0xFF4B5A7A)),
  AvatarOption('🐢', 'Kaplumbağa', 'Sabırlı Kaplumbağa', Color(0xFF4E8063)),
  AvatarOption('🦊', 'Tilki', 'Meraklı Tilki', Color(0xFFC0723F)),
  AvatarOption('🦉', 'Baykuş', 'Bilge Baykuş', Color(0xFF7A6A58)),
  AvatarOption('🐙', 'Ahtapot', 'Şefkatli Ahtapot', Color(0xFFA0607A)),
  AvatarOption('🐝', 'Arı', 'Çalışkan Arı', Color(0xFFC9A03A)),
  AvatarOption('⭐', 'Yıldız', 'Parlak Yıldız', Color(0xFFC9A03A)),
  AvatarOption('☁️', 'Bulut', 'Yumuşacık Bulut', Color(0xFF7F95B0)),
  // hediye avatarlar (en iyi seriyle ya da isteğe bağlı reklamla açılır)
  AvatarOption('🦁', 'Aslan', 'Yürekli Aslan', Color(0xFFC08A3E), unlockStreak: 3),
  AvatarOption('🐯', 'Kaplan', 'Güçlü Kaplan', Color(0xFFC9762F), unlockStreak: 5),
  AvatarOption('🐬', 'Yunus', 'Oyuncu Yunus', Color(0xFF3E8E9B), unlockStreak: 7),
  AvatarOption('🐘', 'Fil', 'Koca Yürekli Fil', Color(0xFF7D8590), unlockStreak: 10),
  AvatarOption('🦒', 'Zürafa', 'Hayalperest Zürafa', Color(0xFFC0904A), unlockStreak: 14),
  AvatarOption('🦦', 'Su Samuru', 'Neşeli Su Samuru', Color(0xFF8A6A50), unlockStreak: 21),
  AvatarOption('🐿️', 'Sincap', 'Telaşsız Sincap', Color(0xFFA86A3E), unlockStreak: 30),
  AvatarOption('🌙', 'Ay', 'Huzurlu Ay', Color(0xFF5B6299), unlockStreak: 40),
  AvatarOption('🚀', 'Roket', 'Cesur Roket', Color(0xFF5C6E99), unlockStreak: 50),
  AvatarOption('🦄', 'Tekboynuz', 'Büyülü Tekboynuz', Color(0xFF8A6AA8), unlockStreak: 60),
  AvatarOption('🐲', 'Ejderha', 'Koruyucu Ejderha', Color(0xFF4E8063), unlockStreak: 75),
  AvatarOption('🐋', 'Balina', 'Engin Balina', Color(0xFF2F7C93), unlockStreak: 100),
];

AvatarOption avatarAt(int index) => kAvatars[index.abs() % kAvatars.length];

/// Kayıtta seçilebilen ücretsiz avatar sayısı.
const kFreeAvatarCount = 18;

/// Avatarın varsayılan adı: panda → "Sevimli Panda".
String defaultNickname(int avatar) => avatarAt(avatar).nick;

const kNickAdjectives = [
  'Sevimli',
  'Cesur',
  'Sakin',
  'Usul',
  'Sabırlı',
  'Neşeli',
  'Dingin',
  'Umutlu',
  'Meraklı',
  'Kararlı',
  'Şefkatli',
  'Bilge',
];

/// Zar düğmesi için alternatif öneri: aynı avatar, farklı sıfat. Kelime
/// sırası dile göre şablondan gelir (es: "Panda Sabio", zh: "睿智的熊猫").
String suggestNickname({int? avatar, Random? random}) {
  final r = random ?? Random();
  final a = avatarAt(avatar ?? r.nextInt(kAvatars.length));
  final adj = tx(kNickAdjectives[r.nextInt(kNickAdjectives.length)]);
  return tx('{adj} {animal}', {'adj': adj, 'animal': a.name});
}

const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/// Arkadaş kodu: karışabilecek karakterler (0/O, 1/I) yok.
String generateFriendCode([Random? random]) {
  final r = random ?? Random.secure();
  return List.generate(6, (_) => _codeChars[r.nextInt(_codeChars.length)]).join();
}

// ------------------------------------------------------------ destek talepleri

/// Uygulama sürümü (destek taleplerine eklenir; pubspec.yaml ile aynı tutulmalı).
const kAppVersion = '3.2.1';

/// Destek ve öneri taleplerini okuyup yanıtlayabilen geliştirici hesapları
/// (Firebase Auth uid). firestore.rules → developerUids() ile AYNI olmalı.
/// Yeni bir geliştirici eklemek için uid'yi iki yere de ekle ve kuralları yayınla.
const kDeveloperUids = <String>{'45q7AAJ06TOi49mMyHEPdLMDPi82'};
