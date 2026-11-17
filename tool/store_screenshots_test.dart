// Google Play ekran görüntüleri: uygulamanın GERÇEK ekranları, örnek verilerle.
//
// Normal `flutter test` bunu çalıştırmaz (test/ dışında). Üretmek için:
//   flutter test tool/store_screenshots_test.dart
// Çıktı: store/screenshots/{tr,en}/*.png (1080x1920, Play'in 9:16 sınırına uygun).
//
// Yazı tipleri: Roboto ve Material simgeleri Flutter SDK'sının içinden yüklenir.
// Avatar emojileri ve "→" gibi semboller için telefondaki yedek yazı tiplerinin
// yerine bir emoji ve bir sembol yazı tipi verilir (Windows'ta:
// C:/Windows/Fonts/seguiemj.ttf ve seguisym.ttf).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:haven/core/constants/struggle_catalog.dart';
import 'package:haven/core/theme/app_theme.dart' show buildTheme;
import 'package:haven/core/utils/day_key.dart';
import 'package:haven/core/utils/streak.dart';
import 'package:haven/data/models/app_user.dart';
import 'package:haven/data/models/community.dart';
import 'package:haven/data/models/journal_entry.dart';
import 'package:haven/data/models/month_log.dart';
import 'package:haven/data/models/struggle.dart';
import 'package:haven/data/models/support_ticket.dart';
import 'package:haven/data/services/analytics_service.dart';
import 'package:haven/data/services/community_repository.dart';
import 'package:haven/data/services/haven_repository.dart';
import 'package:haven/data/services/support_repository.dart';
import 'package:haven/features/notifications/notifications_screen.dart';
import 'package:haven/features/shell/home_shell.dart';
import 'package:haven/features/support/feedback_screen.dart';
import 'package:haven/l10n/app_localizations.dart';
import 'package:haven/l10n/tx.dart';
import 'package:haven/providers.dart';

const _emojiFont = String.fromEnvironment('EMOJI_FONT', defaultValue: 'C:/Windows/Fonts/seguiemj.ttf');
const _symbolFont = String.fromEnvironment('SYMBOL_FONT', defaultValue: 'C:/Windows/Fonts/seguisym.ttf');
const _size = Size(1080, 1920);
const _dpr = 2.625; // 411 x 731 dp: yaygın bir telefon genişliği

/// Ekranlar Firebase'e yalnızca dokunulunca gider; çizim sırasında hiçbir
/// çağrı yapılmaz. Yine de yapılırsa sessizce geçmesin diye hata verir.
class _NoFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError('Ekran görüntüsünde veritabanı yok');
}

class _NoAnalytics implements FirebaseAnalytics {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError('Ekran görüntüsünde analiz yok');
}

/// Bir dil için örnek içerik. Kişiler sevimli hayvan avatarlı takma adlardır
/// (uygulamada gerçek ad yoktur); metinler gerçek kullanıcı paylaşımı değildir.
class _Demo {
  _Demo(this.lang);
  final String lang;
  bool get tr => lang == 'tr';

  final now = DateTime.now();
  String get today => dayKey(now);
  String get yesterday => dayKey(now.subtract(const Duration(days: 1)));

  late final bfrb = typesOf(StruggleCategory.bfrb).first;
  late final anxiety = typesOf(StruggleCategory.anxiety).first;
  late final sleep = typesOf(StruggleCategory.sleep).first;

  AppUser get user => AppUser.fromMap('demo', {
    'struggleIds': [bfrb.id, anxiety.id, sleep.id],
    'categoryIds': ['bfrb', 'anxiety', 'sleep'],
    'communityJoined': true,
    'nickname': tr ? 'Sevimli Panda' : 'Cute Panda',
    'avatar': 1,
    'anonymous': false,
    'dailyStreak': 12,
    'longestDailyStreak': 21,
    'lastActivityDay': yesterday,
    'adsOptIn': false, // reklam alanı görüntüde boş kalmasın
    'language': lang,
    'country': tr ? 'TR' : 'US',
    'themeId': 'ocean',
  });

