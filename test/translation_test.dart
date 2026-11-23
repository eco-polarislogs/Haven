import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:haven/core/constants/app_constants.dart';
import 'package:haven/core/constants/country_support.dart';
import 'package:haven/core/constants/struggle_catalog.dart';
import 'package:haven/core/moderation/content_moderator.dart';
import 'package:haven/core/quotes/quote_engine.dart';
import 'package:haven/core/theme/theme_presets.dart';
import 'package:haven/data/models/community.dart';
import 'package:haven/data/services/local_notifier.dart';
import 'package:haven/features/profile/badges.dart';
import 'package:haven/l10n/tx.dart';

/// Çeviri kapsamı: koddaki her tx('…') metni ve tüm içerik listeleri
/// (11 alanın metinleri, günün sözleri, bildirimler…) 4 dilde de çevrilmiş
/// olmalı ve yer tutucular ({ad}) korunmalı.
///
/// Yeni metin eklediğinde bu test eksik çeviriyi listeler.
/// Anahtar listesini dökmek için: DUMP_TX=1 flutter test test/translation_test.dart
void main() {
  const langs = ['en', 'es', 'zh', 'hi'];

  Set<String> sourceKeys() {
    final keys = <String>{};
    // AuthFailure('…') metinleri de gösterim anında tx() ile çevrilir.
    final lit = RegExp(r"""\b(?:tx|AuthFailure)\(\s*'((?:[^'\\]|\\.)*)'""");
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.contains('${Platform.pathSeparator}l10n${Platform.pathSeparator}')) {
        continue;
      }
      for (final m in lit.allMatches(f.readAsStringSync())) {
        keys.add(m[1]!.replaceAllMapped(RegExp(r'\\(.)'), (e) => switch (e[1]) {
              'n' => '\n',
              't' => '\t',
              _ => e[1]!,
            }));
      }
    }
    return keys;
  }

  Set<String> dataKeys() {
    final keys = <String>{};
    Tx.onLookup = keys.add;
    try {
      for (final c in StruggleCategory.values) {
        c.title;
        c.shortTitle;
        c.subtitle;
        c.checkInQuestion;
        c.hardDayMessage;
        c.calmTips;
        c.affirmations;
        c.info;
        c.fact;
      }
      for (final t in kStruggleTypes) {
        t.label;
      }
      for (final s in kSupportLines) {
        s.name;
        s.description;
      }
      for (final h in kHelpResources) {
        h.title;
        h.description;
      }
      for (final a in kAvatars) {
        a.name;
        a.nick;
      }
      for (final p in ThemePreset.values) {
        p.label;
      }
      for (final v in ModerationVerdict.values) {
        ModerationResult(v).message;
      }
      for (final c in kCountrySupport) {
        c.name;
        for (final l in c.allLines) {
          l.name;
          l.description;
        }
      }
      for (final h in kHelpResourcesGlobal) {
        h.title;
        h.description;
      }
      for (final b in computeBadges(
        best: 0,
        totalKind: 0,
        comeback: false,
        posts: 0,
        supportsGiven: 0,
        journal: 0,
        friends: 0,
      )) {
        b.title;
        b.how;
      }
    } finally {
      Tx.onLookup = null;
    }
    keys
      ..addAll(kNickAdjectives)
      ..addAll(QuoteEngine.allPoolTexts)
      ..addAll(kGeneralAffirmations)
      ..addAll(kKudosMessages)
      ..addAll(kNotePrompts)
      ..add(kGlobalFact)
      ..add(CommunityNote.anonymousName)
      ..addAll(LocalNotifier.nudges)
      ..addAll(LocalNotifier.nudgeTitles)
      ..addAll([for (final (t, b) in LocalNotifier.eveningReminders) ...[t, b]])
      ..addAll(LocalNotifier.dailyTitles)
      ..addAll(LocalNotifier.checkInInvites)
      ..addAll(LocalNotifier.checkInInvitesStreak)
      ..addAll(LocalNotifier.greetingTitles)
      ..add(LocalNotifier.testTitle)
      ..add(LocalNotifier.testBody);
    return keys;
  }

  final all = {...sourceKeys(), ...dataKeys()}..removeWhere((k) => k.trim().isEmpty);

  if (Platform.environment['DUMP_TX'] == '1') {
    test('anahtar listesini dök', () {
      final missing = all.where((k) => Tx.row(k) == null).toList()..sort();
      File('build/tx_keys.json')
        ..createSync(recursive: true)
        ..writeAsStringSync(const JsonEncoder.withIndent(' ').convert({'all': all.length, 'missing': missing}));
    });
    return;
  }

  test('her metnin 4 dilde çevirisi var', () {
    final missing = [
      for (final k in all)
        if (Tx.row(k) == null || Tx.row(k)!.length != 4 || Tx.row(k)!.any((s) => s.trim().isEmpty)) k,
    ];
    expect(missing, isEmpty, reason: 'Çevirisi eksik ${missing.length} metin:\n${missing.take(40).join('\n')}');
  });

  test('yer tutucular her dilde korunur', () {
    final bad = <String>[];
    for (final k in all) {
      final row = Tx.row(k);
      if (row == null) continue;
      final want = placeholderNames(k);
      for (var i = 0; i < row.length; i++) {
        if (!setEquals(placeholderNames(row[i]), want)) bad.add('[${langs[i]}] $k → ${row[i]}');
      }
    }
    expect(bad, isEmpty, reason: bad.take(20).join('\n'));
  });

  test('dil değişince metinler ve içerik değişir', () {
    addTearDown(() => Tx.code = 'tr');
    Tx.code = 'en';
    expect(tx('Paylaşım'), isNot('Paylaşım'));
    expect(StruggleCategory.anxiety.title, isNot(StruggleCategory.anxiety.titleTr));
    expect(kAvatars[4].nick, isNot('Sevimli Kurbağa'));
    Tx.code = 'tr';
    expect(kAvatars[4].nick, 'Sevimli Kurbağa');
  });

  test('çoğul biçim ve yer tutucu doldurma', () {
    expect(fillPlaceholders('{n} {n|day|days} left', {'n': 1}), '1 day left');
    expect(fillPlaceholders('{n} {n|day|days} left', {'n': 3}), '3 days left');
    expect(fillPlaceholders('{who} sent you a note', {'who': 'Ada'}), 'Ada sent you a note');
  });
}

bool setEquals(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);
