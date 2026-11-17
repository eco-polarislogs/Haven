// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Haven';

  @override
  String get navToday => 'Bugün';

  @override
  String get navCommunity => 'Topluluk';

  @override
  String get navCalm => 'Sakinleş';

  @override
  String get navProfile => 'Profil';

  @override
  String get welcomeTagline => 'Güvenli limanın.';

  @override
  String get welcomeSubtitle => 'Yargısız, acelesiz; kendi hızında.';

  @override
  String get welcomeFeaturePrivate =>
      'Sana özel, gizli bir günlük. Kayıtlarını yalnızca sen görürsün.';

  @override
  String get welcomeFeatureCommunity =>
      'Aynı yolda yürüyenlerden içten destek ve seri arkadaşları.';

  @override
  String get welcomeFeatureCalm =>
      'Zor anlar için nefes, topraklanma ve kısa sakinleştirici oyunlar.';

  @override
  String get welcomeGoogle => 'Google ile kayıt ol / giriş yap';

  @override
  String get welcomeGoogleNote =>
      'Google yalnızca kimliğini doğrular; şifren Haven ile asla paylaşılmaz. Kaydın geri kalanını burada, birlikte tamamlayacağız.';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get stepProfile => 'Profil';

  @override
  String get stepAreas => 'Alanların';

  @override
  String get stepCommunity => 'Topluluk';

  @override
  String get stepConsent => 'Onay';

  @override
  String get continueButton => 'Devam';

  @override
  String get backButton => 'Geri';

  @override
  String get enterHaven => 'Haven\'a gir';

  @override
  String get profileTitle => 'Seni nasıl çağıralım?';

  @override
  String get profileSubtitle =>
      'Kimliğini paylaşmak zorunda değilsin. İstersen seçtiğin avatara göre sevimli bir takma ad önerelim; dilersen kendin yaz.';

  @override
  String get anonymousOption => 'Anonim kalmak istiyorum';

  @override
  String get anonymousOptionDesc => 'Avatarına göre bir takma ad öneririz';

  @override
  String get namedOption => 'Adımı kullanmak istiyorum';

  @override
  String get namedOptionDesc => 'Adını ya da kısaltmasını yazabilirsin';

  @override
  String get nicknameLabel => 'Takma ad';

  @override
  String get nameLabel => 'Adın';

  @override
  String get chooseAvatar => 'Bir avatar seç';

  @override
  String get suggestAnother => 'Başka bir öneri';

  @override
  String get areasTitle => 'Neyle mücadele ediyorsun?';

  @override
  String get areasSubtitle =>
      'Birden fazla alan seçebilirsin. Bu bilgi yalnızca sana özel kalır; istediğin zaman değiştirebilirsin.';

  @override
  String get communityTitle => 'Aynı yolda yürüyenlerle buluş';

  @override
  String get communitySubtitle =>
      'Haven topluluğunda benzer zorlukları yaşayan insanlar birbirine destek notları bırakır, serilerini görür ve cesaret verir.';

  @override
  String get communityJoin => 'Topluluğa katılmak istiyorum';

  @override
  String get communityJoinDesc =>
      'İstediğin zaman Profil\'den değiştirebilirsin.';

  @override
  String get consentTitle => 'Son bir adım';

  @override
  String get consentSubtitle =>
      'Haven\'ın nasıl çalıştığını bilmeni istiyoruz.';

  @override
  String get greetingMorning => 'Günaydın';

  @override
  String get greetingDay => 'Merhaba';

  @override
  String get greetingEvening => 'İyi akşamlar';

  @override
  String get greetingNight => 'İyi geceler';

  @override
  String get dailyStreak => 'günlük seri';

  @override
  String bestStreak(int days) {
    return 'En iyi: $days gün';
  }

  @override
  String get streakDoneToday => 'Bugünü kaydettin, serin devam ediyor.';

  @override
  String get streakNotDone =>
      'Bugün bir kayıt yap, serin devam etsin. Bir günü kaçırmak serini bozmaz.';

  @override
  String get quoteTitle => 'Günün sözü';

  @override
  String get todayRecords => 'Bugünkü kayıtların';

  @override
  String get monthLights => 'Bu ayın ışıkları';

  @override
  String get yourProgress => 'İlerlemen';

  @override
  String get myNotes => 'Notlarım';

  @override
  String get addNote => 'Not ekle';

  @override
  String get noNotesYet =>
      'Henüz notun yok. Kendine bir not bırakmaya ne dersin?';

  @override
  String get kindDays => 'iyi geçen gün';

  @override
  String get currentStreak => 'Şu anki seri';

  @override
  String get personalBest => 'Rekorun';

  @override
  String get last30Days => 'Son 30 gün';

  @override
  String get imStruggling => 'Şu an zorlanıyorum';

  @override
  String get quickBreath => 'Nefes';

  @override
  String get quickGames => 'Oyunlar';

  @override
  String get quickCommunity => 'Topluluk';

  @override
  String get quickSupport => 'Destek al';

  @override
  String get wentWell => 'İyi geçti';

  @override
  String get wasHard => 'Zordu';

  @override
  String get comebackTitle => 'Bu sadece küçük bir tümsek';

  @override
  String comebackBody(int past, int best) {
    return 'Geçen sefer $past gün boyunca ne kadar güzel ilerlediğini gördük. O günler hâlâ senin. Şimdi kendi rekorunla ($best gün) yarışıyoruz!';
  }

  @override
  String get raceTitle => 'Kendi rekorunla yarışıyorsun';

  @override
  String raceBody(int left) {
    return 'Rekoruna $left gün kaldı. Acele yok; kendi hızında.';
  }

  @override
  String get newRecordTitle => 'Yeni rekor!';

  @override
  String newRecordBody(int days) {
    return '$days gün! Kendi rekorunu aştın. Kendinle gurur duyabilirsin.';
  }

  @override
  String get calmTitle => 'Sakinleş';

  @override
  String get calmIntro =>
      'Burası senin güvenli alanın. Dürtü ya da kaygı geldiğinde birkaç dakikalık bir mola, dalganın geçmesine yardım eder.';

  @override
  String get emergencyTitle => 'Acil destek';

  @override
  String get emergencyBody =>
      'Kendini güvende hissetmiyorsan hemen ara. Bunu yapmak güç gerektirir.';

  @override
  String get breathingTitle => 'Nefes al · tut · ver';

  @override
  String get breathingDesc => '4 saniye al, 4 saniye tut, 6 saniye ver';

  @override
  String get breatheIn => 'Nefes al';

  @override
  String get hold => 'Tut';

  @override
  String get breatheOut => 'Yavaşça ver';

  @override
  String get gameBubbles => 'Baloncuk patlat';

  @override
  String get gameBubblesDesc => 'Ellerine güvenli bir uğraş';

  @override
  String get gameColors => 'Renk eşleştir';

  @override
  String get gameColorsDesc => 'Renkleri eşleştir, zihnin dinlensin';

  @override
  String get gameMemory => 'Hafıza kartları';

  @override
  String get gameMemoryDesc => 'Zihnini nazikçe meşgul et';

  @override
  String get groundingTitle => '5-4-3-2-1 topraklanma';

  @override
  String get groundingDesc => 'Şimdiye dön';

  @override
  String get supportTitle => 'Destek al';

  @override
  String get supportDesc => 'Kriz hatları ve uzman desteği';

  @override
  String get notificationsTitle => 'Bildirimler';

  @override
  String get markAllRead => 'Tümünü okundu say';

  @override
  String get noNotifications => 'Henüz bildirim yok.';

  @override
  String get giftsTitle => 'Hediyelerim';

  @override
  String get giftsIntro =>
      'Kendine her gün geri döndükçe yeni hediyeler açılır. Dilersen kısa bir reklamla da açabilirsin; tamamen isteğe bağlı.';

  @override
  String giftUnlockAt(int days) {
    return '$days günlük seride açılır';
  }

  @override
  String giftDaysLeft(int left) {
    return '$left gün kaldı';
  }

  @override
  String get themes => 'Temalar';

  @override
  String get avatars => 'Avatarlar';

  @override
  String get language => 'Dil';

  @override
  String get systemLanguage => 'Cihaz dili';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get deleteAccount => 'Hesabımı ve tüm verilerimi sil';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get close => 'Kapat';

  @override
  String daysCount(int count) {
    return '$count gün';
  }

  @override
  String recordLabel(int count) {
    return 'Rekor: $count gün';
  }

  @override
  String get journeyStart => 'Yolculuğun bugün başlayabilir.';

  @override
  String get recordReached =>
      'Rekoruna ulaştın! Yarın yeni bir rekor olabilir.';

  @override
  String comebackShort(int best) {
    return 'Rekorun $best gün. Yeniden başlamak için güzel bir gün.';
  }

  @override
  String get seeAll => 'Tümü';

  @override
  String get beginning => 'Başlangıç';
}
