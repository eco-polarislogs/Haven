import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haven/data/models/app_user.dart';
import 'package:haven/data/models/support_ticket.dart';
import 'package:haven/features/community/moderation_actions.dart';
import 'package:haven/l10n/app_localizations.dart';
import 'package:haven/providers.dart';

/// Engelleme ve şikâyet: Google Play / App Store kullanıcı içeriği politikası
/// uygulama içinde içeriği bildirme ve kullanıcıyı engelleme ister.
void main() {
  final rules = File('firestore.rules').readAsStringSync();

  group('kurallar', () {
    test('engellenen kişi bildirim bırakamaz ve arkadaş ekleyemez', () {
      expect(rules, contains('function blockedBy(uid)'));
      expect(RegExp(r'match /friends/\{friendUid\}[\s\S]*?allow create:[^;]*!blockedBy\(uid\)').hasMatch(rules), isTrue);
      expect(RegExp(r'match /inbox/\{id\}[\s\S]*?allow create:[\s\S]*?!blockedBy\(uid\)').hasMatch(rules), isTrue);
    });

    test('geliştirici şikâyet edilen paylaşım ve yanıtı kaldırabilir', () {
      expect(rules, contains("exists(myNotePath()) || isDeveloper()"));
      expect(rules, contains("resource.data.authorUid == me() || isDeveloper()"));
    });

    test('şikâyet hedefi uygulamada ve kurallarda aynı biçimde', () {
      expect(rules, contains("'report'"));
      expect(rules, contains('notes/[A-Za-z0-9]{1,40}(/replies/[A-Za-z0-9]{1,40})?'));
      expect(SupportTicket.targetPattern.hasMatch('notes/AbC123'), isTrue);
      expect(SupportTicket.targetPattern.hasMatch('notes/AbC123/replies/x9'), isTrue);
      expect(SupportTicket.targetPattern.hasMatch('users/abc'), isFalse);
      expect(SupportTicket.targetPattern.hasMatch('notes/../users/x'), isFalse);
    });
  });

  test('engel listesi kullanıcı belgesinden okunur', () {
    final u = AppUser.fromMap('me', {
      'blockedUids': ['a', 'b'],
      'reportedReplies': ['r1'],
    });
    expect(u.blockedUids, {'a', 'b'});
    expect(u.reportedReplies, {'r1'});
    expect(AppUser.fromMap('me', const {}).blockedUids, isEmpty);
  });

  testWidgets('Engellediğin kişiler: boşken nasıl engelleneceğini anlatır', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          uidProvider.overrideWithValue(null),
          appUserProvider.overrideWith((ref) => Stream.value(null)),
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
          home: const BlockedUsersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Engellediğin kişiler'), findsOneWidget);
    expect(find.textContaining('Kimseyi engellemedin'), findsOneWidget);
  });
}