  List<Struggle> get struggles => [
    Struggle(
      type: bfrb,
      streak: StreakState(current: 12, longest: 21, totalKindDays: 34, lastKindDay: yesterday, lastCheckInDay: yesterday),
    ),
    Struggle(
      type: sleep,
      streak: StreakState(current: 5, longest: 9, totalKindDays: 17, lastKindDay: today, lastCheckInDay: today),
      lastResult: CheckInResult.kind,
    ),
    Struggle(
      type: anxiety,
      streak: StreakState(current: 3, longest: 8, totalKindDays: 22, lastKindDay: yesterday, lastCheckInDay: yesterday),
    ),
  ];

  /// Bu ay: çoğu gün iyi, birkaç zorlandığım gün, bir zor gün.
  MonthLog monthLog(String key) {
    if (key != monthKey(now)) return MonthLog.empty;
    const pattern = ['kind', 'kind', 'struggled', 'kind', 'kind', 'kind', 'hard', 'kind', 'kind', 'struggled'];
    return MonthLog({
      for (var d = 1; d < now.day; d++)
        d: {bfrb.id: CheckInResult.values.byName(pattern[d % pattern.length]), sleep.id: CheckInResult.kind},
      now.day: {sleep.id: CheckInResult.kind},
    });
  }

  List<JournalEntry> get journal => [
    JournalEntry(
      id: 'j1',
      text: tr
          ? 'Sınavdan önce nefes egzersizini yaptım, gerçekten iyi geldi.'
          : 'I did the breathing exercise before my exam and it really helped.',
      createdAt: now.subtract(const Duration(hours: 5)),
    ),
    JournalEntry(
      id: 'j2',
      text: tr
          ? 'Kendime karşı daha sabırlı olmayı deniyorum. Bugün iyi gitti.'
          : 'I am trying to be more patient with myself. Today went well.',
      createdAt: now.subtract(const Duration(days: 1, hours: 3)),
    ),
  ];

  List<CommunityNote> get feed => [
    CommunityNote(
      id: 'n1',
      authorUid: 'u1',
      nickname: tr ? 'Cesur Kuş' : 'Brave Bird',
      avatar: 3,
      streak: 30,
      circle: StruggleCategory.bfrb,
      text: tr
          ? '30 gün oldu! Ellerimi meşgul tutmak için yanımda küçük bir stres topu taşıyorum, gerçekten işe yarıyor. Kendinize nazik olun 🤍'
          : '30 days today! I carry a small stress ball to keep my hands busy and it really works. Be gentle with yourselves 🤍',
      createdAt: now.subtract(const Duration(minutes: 18)),
      supportCount: 24,
      reportCount: 0,
      replyCount: 6,
      lang: lang,
    ),
    CommunityNote(
      id: 'n2',
      authorUid: '',
      anonymous: true,
      nickname: CommunityNote.anonymousName,
      avatar: 0,
      streak: 0,
      circle: StruggleCategory.anxiety,
      text: tr
          ? 'Bugün kalabalıkta içim sıkıştı. Sakinleş\'teki nefes egzersizini yaptım, birkaç dakikada geçti. Küçük ama benim için büyük bir adım.'
          : 'I felt overwhelmed in a crowd today. I did the breathing exercise in Calm and it passed in a few minutes. Small, but a big step for me.',
      createdAt: now.subtract(const Duration(hours: 1, minutes: 5)),
      supportCount: 41,
      reportCount: 0,
      replyCount: 9,
      lang: lang,
    ),
    CommunityNote(
      id: 'n3',
      authorUid: 'u3',
      nickname: tr ? 'Sıcacık Ayı' : 'Cozy Bear',
      avatar: 2,
      streak: 6,
      circle: StruggleCategory.sleep,
      text: tr
          ? 'Telefonu yatak odasının dışında şarj etmeye başladım. Bir haftadır ilk kez gece uyanmadan uyudum.'
          : 'I started charging my phone outside the bedroom. For the first time in a week I slept through the night.',
      createdAt: now.subtract(const Duration(hours: 3)),
      supportCount: 17,
      reportCount: 0,
      replyCount: 3,
      lang: lang,
    ),
    CommunityNote(
      id: 'n4',
      authorUid: 'u4',
      nickname: tr ? 'Neşeli Tavşan' : 'Cheerful Bunny',
      avatar: 0,
      streak: 3,
      circle: StruggleCategory.anxiety,
      text: tr
          ? 'Bugün yataktan çıkmak zordu ama çıktım, kısa bir yürüyüş yaptım. Bunu da bir başarı sayıyorum.'
          : 'Getting out of bed was hard today, but I did it and went for a short walk. I am counting that as a win.',
      createdAt: now.subtract(const Duration(hours: 6)),
      supportCount: 33,
      reportCount: 0,
      replyCount: 4,
      lang: lang,
    ),
  ];

