// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Haven';

  @override
  String get navToday => 'Today';

  @override
  String get navCommunity => 'Community';

  @override
  String get navCalm => 'Calm';

  @override
  String get navProfile => 'Profile';

  @override
  String get welcomeTagline => 'Your safe harbor.';

  @override
  String get welcomeSubtitle => 'No judgment, no rush — at your own pace.';

  @override
  String get welcomeFeaturePrivate =>
      'A private journal just for you. Only you can see your entries.';

  @override
  String get welcomeFeatureCommunity =>
      'Gentle support and streak friends from people walking the same path.';

  @override
  String get welcomeFeatureCalm =>
      'Breathing, grounding and short calming games for hard moments.';

  @override
  String get welcomeGoogle => 'Sign up / sign in with Google';

  @override
  String get welcomeGoogleNote =>
      'Google only verifies who you are; your password is never shared with Haven. We\'ll finish the rest of your sign-up here, together.';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get stepProfile => 'Profile';

  @override
  String get stepAreas => 'Your areas';

  @override
  String get stepCommunity => 'Community';

  @override
  String get stepConsent => 'Consent';

  @override
  String get continueButton => 'Continue';

  @override
  String get backButton => 'Back';

  @override
  String get enterHaven => 'Enter Haven';

  @override
  String get profileTitle => 'What should we call you?';

  @override
  String get profileSubtitle =>
      'You don\'t have to share who you are. We can suggest a cute nickname based on your avatar, or you can write your own.';

  @override
  String get anonymousOption => 'I\'d like to stay anonymous';

  @override
  String get anonymousOptionDesc =>
      'We\'ll suggest a nickname from your avatar';

  @override
  String get namedOption => 'I\'d like to use my name';

  @override
  String get namedOptionDesc => 'You can write your name or initials';

  @override
  String get nicknameLabel => 'Nickname';

  @override
  String get nameLabel => 'Your name';

  @override
  String get chooseAvatar => 'Choose an avatar';

  @override
  String get suggestAnother => 'Another suggestion';

  @override
  String get areasTitle => 'What are you working through?';

  @override
  String get areasSubtitle =>
      'You can choose more than one. This stays private to you and you can change it anytime.';

  @override
  String get communityTitle => 'Meet people on the same path';

  @override
  String get communitySubtitle =>
      'In the Haven community, people facing similar challenges leave each other kind notes, see each other\'s streaks and cheer each other on.';

  @override
  String get communityJoin => 'I\'d like to join the community';

  @override
  String get communityJoinDesc => 'You can change this anytime in Profile.';

  @override
  String get consentTitle => 'One last step';

  @override
  String get consentSubtitle => 'We want you to know how Haven works.';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingDay => 'Hello';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingNight => 'Good night';

  @override
  String get dailyStreak => 'day streak';

  @override
  String bestStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Best: $_temp0';
  }

  @override
  String get streakDoneToday => 'You checked in today — your streak continues.';

  @override
  String get streakNotDone =>
      'Check in today to keep your streak. Missing one day won\'t break it.';

  @override
  String get quoteTitle => 'Quote of the day';

  @override
  String get todayRecords => 'Today\'s check-ins';

  @override
  String get monthLights => 'This month\'s lights';

  @override
  String get yourProgress => 'Your progress';

  @override
  String get myNotes => 'My notes';

  @override
  String get addNote => 'Add note';

  @override
  String get noNotesYet =>
      'No notes yet. How about leaving yourself a kind note?';

  @override
  String get kindDays => 'good days';

  @override
  String get currentStreak => 'Current streak';

  @override
  String get personalBest => 'Your record';

  @override
  String get last30Days => 'Last 30 days';

  @override
  String get imStruggling => 'I\'m struggling right now';

  @override
  String get quickBreath => 'Breathe';

  @override
  String get quickGames => 'Games';

  @override
  String get quickCommunity => 'Community';

  @override
  String get quickSupport => 'Get support';

  @override
  String get wentWell => 'It went well';

  @override
  String get wasHard => 'It was hard';

  @override
  String get comebackTitle => 'This is just a small bump';

  @override
  String comebackBody(int past, int best) {
    String _temp0 = intl.Intl.pluralLogic(
      past,
      locale: localeName,
      other: '$past days',
      one: '1 day',
    );
    return 'Last time you made beautiful progress for $_temp0. Those days are still yours. Now we\'re racing your own record ($best days)!';
  }

  @override
  String get raceTitle => 'Racing your own record';

  @override
  String raceBody(int left) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: '$left days',
      one: '1 day',
    );
    return '$_temp0 to your record. No rush — at your own pace.';
  }

  @override
  String get newRecordTitle => 'New record!';

  @override
  String newRecordBody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0! You beat your own record. Be proud of yourself.';
  }

  @override
  String get calmTitle => 'Calm';

  @override
  String get calmIntro =>
      'This is your safe space. When an urge or anxiety comes, a few minutes\' break helps the wave pass.';

  @override
  String get emergencyTitle => 'Emergency support';

  @override
  String get emergencyBody =>
      'If you don\'t feel safe, call now. Reaching out takes strength.';

  @override
  String get breathingTitle => 'Breathe in · hold · out';

  @override
  String get breathingDesc => 'In for 4, hold for 4, out for 6';

  @override
  String get breatheIn => 'Breathe in';

  @override
  String get hold => 'Hold';

  @override
  String get breatheOut => 'Slowly out';

  @override
  String get gameBubbles => 'Pop bubbles';

  @override
  String get gameBubblesDesc => 'A safe task for your hands';

  @override
  String get gameColors => 'Match colors';

  @override
  String get gameColorsDesc => 'Match colors, rest your mind';

  @override
  String get gameMemory => 'Memory cards';

  @override
  String get gameMemoryDesc => 'Calmly occupy your mind';

  @override
  String get groundingTitle => '5-4-3-2-1 grounding';

  @override
  String get groundingDesc => 'Come back to now';

  @override
  String get supportTitle => 'Get support';

  @override
  String get supportDesc => 'Crisis lines and professional help';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get noNotifications => 'No notifications yet.';

  @override
  String get giftsTitle => 'My gifts';

  @override
  String get giftsIntro =>
      'New gifts unlock as you keep coming back to yourself. You can also unlock them with a short ad — completely optional.';

  @override
  String giftUnlockAt(int days) {
    return 'Unlocks at a $days-day streak';
  }

  @override
  String giftDaysLeft(int left) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: '$left days',
      one: '1 day',
    );
    return '$_temp0 to go';
  }

  @override
  String get themes => 'Themes';

  @override
  String get avatars => 'Avatars';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'Device language';

  @override
  String get signOut => 'Sign out';

  @override
  String get deleteAccount => 'Delete my account and all my data';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String recordLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return 'Record: $_temp0';
  }

  @override
  String get journeyStart => 'Your journey can begin today.';

  @override
  String get recordReached =>
      'You reached your record! Tomorrow could be a new one.';

  @override
  String comebackShort(int best) {
    String _temp0 = intl.Intl.pluralLogic(
      best,
      locale: localeName,
      other: '$best days',
      one: '1 day',
    );
    return 'Your record is $_temp0. A good day to begin again.';
  }

  @override
  String get seeAll => 'All';

  @override
  String get beginning => 'Beginning';
}
