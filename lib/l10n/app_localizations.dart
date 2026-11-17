import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('hi'),
    Locale('tr'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In tr, this message translates to:
  /// **'Haven'**
  String get appName;

  /// No description provided for @navToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get navToday;

  /// No description provided for @navCommunity.
  ///
  /// In tr, this message translates to:
  /// **'Topluluk'**
  String get navCommunity;

  /// No description provided for @navCalm.
  ///
  /// In tr, this message translates to:
  /// **'Sakinleş'**
  String get navCalm;

  /// No description provided for @navProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @welcomeTagline.
  ///
  /// In tr, this message translates to:
  /// **'Güvenli limanın.'**
  String get welcomeTagline;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yargısız, acelesiz; kendi hızında.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeFeaturePrivate.
  ///
  /// In tr, this message translates to:
  /// **'Sana özel, gizli bir günlük. Kayıtlarını yalnızca sen görürsün.'**
  String get welcomeFeaturePrivate;

  /// No description provided for @welcomeFeatureCommunity.
  ///
  /// In tr, this message translates to:
  /// **'Aynı yolda yürüyenlerden içten destek ve seri arkadaşları.'**
  String get welcomeFeatureCommunity;

  /// No description provided for @welcomeFeatureCalm.
  ///
  /// In tr, this message translates to:
  /// **'Zor anlar için nefes, topraklanma ve kısa sakinleştirici oyunlar.'**
  String get welcomeFeatureCalm;

  /// No description provided for @welcomeGoogle.
  ///
  /// In tr, this message translates to:
  /// **'Google ile kayıt ol / giriş yap'**
  String get welcomeGoogle;

  /// No description provided for @welcomeGoogleNote.
  ///
  /// In tr, this message translates to:
  /// **'Google yalnızca kimliğini doğrular; şifren Haven ile asla paylaşılmaz. Kaydın geri kalanını burada, birlikte tamamlayacağız.'**
  String get welcomeGoogleNote;

  /// No description provided for @privacyPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get privacyPolicy;

  /// No description provided for @stepProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get stepProfile;

  /// No description provided for @stepAreas.
  ///
  /// In tr, this message translates to:
  /// **'Alanların'**
  String get stepAreas;

  /// No description provided for @stepCommunity.
  ///
  /// In tr, this message translates to:
  /// **'Topluluk'**
  String get stepCommunity;

  /// No description provided for @stepConsent.
  ///
  /// In tr, this message translates to:
  /// **'Onay'**
  String get stepConsent;

  /// No description provided for @continueButton.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get continueButton;

  /// No description provided for @backButton.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get backButton;

  /// No description provided for @enterHaven.
  ///
  /// In tr, this message translates to:
  /// **'Haven\'a gir'**
  String get enterHaven;

  /// No description provided for @profileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Seni nasıl çağıralım?'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kimliğini paylaşmak zorunda değilsin. İstersen seçtiğin avatara göre sevimli bir takma ad önerelim; dilersen kendin yaz.'**
  String get profileSubtitle;

  /// No description provided for @anonymousOption.
  ///
  /// In tr, this message translates to:
  /// **'Anonim kalmak istiyorum'**
  String get anonymousOption;

  /// No description provided for @anonymousOptionDesc.
  ///
  /// In tr, this message translates to:
  /// **'Avatarına göre bir takma ad öneririz'**
  String get anonymousOptionDesc;

  /// No description provided for @namedOption.
  ///
  /// In tr, this message translates to:
  /// **'Adımı kullanmak istiyorum'**
  String get namedOption;

  /// No description provided for @namedOptionDesc.
  ///
  /// In tr, this message translates to:
  /// **'Adını ya da kısaltmasını yazabilirsin'**
  String get namedOptionDesc;

  /// No description provided for @nicknameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Takma ad'**
  String get nicknameLabel;

  /// No description provided for @nameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Adın'**
  String get nameLabel;

  /// No description provided for @chooseAvatar.
  ///
  /// In tr, this message translates to:
  /// **'Bir avatar seç'**
  String get chooseAvatar;

  /// No description provided for @suggestAnother.
  ///
  /// In tr, this message translates to:
  /// **'Başka bir öneri'**
  String get suggestAnother;

  /// No description provided for @areasTitle.
  ///
  /// In tr, this message translates to:
  /// **'Neyle mücadele ediyorsun?'**
  String get areasTitle;

  /// No description provided for @areasSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Birden fazla alan seçebilirsin. Bu bilgi yalnızca sana özel kalır; istediğin zaman değiştirebilirsin.'**
  String get areasSubtitle;

  /// No description provided for @communityTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aynı yolda yürüyenlerle buluş'**
  String get communityTitle;

  /// No description provided for @communitySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Haven topluluğunda benzer zorlukları yaşayan insanlar birbirine destek notları bırakır, serilerini görür ve cesaret verir.'**
  String get communitySubtitle;

  /// No description provided for @communityJoin.
  ///
  /// In tr, this message translates to:
  /// **'Topluluğa katılmak istiyorum'**
  String get communityJoin;

  /// No description provided for @communityJoinDesc.
  ///
  /// In tr, this message translates to:
  /// **'İstediğin zaman Profil\'den değiştirebilirsin.'**
  String get communityJoinDesc;

  /// No description provided for @consentTitle.
  ///
  /// In tr, this message translates to:
  /// **'Son bir adım'**
  String get consentTitle;

  /// No description provided for @consentSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Haven\'ın nasıl çalıştığını bilmeni istiyoruz.'**
  String get consentSubtitle;

  /// No description provided for @greetingMorning.
  ///
  /// In tr, this message translates to:
  /// **'Günaydın'**
  String get greetingMorning;

  /// No description provided for @greetingDay.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba'**
  String get greetingDay;

  /// No description provided for @greetingEvening.
  ///
  /// In tr, this message translates to:
  /// **'İyi akşamlar'**
  String get greetingEvening;

  /// No description provided for @greetingNight.
  ///
  /// In tr, this message translates to:
  /// **'İyi geceler'**
  String get greetingNight;

  /// No description provided for @dailyStreak.
  ///
  /// In tr, this message translates to:
  /// **'günlük seri'**
  String get dailyStreak;

  /// No description provided for @bestStreak.
  ///
  /// In tr, this message translates to:
  /// **'En iyi: {days} gün'**
  String bestStreak(int days);

  /// No description provided for @streakDoneToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugünü kaydettin, serin devam ediyor.'**
  String get streakDoneToday;

  /// No description provided for @streakNotDone.
  ///
  /// In tr, this message translates to:
  /// **'Bugün bir kayıt yap, serin devam etsin. Bir günü kaçırmak serini bozmaz.'**
  String get streakNotDone;

  /// No description provided for @quoteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günün sözü'**
  String get quoteTitle;

  /// No description provided for @todayRecords.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü kayıtların'**
  String get todayRecords;

  /// No description provided for @monthLights.
  ///
  /// In tr, this message translates to:
  /// **'Bu ayın ışıkları'**
  String get monthLights;

  /// No description provided for @yourProgress.
  ///
  /// In tr, this message translates to:
  /// **'İlerlemen'**
  String get yourProgress;

  /// No description provided for @myNotes.
  ///
  /// In tr, this message translates to:
  /// **'Notlarım'**
  String get myNotes;

  /// No description provided for @addNote.
  ///
  /// In tr, this message translates to:
  /// **'Not ekle'**
  String get addNote;

  /// No description provided for @noNotesYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz notun yok. Kendine bir not bırakmaya ne dersin?'**
  String get noNotesYet;

  /// No description provided for @kindDays.
  ///
  /// In tr, this message translates to:
  /// **'iyi geçen gün'**
  String get kindDays;

  /// No description provided for @currentStreak.
  ///
  /// In tr, this message translates to:
  /// **'Şu anki seri'**
  String get currentStreak;

  /// No description provided for @personalBest.
  ///
  /// In tr, this message translates to:
  /// **'Rekorun'**
  String get personalBest;

  /// No description provided for @last30Days.
  ///
  /// In tr, this message translates to:
  /// **'Son 30 gün'**
  String get last30Days;

  /// No description provided for @imStruggling.
  ///
  /// In tr, this message translates to:
  /// **'Şu an zorlanıyorum'**
  String get imStruggling;

  /// No description provided for @quickBreath.
  ///
  /// In tr, this message translates to:
  /// **'Nefes'**
  String get quickBreath;

  /// No description provided for @quickGames.
  ///
  /// In tr, this message translates to:
  /// **'Oyunlar'**
  String get quickGames;

  /// No description provided for @quickCommunity.
  ///
  /// In tr, this message translates to:
  /// **'Topluluk'**
  String get quickCommunity;

  /// No description provided for @quickSupport.
  ///
  /// In tr, this message translates to:
  /// **'Destek al'**
  String get quickSupport;

  /// No description provided for @wentWell.
  ///
  /// In tr, this message translates to:
  /// **'İyi geçti'**
  String get wentWell;

  /// No description provided for @wasHard.
  ///
  /// In tr, this message translates to:
  /// **'Zordu'**
  String get wasHard;

  /// No description provided for @comebackTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu sadece küçük bir tümsek'**
  String get comebackTitle;

  /// No description provided for @comebackBody.
  ///
  /// In tr, this message translates to:
  /// **'Geçen sefer {past} gün boyunca ne kadar güzel ilerlediğini gördük. O günler hâlâ senin. Şimdi kendi rekorunla ({best} gün) yarışıyoruz!'**
  String comebackBody(int past, int best);

  /// No description provided for @raceTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kendi rekorunla yarışıyorsun'**
  String get raceTitle;

  /// No description provided for @raceBody.
  ///
  /// In tr, this message translates to:
  /// **'Rekoruna {left} gün kaldı. Acele yok; kendi hızında.'**
  String raceBody(int left);

  /// No description provided for @newRecordTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni rekor!'**
  String get newRecordTitle;

  /// No description provided for @newRecordBody.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün! Kendi rekorunu aştın. Kendinle gurur duyabilirsin.'**
  String newRecordBody(int days);

  /// No description provided for @calmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sakinleş'**
  String get calmTitle;

  /// No description provided for @calmIntro.
  ///
  /// In tr, this message translates to:
  /// **'Burası senin güvenli alanın. Dürtü ya da kaygı geldiğinde birkaç dakikalık bir mola, dalganın geçmesine yardım eder.'**
  String get calmIntro;

  /// No description provided for @emergencyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Acil destek'**
  String get emergencyTitle;

  /// No description provided for @emergencyBody.
  ///
  /// In tr, this message translates to:
  /// **'Kendini güvende hissetmiyorsan hemen ara. Bunu yapmak güç gerektirir.'**
  String get emergencyBody;

  /// No description provided for @breathingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Nefes al · tut · ver'**
  String get breathingTitle;

  /// No description provided for @breathingDesc.
  ///
  /// In tr, this message translates to:
  /// **'4 saniye al, 4 saniye tut, 6 saniye ver'**
  String get breathingDesc;

  /// No description provided for @breatheIn.
  ///
  /// In tr, this message translates to:
  /// **'Nefes al'**
  String get breatheIn;

  /// No description provided for @hold.
  ///
  /// In tr, this message translates to:
  /// **'Tut'**
  String get hold;

  /// No description provided for @breatheOut.
  ///
  /// In tr, this message translates to:
  /// **'Yavaşça ver'**
  String get breatheOut;

  /// No description provided for @gameBubbles.
  ///
  /// In tr, this message translates to:
  /// **'Baloncuk patlat'**
  String get gameBubbles;

  /// No description provided for @gameBubblesDesc.
  ///
  /// In tr, this message translates to:
  /// **'Ellerine güvenli bir uğraş'**
  String get gameBubblesDesc;

  /// No description provided for @gameColors.
  ///
  /// In tr, this message translates to:
  /// **'Renk eşleştir'**
  String get gameColors;

  /// No description provided for @gameColorsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Renkleri eşleştir, zihnin dinlensin'**
  String get gameColorsDesc;

  /// No description provided for @gameMemory.
  ///
  /// In tr, this message translates to:
  /// **'Hafıza kartları'**
  String get gameMemory;

  /// No description provided for @gameMemoryDesc.
  ///
  /// In tr, this message translates to:
  /// **'Zihnini nazikçe meşgul et'**
  String get gameMemoryDesc;

  /// No description provided for @groundingTitle.
  ///
  /// In tr, this message translates to:
  /// **'5-4-3-2-1 topraklanma'**
  String get groundingTitle;

  /// No description provided for @groundingDesc.
  ///
  /// In tr, this message translates to:
  /// **'Şimdiye dön'**
  String get groundingDesc;

  /// No description provided for @supportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Destek al'**
  String get supportTitle;

  /// No description provided for @supportDesc.
  ///
  /// In tr, this message translates to:
  /// **'Kriz hatları ve uzman desteği'**
  String get supportDesc;

  /// No description provided for @notificationsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notificationsTitle;

  /// No description provided for @markAllRead.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü okundu say'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bildirim yok.'**
  String get noNotifications;

  /// No description provided for @giftsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hediyelerim'**
  String get giftsTitle;

  /// No description provided for @giftsIntro.
  ///
  /// In tr, this message translates to:
  /// **'Kendine her gün geri döndükçe yeni hediyeler açılır. Dilersen kısa bir reklamla da açabilirsin; tamamen isteğe bağlı.'**
  String get giftsIntro;

  /// No description provided for @giftUnlockAt.
  ///
  /// In tr, this message translates to:
  /// **'{days} günlük seride açılır'**
  String giftUnlockAt(int days);

  /// No description provided for @giftDaysLeft.
  ///
  /// In tr, this message translates to:
  /// **'{left} gün kaldı'**
  String giftDaysLeft(int left);

  /// No description provided for @themes.
  ///
  /// In tr, this message translates to:
  /// **'Temalar'**
  String get themes;

  /// No description provided for @avatars.
  ///
  /// In tr, this message translates to:
  /// **'Avatarlar'**
  String get avatars;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Cihaz dili'**
  String get systemLanguage;

  /// No description provided for @signOut.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabımı ve tüm verilerimi sil'**
  String get deleteAccount;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @daysCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} gün'**
  String daysCount(int count);

  /// No description provided for @recordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Rekor: {count} gün'**
  String recordLabel(int count);

  /// No description provided for @journeyStart.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuğun bugün başlayabilir.'**
  String get journeyStart;

  /// No description provided for @recordReached.
  ///
  /// In tr, this message translates to:
  /// **'Rekoruna ulaştın! Yarın yeni bir rekor olabilir.'**
  String get recordReached;

  /// No description provided for @comebackShort.
  ///
  /// In tr, this message translates to:
  /// **'Rekorun {best} gün. Yeniden başlamak için güzel bir gün.'**
  String comebackShort(int best);

  /// No description provided for @seeAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get seeAll;

  /// No description provided for @beginning.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get beginning;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'hi', 'tr', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'hi':
      return AppLocalizationsHi();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
