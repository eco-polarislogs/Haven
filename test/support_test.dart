import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haven/core/constants/app_constants.dart';
import 'package:haven/data/models/community.dart';
import 'package:haven/data/models/support_ticket.dart';
import 'package:haven/features/support/feedback_screen.dart';
import 'package:haven/l10n/app_localizations.dart';
import 'package:haven/l10n/tx.dart';
import 'package:haven/providers.dart';

/// Destek ve öneriler: kullanıcı → geliştirici talepleri.
void main() {
  final rules = File('firestore.rules').readAsStringSync();

  group('kurallarla uyum', () {
    test('geliştirici listesi uygulamada ve firestore.rules içinde aynı', () {
      final m = RegExp(r"function developerUids\(\) \{ return \[([^\]]*)\]; \}").firstMatch(rules);
      expect(m, isNotNull);
      final inRules = RegExp(r"'([^']+)'").allMatches(m![1]!).map((x) => x[1]).toSet();
      expect(inRules, kDeveloperUids);
    });

    test('talep türleri, durumlar ve bildirim türleri kurallarda tanımlı', () {
      for (final k in TicketKind.values) {
        expect(rules, contains("'${k.wire}'"), reason: k.wire);
      }
      for (final s in TicketStatus.values) {
        expect(rules, contains("'${s.wire}'"), reason: s.wire);
      }
      expect(rules, contains("'${InboxType.feedbackNew.wire}'"));
      expect(rules, contains("'${InboxType.feedbackReply.wire}'"));
      expect(rules, contains('text.size() <= ${SupportTicket.maxLength}'));
      expect(rules, contains('text.size() >= ${SupportTicket.minLength}'));
    });
  });

  group('model', () {
    test('bilinmeyen değerler güvenli varsayılana düşer', () {
      expect(TicketKind.parse('xyz'), TicketKind.other);
      expect(TicketStatus.parse(null), TicketStatus.open);
      for (final k in TicketKind.values) {
        expect(TicketKind.parse(k.wire), k);
      }
    });

    test('yeniden eskiye sıralama; sunucu saati gelmemiş talep en üstte', () {
      SupportTicket t(String id, DateTime? at) => SupportTicket(
        id: id,
        uid: 'u',
        kind: TicketKind.idea,
        text: 'x',
        status: TicketStatus.open,
        lang: 'tr',
        createdAt: at,
      );
      final list = [t('eski', DateTime(2026, 1, 1)), t('bekleyen', null), t('yeni', DateTime(2026, 6, 1))]
        ..sort(SupportTicket.newestFirst);
      expect(list.map((x) => x.id), ['bekleyen', 'yeni', 'eski']);
    });
  });

  group('bildirim metinleri', () {
    tearDown(() => Tx.code = 'tr');

    InboxItem item(InboxType type, {int? value, String? nick}) =>
        InboxItem(id: '1', type: type, createdAt: null, read: false, fromUid: 'x', value: value, fromNickname: nick);

    test('geliştiriciye yeni talep: tür ve gönderen (isimsizse "İsimsiz bir kullanıcı")', () {
      expect(item(InboxType.feedbackNew, value: TicketKind.bug.index).title, 'Yeni destek talebi · Hata bildir');
      expect(item(InboxType.feedbackNew, value: 0).body, contains('İsimsiz bir kullanıcı'));
      expect(item(InboxType.feedbackNew, value: 0, nick: 'Deniz').body, contains('Deniz'));
    });

    test('kullanıcıya güncelleme: yanıt / planlandı / tamamlandı ayrı mesaj, 5 dilde', () {
      for (final lang in ['tr', 'en', 'es', 'zh', 'hi']) {
        Tx.code = lang;
        final bodies = {
          for (final s in [TicketStatus.seen, TicketStatus.planned, TicketStatus.done])
            item(InboxType.feedbackReply, value: s.index).body,
        };
        expect(bodies.length, 3, reason: lang);
        expect(item(InboxType.feedbackReply).title, isNot('Haven'));
      }
    });
  });

  group('Destek ve öneriler ekranı', () {
    Future<void> pump(WidgetTester tester, List<SupportTicket> mine) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uidProvider.overrideWithValue(null),
            appUserProvider.overrideWith((ref) => Stream.value(null)),
            myTicketsProvider.overrideWith((ref) => Stream.value(mine)),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const FeedbackScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('dört talep türü, gönder düğmesi ve boş liste mesajı', (tester) async {
      await pump(tester, const []);
      for (final k in TicketKind.values) {
        expect(find.text(k.label), findsOneWidget);
      }
      final list = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Geliştiriciye gönder'), 200, scrollable: list);
      expect(find.text('Geliştiriciye gönder'), findsOneWidget);
      await tester.scrollUntilVisible(find.textContaining('Henüz bir talep göndermedin'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.textContaining('Henüz bir talep göndermedin'), findsOneWidget);
    });

    testWidgets('acil bir durum yazılırsa destek hatları hemen önerilir', (tester) async {
      await pump(tester, const []);
      expect(find.text('Destek hatlarını aç'), findsNothing);
      await tester.enterText(find.byType(TextField), 'Artık dayanamıyorum, ne yapacağımı bilmiyorum');
      await tester.pump();
      expect(find.text('Destek hatlarını aç'), findsOneWidget);
    });

    testWidgets('gönderilen talep: durum etiketi ve geliştiricinin yanıtı görünür', (tester) async {
      await pump(tester, [
        SupportTicket(
          id: 'a',
          uid: 'u',
          kind: TicketKind.idea,
          text: 'Karanlık tema daha koyu olabilir mi?',
          status: TicketStatus.planned,
          lang: 'tr',
          reply: 'Harika fikir, bir sonraki sürümde!',
          replyLang: 'tr',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          repliedAt: DateTime.now(),
        ),
      ]);
      await tester.scrollUntilVisible(find.text('Harika fikir, bir sonraki sürümde!'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Planlandı'), findsOneWidget);
      expect(find.text('Geliştiricinin yanıtı'), findsOneWidget);
      expect(find.text('Karanlık tema daha koyu olabilir mi?'), findsOneWidget);
    });
  });
}
