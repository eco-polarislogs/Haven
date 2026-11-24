// Tasarım ekran görüntüleri (README ve mağaza): uygulamanın GERÇEK ekranları,
// örnek verilerle, yedi tasarımın her birinde ayrı ayrı çizilir.
//
// Normal `flutter test` bunu çalıştırmaz (test/ dışında). Üretmek için:
//   flutter test tool/design_screenshots_test.dart
//   (yalnızca bazıları: --dart-define=SHOT_DESIGNS=classic,gece)
//
// Çıktı: store/screenshots/designs/<tasarım>/<sıra>-<ekran>.png (1080×1920, 9:16)
// Firebase'e bağlanmaz; tüm veri akışları örnek verilerle değiştirilir.
// Mağaza dilindeki genel ekran görüntüleri: tool/store_screenshots_test.dart.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haven/core/constants/struggle_catalog.dart';
import 'package:haven/core/theme/app_theme.dart';
import 'package:haven/core/utils/day_key.dart';
import 'package:haven/core/utils/streak.dart';
import 'package:haven/data/models/app_user.dart';
import 'package:haven/data/models/community.dart';
import 'package:haven/data/models/journal_entry.dart';
import 'package:haven/data/models/month_log.dart';
import 'package:haven/data/models/struggle.dart';
import 'package:haven/data/services/analytics_service.dart';
import 'package:haven/data/services/community_repository.dart';
import 'package:haven/data/services/haven_repository.dart';
import 'package:haven/data/services/support_repository.dart';
import 'package:haven/features/journal/journal_screen.dart';
import 'package:haven/features/notifications/notifications_screen.dart';
import 'package:haven/features/profile/design_picker.dart';
import 'package:haven/features/profile/profile_screen.dart';
import 'package:haven/features/shell/home_shell.dart';
import 'package:haven/features/support/calm_screen.dart';
import 'package:haven/l10n/app_localizations.dart';
import 'package:haven/l10n/tx.dart';
import 'package:haven/providers.dart';

const _logicalSize = Size(405, 720); // × 8/3 = 1080 × 1920
const _dpr = 8 / 3;

/// Ekran görüntüsü alınacak tasarımlar (boşsa hepsi).
const _only = String.fromEnvironment('SHOT_DESIGNS');

// ------------------------------------------------------------ yazı tipleri
Future<void> _loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? _guessFlutterRoot();
  final material = '$flutterRoot/bin/cache/artifacts/material_fonts';
  Future<void> family(String name, List<String> paths) async {
    final loader = FontLoader(name);
    for (final p in paths) {
      final f = File(p);
      if (!f.existsSync()) continue;
      loader.addFont(Future.value(ByteData.view(Uint8List.fromList(f.readAsBytesSync()).buffer)));
    }
    await loader.load();
  }

  await family('Roboto', [
    for (final w in ['regular', 'medium', 'bold', 'light', 'black']) '$material/roboto-$w.ttf',
  ]);
  await family('MaterialIcons', ['$material/materialicons-regular.otf']);
  // Uygulamanın kendi yazı tipleri (pubspec.yaml → fonts).
  final byFamily = <String, List<String>>{};
  for (final f in Directory('assets/fonts').listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (!name.endsWith('.ttf')) continue;
    byFamily.putIfAbsent(name.split('-').first, () => []).add(f.path);
  }
  for (final e in byFamily.entries) {
    await family(e.key, e.value);
  }
  // Avatarlar emoji, "→" gibi işaretler sembol: test ortamında sistemin
  // emoji ve sembol yazı tipleri (telefonda sistemin yedek yazı tipleri).
  await family('ShotEmoji', ['C:/Windows/Fonts/seguiemj.ttf']);
  await family('ShotSymbols', ['C:/Windows/Fonts/seguisym.ttf']);
}

String _guessFlutterRoot() {
  final exe = Platform.resolvedExecutable.replaceAll('\\', '/');
  final i = exe.indexOf('/bin/cache/');
  return i > 0 ? exe.substring(0, i) : '';
}

// ------------------------------------------------------------ örnek veri
final _today = todayKey();
String _daysAgo(int n) {
  final d = DateTime.now().subtract(Duration(days: n));
  return dayKey(d);
}

AppUser _user(String designId) => AppUser.fromMap('demo', {
  'struggleIds': ['generalized_anxiety', 'insomnia'],
  'categoryIds': ['anxiety', 'sleep'],
  'nickname': 'Sevimli Panda',
  'avatar': 1,
  'themeId': 'ocean',
  'designId': designId,
  'communityJoined': true,
  'adsOptIn': false,
  'language': 'tr',
  'country': 'TR',
  'dailyStreak': 12,
  'longestDailyStreak': 21,
  'lastActivityDay': _today,
});

