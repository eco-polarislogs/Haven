import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haven/core/theme/app_theme.dart';
import 'package:haven/core/utils/day_key.dart';
import 'package:haven/core/utils/streak.dart';
import 'package:haven/data/models/app_user.dart';
import 'package:haven/data/models/month_log.dart';
import 'package:haven/features/home/month_lights.dart';
import 'package:haven/features/home/streak_hero.dart';
import 'package:haven/features/profile/design_picker.dart';
import 'package:haven/l10n/app_localizations.dart';

/// Görünüm tasarımları: Klasik orijinal temayla birebir aynı kalır; diğer
/// tasarımlar eksiksiz bir tema üretir, metinleri okunur ve seri kartı,
/// takvim ve tasarım seçici her tasarımda taşmadan çizilir.
void main() {
  // Taşma denetimi gerçek yazı tipleriyle yapılsın (test yazı tipinde her harf
  // kare çizilir ve gerçekte sığan metinler taşmış görünür).
  setUpAll(() async {
    Future<void> load(String family, Iterable<File> files) async {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      }
      await loader.load();
    }

    final exe = Platform.resolvedExecutable.replaceAll(r'\', '/');
    final root = Platform.environment['FLUTTER_ROOT'] ?? exe.substring(0, exe.indexOf('/bin/cache/'));
    final material = Directory('$root/bin/cache/artifacts/material_fonts');
    if (material.existsSync()) {
      await load(
        'Roboto',
        material.listSync().whereType<File>().where((f) => RegExp(r'roboto-\w+\.ttf$').hasMatch(f.path)),
      );
      await load('MaterialIcons', [File('${material.path}/materialicons-regular.otf')]);
    }
    final byFamily = <String, List<File>>{};
    for (final f in Directory('assets/fonts').listSync().whereType<File>().where((f) => f.path.endsWith('.ttf'))) {
      byFamily.putIfAbsent(f.uri.pathSegments.last.split('-').first, () => []).add(f);
    }
    for (final e in byFamily.entries) {
      await load(e.key, e.value);
    }
  });

  double contrast(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  test('bilinmeyen ya da boş tasarım kimliği Klasik sayılır', () {
    expect(HavenDesign.parse(null), HavenDesign.classic);
    expect(HavenDesign.parse('yok-boyle-bir-sey'), HavenDesign.classic);
    expect(HavenDesign.parse('gece'), HavenDesign.gece);
  });

  test('Klasik tasarım her renk temasında orijinal temanın aynısı', () {
    for (final p in ThemePreset.values) {
      final a = buildAppTheme(HavenDesign.classic, p);
      final b = buildTheme(p);
      expect(a.colorScheme, b.colorScheme, reason: p.name);
      expect(a.cardTheme, b.cardTheme, reason: p.name);
      expect(a.navigationBarTheme, b.navigationBarTheme, reason: p.name);
      expect(a.textTheme, b.textTheme, reason: p.name);
      expect(a.extension<HavenStyle>()?.isClassic, isTrue);
    }
  });

  test('Klasik stil yardımcıları orijinal değerleri döndürür', () {
    const s = HavenStyle.classic;
    expect(s.r(16), 16);
    expect(s.border, isNull);
    expect(s.shadow(), isNull);
    expect(
      s.box(color: Colors.red, radius: 20),
      BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
    );
    expect(s.danger, HavenColors.clay);
    expect(DesignTokens.classic.kindDay, HavenColors.kindDay);
    expect(DesignTokens.classic.struggledDay, HavenColors.struggledDay);
    expect(DesignTokens.classic.hardDay, HavenColors.hardDay);
  });

  for (final d in HavenDesign.values.where((d) => !d.isClassic)) {
    test('${d.name}: tema eksiksiz ve okunur', () {
      final theme = buildAppTheme(d, ThemePreset.ocean);
      final t = d.tokens;
      expect(theme.extension<HavenStyle>()?.design, d);
      expect(theme.brightness, t.brightness);
      expect(theme.textTheme.bodyMedium?.fontFamily, t.bodyFont);
      expect(theme.textTheme.headlineSmall?.fontFamily, t.headingFont);
      // WCAG: gövde metni 4.5:1 (Net'te 7:1), düğme yazısı 4.5:1.
      expect(contrast(t.ink, t.background), greaterThanOrEqualTo(d == HavenDesign.net ? 7 : 4.5));
      expect(contrast(t.ink, t.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(t.muted, t.background), greaterThanOrEqualTo(4.5));
      expect(contrast(t.muted, t.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(t.onPrimary, t.primary), greaterThanOrEqualTo(4.5));
      expect(contrast(t.onDanger, t.danger), greaterThanOrEqualTo(4.5));
      expect(contrast(t.onAccent, t.accent), greaterThanOrEqualTo(4.5));
      // Simgeler (alev, vurgu): en az 3:1.
      expect(contrast(t.flame, t.background), greaterThanOrEqualTo(3));
    });
  }

  test('tasarım seçimi kullanıcı belgesinden okunur (yoksa Klasik)', () {
    expect(AppUser.fromMap('u', const {}).designId, 'classic');
    expect(AppUser.fromMap('u', const {'designId': 'neseli'}).designId, 'neseli');
  });

  Widget app(HavenDesign d, Widget child) => MaterialApp(
    theme: buildAppTheme(d, ThemePreset.ocean),
    locale: const Locale('tr'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child),
    ),
  );

  for (final d in HavenDesign.values) {
    testWidgets('${d.name}: seri kartı, takvim ve tasarım seçici taşmadan çizilir', (tester) async {
      tester.view.physicalSize = const Size(360, 1400) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final today = todayKey();
      await tester.pumpWidget(
        app(
          d,
          Column(
            children: [
              StreakHero(
                daily: DailyStreak(current: 12, longest: 21, lastDay: today),
                today: today,
                week: const [
                  DayStatus.kind,
                  DayStatus.struggled,
                  DayStatus.hard,
                  DayStatus.none,
                  DayStatus.none,
                  DayStatus.none,
                  DayStatus.none,
                ],
                doneToday: true,
              ),
              const SizedBox(height: 12),
              MonthLights(month: DateTime.now(), log: MonthLog.empty),
              const SizedBox(height: 12),
              DesignPicker(selected: d, classicPreset: ThemePreset.ocean, onSelect: (_) {}),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('12'), findsWidgets);
    });
  }
}