  List<InboxItem> get inbox => [
    InboxItem(
      id: 'i1',
      type: InboxType.kudos,
      createdAt: now.subtract(const Duration(minutes: 7)),
      read: false,
      fromUid: 'u3',
      fromNickname: tr ? 'Sıcacık Ayı' : 'Cozy Bear',
      fromAvatar: 2,
      messageId: 1,
    ),
    InboxItem(
      id: 'i2',
      type: InboxType.noteReply,
      createdAt: now.subtract(const Duration(minutes: 40)),
      read: false,
      fromUid: 'u1',
      fromNickname: tr ? 'Cesur Kuş' : 'Brave Bird',
      fromAvatar: 3,
    ),
    InboxItem(
      id: 'i3',
      type: InboxType.noteSupport,
      createdAt: now.subtract(const Duration(hours: 2)),
      read: true,
      fromUid: 'u4',
      fromNickname: tr ? 'Neşeli Tavşan' : 'Cheerful Bunny',
      fromAvatar: 0,
    ),
    InboxItem(
      id: 'i4',
      type: InboxType.friendAdded,
      createdAt: now.subtract(const Duration(hours: 9)),
      read: true,
      fromUid: 'u1',
      fromNickname: tr ? 'Cesur Kuş' : 'Brave Bird',
      fromAvatar: 3,
    ),
    InboxItem(
      id: 'i5',
      type: InboxType.streakMilestone,
      createdAt: now.subtract(const Duration(days: 2)),
      read: true,
      value: 10,
    ),
  ];

  List<SupportTicket> get tickets => [
    SupportTicket(
      id: 't1',
      uid: 'demo',
      kind: TicketKind.idea,
      text: tr
          ? 'Akşam hatırlatmasının saatini kendim seçebilsem çok iyi olurdu.'
          : 'It would be great if I could choose the time of the evening reminder myself.',
      status: TicketStatus.planned,
      lang: lang,
      reply: tr
          ? 'Harika bir fikir, teşekkürler! Bir sonraki sürüme ekliyoruz.'
          : 'Great idea, thank you! We are adding it in the next version.',
      replyLang: lang,
      createdAt: now.subtract(const Duration(days: 2)),
      repliedAt: now.subtract(const Duration(hours: 20)),
    ),
  ];

  PublicProfile get profile => PublicProfile(
    uid: 'demo',
    nickname: user.nickname!,
    avatar: 1,
    friendCode: 'HVN-4821',
    daily: user.daily,
  );

  List<Override> get overrides => [
    uidProvider.overrideWithValue('demo'),
    appUserProvider.overrideWith((ref) => Stream.value(user)),
    strugglesProvider.overrideWith((ref) => Stream.value(struggles)),
    monthLogProvider.overrideWith((ref, key) => Stream.value(monthLog(key))),
    bestStreakProvider.overrideWithValue(21),
    journalProvider.overrideWith((ref) => Stream.value(journal)),
    inboxProvider.overrideWith((ref) => Stream.value(inbox)),
    feedProvider.overrideWith((ref) => Stream.value(feed)),
    friendsFeedProvider.overrideWith((ref) => Stream.value(const [])),
    friendIdsProvider.overrideWith((ref) => Stream.value(const ['u1', 'u3', 'u4'])),
    myProfileProvider.overrideWith((ref) => Stream.value(profile)),
    myAnonNoteIdsProvider.overrideWith((ref) => Stream.value(const {})),
    userNotesProvider.overrideWith((ref, uid) => Stream.value(const [])),
    profileProvider.overrideWith((ref, uid) => Stream.value(null)),
    myTicketsProvider.overrideWith((ref) => Stream.value(tickets)),
    isDeveloperProvider.overrideWithValue(false),
    openTicketCountProvider.overrideWithValue(0),
    repositoryProvider.overrideWithValue(HavenRepository(_NoFirestore())),
    communityRepositoryProvider.overrideWithValue(CommunityRepository(_NoFirestore())),
    supportRepositoryProvider.overrideWithValue(SupportRepository(_NoFirestore())),
    analyticsProvider.overrideWithValue(AnalyticsService(_NoAnalytics())),
  ];
}