final _struggles = [
  Struggle(
    type: struggleTypeById('generalized_anxiety')!,
    streak: StreakState(current: 12, longest: 21, totalKindDays: 34, lastKindDay: _today, lastCheckInDay: _today),
    lastResult: CheckInResult.kind,
  ),
  Struggle(
    type: struggleTypeById('insomnia')!,
    streak: StreakState(
      current: 5,
      longest: 9,
      totalKindDays: 17,
      lastKindDay: _daysAgo(1),
      lastCheckInDay: _daysAgo(1),
    ),
  ),
];

MonthLog _month(String key) {
  final now = DateTime.now();
  final isCurrent = key == monthKey(now);
  final last = isCurrent ? now.day : DateTime(now.year, now.month, 0).day;
  final days = <int, Map<String, CheckInResult>>{};
  for (var d = 1; d <= last; d++) {
    // Çoğu gün iyi; arada "zorlandım" ve bir "zor gün".
    final r = d % 9 == 4
        ? CheckInResult.hard
        : d % 5 == 2
        ? CheckInResult.struggled
        : CheckInResult.kind;
    if (isCurrent && d == now.day) {
      days[d] = {'generalized_anxiety': CheckInResult.kind};
    } else if (d % 7 != 6) {
      days[d] = {'generalized_anxiety': r, 'insomnia': CheckInResult.kind};
    }
  }
  return MonthLog(days);
}

DateTime _ago(Duration d) => DateTime.now().subtract(d);

List<CommunityNote> _feed() => [
  CommunityNote(
    id: 'n1',
    authorUid: 'u1',
    nickname: 'Cesur Kuş',
    avatar: 3,
    streak: 30,
    circle: StruggleCategory.anxiety,
    text: 'Bugün ilk kez toplantıda söz aldım. Elim titriyordu ama konuştum.',
    createdAt: _ago(const Duration(minutes: 18)),
    supportCount: 24,
    reportCount: 0,
    replyCount: 5,
  ),
  CommunityNote(
    id: 'n2',
    authorUid: 'u2',
    nickname: 'Sıcacık Ayı',
    avatar: 2,
    streak: 6,
    circle: StruggleCategory.sleep,
    text: 'İlk kez gece yarısından önce uyudum. Telefonu başka odada bıraktım.',
    createdAt: _ago(const Duration(hours: 1)),
    supportCount: 12,
    reportCount: 0,
    replyCount: 2,
  ),
  CommunityNote(
    id: 'n3',
    authorUid: '',
    nickname: CommunityNote.anonymousName,
    avatar: 17,
    streak: 0,
    circle: StruggleCategory.anxiety,
    anonymous: true,
    text: 'Zor bir haftaydı. Yine de buradayım ve nefes egzersizi gerçekten işe yaradı.',
    createdAt: _ago(const Duration(hours: 3)),
    supportCount: 41,
    reportCount: 0,
    replyCount: 8,
  ),
  CommunityNote(
    id: 'n4',
    authorUid: 'u4',
    nickname: 'Sabırlı Kaplumbağa',
    avatar: 11,
    streak: 14,
    circle: StruggleCategory.anxiety,
    text: 'Küçük adımlar da sayılıyor. İki haftadır her sabah 5 dakika yürüyorum.',
    createdAt: _ago(const Duration(hours: 5)),
    supportCount: 9,
    reportCount: 0,
  ),
];

final _journal = [
  JournalEntry(
    id: 'j1',
    text: 'Sabah yürüyüşü iyi geldi. Kaygı öğleden sonra azaldı.',
    createdAt: _ago(const Duration(hours: 4)),
  ),
  JournalEntry(
    id: 'j2',
    text: 'Uyumadan önce ekran yok kuralı ikinci günde.',
    createdAt: _ago(const Duration(days: 1)),
  ),
];

final _inbox = [
  InboxItem(
    id: 'i1',
    type: InboxType.kudos,
    createdAt: _ago(const Duration(minutes: 30)),
    read: false,
    fromNickname: 'Cesur Kuş',
    fromAvatar: 3,
    messageId: 0,
  ),
  InboxItem(id: 'i2', type: InboxType.streakMilestone, createdAt: _ago(const Duration(days: 1)), read: false, value: 7),
];

const _me = PublicProfile(
  uid: 'demo',
  nickname: 'Sevimli Panda',
  avatar: 1,
  friendCode: 'HVN7K2',
  daily: DailyStreak(current: 12, longest: 21),
);

