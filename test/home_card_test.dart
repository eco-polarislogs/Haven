import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haven/core/constants/struggle_catalog.dart';
import 'package:haven/core/utils/day_key.dart';
import 'package:haven/core/utils/streak.dart';
import 'package:haven/data/models/struggle.dart';
import 'package:haven/features/home/struggle_card.dart';
import 'package:haven/l10n/app_localizations.dart';

/// Ana sayfadaki günlük değerlendirme kartı: her alan için "Başardım / Zorlandım / Başaramadım"
/// düğmeleri kayıt yapılmadıysa görünür; kayıt yapıldıysa günün sonucu yazar.
void main() {
  Future<void> pump(WidgetTester tester, Struggle s) => tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('tr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(body: SingleChildScrollView(child: StruggleCard(struggle: s, recentHardDays: 0))),
          ),
        ),
      );

  final type = typesOf(StruggleCategory.bfrb).first;

  testWidgets('bugün değerlendirilmemiş alan: soru + üç seçenek', (tester) async {
    await pump(tester, Struggle(type: type, streak: const StreakState()));
    await tester.pumpAndSettle();
    expect(find.text('Başardım'), findsOneWidget);
    expect(find.text('Zorlandım'), findsOneWidget);
    expect(find.text('Başaramadım'), findsOneWidget);
    expect(find.text('Zor oldu ama dayandım'), findsOneWidget);
    expect(find.text(StruggleCategory.bfrb.checkInQuestion), findsOneWidget);
  });

  testWidgets('bugün değerlendirilmiş alan: düğmeler yerine günün sonucu', (tester) async {
    final today = todayKey();
    await pump(
      tester,
      Struggle(
        type: type,
        streak: StreakState(current: 2, longest: 2, totalKindDays: 2, lastKindDay: today, lastCheckInDay: today),
        lastResult: CheckInResult.kind,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Başardım'), findsNothing);
    expect(find.textContaining('Bugünü kaydettin'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // iyi geçen gün sayısı
  });

  testWidgets('"zorlandım ama dayandım" kaydı: seri sürer, kendine özgü mesaj', (tester) async {
    final today = todayKey();
    await pump(
      tester,
      Struggle(
        type: type,
        streak: StreakState(current: 4, longest: 4, totalKindDays: 4, lastKindDay: today, lastCheckInDay: today),
        lastResult: CheckInResult.struggled,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Zorlandın ama dayandın'), findsOneWidget);
    expect(find.text('Zorlandım'), findsNothing);
  });
}