class _App extends ConsumerWidget {
  const _App({required this.home});
  final Widget home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    Tx.code = locale.languageCode;
    final theme = buildTheme(ref.watch(themePresetProvider));
    const fallback = ['Emoji', 'Symbols'];
    // Temada yazı tipi adı verilmeyen stiller telefonda sistem yazı tipine
    // (Roboto) düşer; test çizicisinde ise yer tutucu kutulara. Aynı sonucu
    // almak için bu stillere Roboto açıkça verilir.
    TextStyle roboto(TextStyle? s) =>
        (s ?? const TextStyle()).copyWith(fontFamily: 'Roboto', fontFamilyFallback: fallback);
    final filled = theme.filledButtonTheme.style;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamilyFallback: fallback),
        primaryTextTheme: theme.primaryTextTheme.apply(fontFamilyFallback: fallback),
        appBarTheme: theme.appBarTheme.copyWith(titleTextStyle: roboto(theme.appBarTheme.titleTextStyle)),
        filledButtonTheme: FilledButtonThemeData(
          style: filled?.copyWith(textStyle: WidgetStatePropertyAll(roboto(filled.textStyle?.resolve({})))),
        ),
      ),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );
  }
}

Future<void> _loadFonts() async {
  // flutter_tester: <flutter>/bin/cache/artifacts/engine/<platform>/flutter_tester(.exe)
  final artifacts = File(Platform.resolvedExecutable).parent.parent.parent;
  final dir = '${artifacts.path}/material_fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
    }
    await loader.load();
  }

  await load('Roboto', [for (final w in ['light', 'regular', 'medium', 'bold']) '$dir/roboto-$w.ttf']);
  await load('MaterialIcons', ['$dir/materialicons-regular.otf']);
  await load('Emoji', [_emojiFont]);
  await load('Symbols', [_symbolFont]);
}

void main() {
  setUpAll(_loadFonts);

  final boundary = GlobalKey();

  Future<void> settle(WidgetTester tester) async {
    // Akışlar bir sonraki karede gelir; sürekli animasyonlar olabileceği için
    // pumpAndSettle yerine sabit süre ilerlet.
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shoot(WidgetTester tester, String lang, String name) async {
    final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await render.toImage(pixelRatio: _dpr);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('store/screenshots/$lang/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  for (final lang in ['tr', 'en']) {
    testWidgets('mağaza ekran görüntüleri ($lang)', (tester) async {
      tester.view.physicalSize = _size;
      tester.view.devicePixelRatio = _dpr;
      addTearDown(tester.view.reset);
      debugDisableShadows = false; // kart gölgeleri gerçek cihazdaki gibi
      final demo = _Demo(lang);

      Future<void> pump(Widget home) async {
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: ProviderScope(
              key: UniqueKey(),
              overrides: demo.overrides,
              child: _App(home: home),
            ),
          ),
        );
        await settle(tester);
      }

      // Ana kabuk: Bugün, Topluluk, Sakinleş (alt menüyle birlikte).
      await pump(const HomeShell());
      await shoot(tester, lang, '1-bugun');
      final container = ProviderScope.containerOf(tester.element(find.byType(HomeShell)));
      for (final (i, name) in [(1, '2-topluluk'), (2, '3-sakinles')]) {
        container.read(shellIndexProvider.notifier).select(i);
        await settle(tester);
        await shoot(tester, lang, name);
      }

      await pump(const NotificationsScreen());
      await shoot(tester, lang, '4-bildirimler');

      await pump(const FeedbackScreen());
      // Asıl gösterilecek kısım: talebin durumu ve geliştiricinin yanıtı.
      // Liste yalnızca görünen öğeleri kurar: önce yanıt görünene kadar kaydır.
      final reply = find.text(demo.tickets.first.reply!);
      await tester.scrollUntilVisible(reply, 200, scrollable: find.byType(Scrollable).first);
      Scrollable.ensureVisible(tester.element(reply.first), alignment: 0.7);
      await settle(tester);
      await shoot(tester, lang, '5-destek');
      debugDisableShadows = true; // test çerçevesi bu ayarın geri alınmasını bekler
    });
  }
}