// ------------------------------------------------------------ sahte servisler
class _NoAnalytics implements AnalyticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _NoRepo implements HavenRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _NoCommunity implements CommunityRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _NoSupport implements SupportRepository {
  @override
  bool isDeveloper(String? uid) => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FixedIndex extends ShellIndex {
  _FixedIndex(this.index);
  final int index;
  @override
  int build() => index;
}

List<dynamic> _overrides(String designId, int tab) {
  final user = _user(designId);
  return [
    uidProvider.overrideWithValue('demo'),
    appUserProvider.overrideWith((ref) => Stream.value(user)),
    strugglesProvider.overrideWith((ref) => Stream.value(_struggles)),
    monthLogProvider.overrideWith((ref, key) => Stream.value(_month(key))),
    journalProvider.overrideWith((ref) => Stream.value(_journal)),
    myProfileProvider.overrideWith((ref) => Stream.value(_me)),
    feedProvider.overrideWith((ref) => Stream.value(_feed())),
    friendsFeedProvider.overrideWith((ref) => Stream.value(const [])),
    friendIdsProvider.overrideWith((ref) => Stream.value(const [])),
    friendProfilesProvider.overrideWith((ref) => Stream.value(const [])),
    myAnonNoteIdsProvider.overrideWith((ref) => Stream.value(const {})),
    inboxProvider.overrideWith((ref) => Stream.value(_inbox)),
    myTicketsProvider.overrideWith((ref) => Stream.value(const [])),
    allTicketsProvider.overrideWith((ref) => Stream.value(const [])),
    analyticsProvider.overrideWithValue(_NoAnalytics()),
    repositoryProvider.overrideWithValue(_NoRepo()),
    communityRepositoryProvider.overrideWithValue(_NoCommunity()),
    supportRepositoryProvider.overrideWithValue(_NoSupport()),
    shellIndexProvider.overrideWith(() => _FixedIndex(tab)),
  ];
}

// ------------------------------------------------------------ çizim
ThemeData _themeFor(String designId) {
  final theme = buildAppTheme(
    HavenDesign.parse(designId),
    ThemePreset.ocean,
    fontFallback: const ['ShotEmoji', 'ShotSymbols'],
  );
  // Test ortamında yazı tipi belirtilmemiş metin "kutu" çizilir; telefonda
  // bu metinler sistem yazı tipiyle (Roboto) çıkar. Emoji avatarlar için de
  // sistemin emoji yazı tipi yedek olarak eklenir (yalnızca test ortamı).
  const fallback = ['ShotEmoji', 'ShotSymbols'];
  TextStyle? fix(TextStyle? s) => s?.copyWith(fontFamily: s.fontFamily ?? 'Roboto', fontFamilyFallback: fallback);
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamilyFallback: fallback),
    appBarTheme: theme.appBarTheme.copyWith(titleTextStyle: fix(theme.appBarTheme.titleTextStyle)),
    snackBarTheme: theme.snackBarTheme.copyWith(contentTextStyle: fix(theme.snackBarTheme.contentTextStyle)),
  );
}

Future<void> _shoot(
  WidgetTester tester, {
  required String designId,
  required String name,
  required Widget home,
  int tab = 0,
  Duration settle = const Duration(milliseconds: 600),
  Future<void> Function(WidgetTester tester)? prepare,
}) async {
  tester.view.physicalSize = _logicalSize * _dpr;
  tester.view.devicePixelRatio = _dpr;
  tester.view.padding = const FakeViewPadding(top: 24 * _dpr);
  tester.view.viewPadding = const FakeViewPadding(top: 24 * _dpr);
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: _overrides(designId, tab).cast(),
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _themeFor(designId),
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: home,
        ),
      ),
    ),
  );
  // Akışlar (Stream.value) bir sonraki karede gelir; animasyonlar kısa ilerler.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(settle);
  if (prepare != null) {
    await prepare(tester);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _dpr);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = File('store/screenshots/designs/$designId/$name.png');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    Tx.code = 'tr';
    await _loadFonts();
  });

  final designs = [
    for (final d in HavenDesign.values)
      if (_only.isEmpty || _only.split(',').contains(d.name)) d.name,
  ];

  for (final d in designs) {
    testWidgets('ekran görüntüleri: $d', (tester) async {
      // Testler gölgeleri varsayılan olarak siyah çizgi çizer; gerçek gölge olsun.
      debugDisableShadows = false;
      await _shoot(tester, designId: d, name: '1-bugun', home: const HomeShell());
      await _shoot(tester, designId: d, name: '2-topluluk', home: const HomeShell(), tab: 1);
      await _shoot(tester, designId: d, name: '3-sakinles', home: const HomeShell(), tab: 2);
      await _shoot(
        tester,
        designId: d,
        name: '4-nefes',
        home: const CalmScreen(category: StruggleCategory.anxiety),
        settle: const Duration(milliseconds: 2400),
      );
      await _shoot(tester, designId: d, name: '5-profil', home: const HomeShell(), tab: 3);
      // Profil → Tasarım: yedi tasarımın seçildiği bölüm.
      await _shoot(
        tester,
        designId: d,
        name: '6-tasarim',
        home: const ProfileScreen(),
        prepare: (tester) async {
          final picker = find.byType(DesignPicker);
          await tester.scrollUntilVisible(picker, 300, scrollable: find.byType(Scrollable).first);
          await tester.pump();
          Scrollable.ensureVisible(tester.element(picker), alignment: 0.32);
        },
      );
      // İkincil ekranlar: kartlar, listeler ve kutular da tasarımla değişir.
      await _shoot(tester, designId: d, name: '7-bildirimler', home: const NotificationsScreen());
      await _shoot(tester, designId: d, name: '8-notlarim', home: const JournalScreen());
      debugDisableShadows = true;
    });
  }
}
