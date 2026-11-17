import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/struggle_catalog.dart';
import '../../core/utils/day_key.dart';
import '../../core/utils/streak.dart';
import '../models/app_user.dart';
import '../models/community.dart';
import '../models/journal_entry.dart';
import '../models/month_log.dart';
import '../models/struggle.dart';

class CheckInOutcome {
  const CheckInOutcome(this.state, {this.gapDays, this.daily});
  final StreakState state;

  /// Bu alandaki bir önceki check-in'den bu yana geçen gün (Analytics için).
  final int? gapDays;

  /// Günün ilk kaydıysa yeni günlük seri; değilse null.
  final DailyStreak? daily;
}

/// Kişisel (özel) verilerin tüm Firestore erişimi. Şema: docs/FIRESTORE_SCHEMA.md
///
/// OFFLINE KURALI: Firestore'da yazma Future'ı ancak SUNUCU onayladığında
/// tamamlanır. İnternet yokken `await batch.commit()` sonsuza kadar bekler.
/// Bu yüzden kullanıcı yazmalarını `await` ETMİYORUZ: yerel önbellek anında
/// güncellenir, dinleyiciler yeni veriyi hemen gösterir.
class HavenRepository {
  HavenRepository(this._db);

  final FirebaseFirestore _db;
  final _lastTouch = <String, DateTime>{};

  DocumentReference<Map<String, dynamic>> _user(String uid) => _db.collection('users').doc(uid);
  CollectionReference<Map<String, dynamic>> _struggles(String uid) =>
      _user(uid).collection('struggles');
  CollectionReference<Map<String, dynamic>> _checkins(String uid) =>
      _user(uid).collection('checkins');
  CollectionReference<Map<String, dynamic>> _inbox(String uid) => _user(uid).collection('inbox');

  static final _merge = SetOptions(merge: true);

  // ---------------------------------------------------------------- okumalar

  Stream<AppUser?> watchUser(String uid) => _user(uid)
      .snapshots()
      // Yeni cihazda önbellek boşken gelen "doküman yok" görüntüsünü yok say.
      .where((s) => s.exists || !s.metadata.isFromCache)
      .map((s) => s.exists ? AppUser.fromMap(uid, s.data()!) : null);

  Stream<List<Struggle>> watchStruggles(String uid) => _struggles(uid)
      .where('active', isEqualTo: true)
      .snapshots()
      .map((q) => q.docs
          .map((d) => Struggle.fromMap(d.id, d.data()))
          .whereType<Struggle>()
          .toList()
        ..sort((a, b) => kStruggleTypes.indexOf(a.type) - kStruggleTypes.indexOf(b.type)));

  Stream<MonthLog> watchMonth(String uid, String month) =>
      _checkins(uid).doc(month).snapshots().map((s) => MonthLog.fromMap(s.data()));

  // ---------------------------------------------------------------- oturum

  /// Girişten hemen sonra çağrılır (internet zaten var).
  Future<void> ensureUserDoc(User user) async {
    final ref = _user(user.uid);
    final snap = await ref.get();
    if (snap.exists) {
      touchActive(user.uid, force: true);
      return;
    }
    await ref.set({
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
      'utcOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
      'locale': 'tr',
      'struggleIds': <String>[],
      'categoryIds': <String>[],
      'notificationsEnabled': true,
      'analyticsEnabled': true,
      'communityJoined': false,
      'themeId': 'light',
      'fcmFids': <String>[],
    });
  }

  /// Bildirim zamanlayıcısının baktığı alan: `lastActiveAt` (15 dk kısıtlı).
  void touchActive(String uid, {bool force = false}) {
    final now = DateTime.now();
    final last = _lastTouch[uid];
    if (!force && last != null && now.difference(last).inMinutes < 15) return;
    _lastTouch[uid] = now;
    _fireAndForget(_user(uid).set({
      'lastActiveAt': FieldValue.serverTimestamp(),
      'utcOffsetMinutes': now.timeZoneOffset.inMinutes,
    }, _merge));
  }

  // ---------------------------------------------------------------- kayıt

  /// Kayıt akışının sonu: profil + alanlar + rıza tek batch'te.
  void completeOnboarding(
    String uid, {
    required String nickname,
    required int avatar,
    required bool anonymous,
    required Set<String> selected,
    required Set<String> previous,
    required bool communityJoined,
  }) {
    final batch = _db.batch();
    _writeStruggleChanges(batch, uid, selected, previous);
    batch.set(_user(uid), {
      'nickname': nickname,
      'avatar': avatar,
      'anonymous': anonymous,
      'communityJoined': communityJoined,
      ..._selectionFields(selected),
      'consent': {'version': 2, 'at': FieldValue.serverTimestamp()},
    }, _merge);
    _fireAndForget(batch.commit());
  }

  /// Profil → "Mücadele alanlarım" düzenleme.
  void saveStruggles(String uid, Set<String> selected, {required Set<String> previous}) {
    final batch = _db.batch();
    _writeStruggleChanges(batch, uid, selected, previous);
    batch.set(_user(uid), _selectionFields(selected), _merge);
    _fireAndForget(batch.commit());
  }

  void updateIdentity(String uid, {required String nickname, required int avatar, bool? anonymous}) =>
      _fireAndForget(_user(uid).set({
        'nickname': nickname,
        'avatar': avatar,
        'anonymous': ?anonymous,
      }, _merge));

  void setAdsOptIn(String uid, bool value) =>
      _fireAndForget(_user(uid).set({'adsOptIn': value}, _merge));

  void setLanguage(String uid, String? code) =>
      _fireAndForget(_user(uid).set({'language': code}, _merge));

  // ---------------------------------------------------------------- özel notlar (günlük)

  CollectionReference<Map<String, dynamic>> _journal(String uid) => _user(uid).collection('journal');

  Stream<List<JournalEntry>> watchJournal(String uid, {int limit = 30}) => _journal(uid)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((q) => q.docs.map(JournalEntry.fromDoc).toList());

  void addJournal(String uid, String text) => _fireAndForget(_journal(uid).add({
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }));

  void deleteJournal(String uid, String id) => _fireAndForget(_journal(uid).doc(id).delete());

  void setCommunityJoined(String uid, bool value) =>
      _fireAndForget(_user(uid).set({'communityJoined': value}, _merge));

  Map<String, Object> _selectionFields(Set<String> selected) => {
        'struggleIds': selected.toList(),
        // Cloud Function ve topluluk kuralları alt koleksiyon okumadan
        // kategoriyi bilsin diye (denormalize).
        'categoryIds':
            selected.map((id) => struggleTypeById(id)!.category.name).toSet().toList(),
      };

  void _writeStruggleChanges(WriteBatch batch, String uid, Set<String> selected, Set<String> previous) {
    for (final id in selected.difference(previous)) {
      batch.set(_struggles(uid).doc(id), {
        'typeId': id,
        'categoryId': struggleTypeById(id)!.category.name,
        'active': true,
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, _merge);
    }
    for (final id in previous.difference(selected)) {
      // Silinmez, pasifleşir: geri eklenirse geçmiş korunur.
      batch.set(_struggles(uid).doc(id), {
        'active': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, _merge);
    }
  }

  // ---------------------------------------------------------------- check-in

  /// Tek batch: ay dokümanı + alanın seri sayaçları + günlük seri.
  /// Offline'da kuyruğa alınır. `null` → bu alan için bugün zaten kayıt var.
  CheckInOutcome? checkIn(String uid, Struggle struggle, CheckInResult result,
      {required DailyStreak daily}) {
    final now = DateTime.now();
    final today = dayKey(now);
    final next = applyCheckIn(struggle.streak, today, result);
    if (next == null) return null;
    final nextDaily = applyDailyActivity(daily, today);

    final batch = _db.batch();
    batch.set(_checkins(uid).doc(monthKey(now)), {
      'days': {
        dayOfMonthKey(now): {struggle.id: result.name},
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, _merge);
    batch.set(_struggles(uid).doc(struggle.id), {
      'currentStreak': next.current,
      'longestStreak': next.longest,
      'totalKindDays': next.totalKindDays,
      'lastKindDay': next.lastKindDay,
      'lastCheckInDay': today,
      'lastResult': result.name,
      // Biten seriler silinmez (I Am Sober mantığı): rekorla yarış için.
      'history': [for (final p in next.history) p.toMap()],
      'updatedAt': FieldValue.serverTimestamp(),
    }, _merge);
    batch.set(_user(uid), {
      'lastActiveAt': FieldValue.serverTimestamp(),
      'lastCheckInDay': today,
      if (nextDaily != null) ...{
        'dailyStreak': nextDaily.current,
        'longestDailyStreak': nextDaily.longest,
        'lastActivityDay': nextDaily.lastDay,
      },
    }, _merge);
    _fireAndForget(batch.commit());

    final last = struggle.streak.lastCheckInDay;
    return CheckInOutcome(next,
        gapDays: last == null ? null : daysBetween(last, today), daily: nextDaily);
  }

  // ---------------------------------------------------------------- bildirim kutusu

  /// Kullanıcının KENDİ bildirim kutusuna olay ekler (giriş, çıkış, seri…).
  void addInbox(String uid, InboxType type, {int? value}) =>
      _fireAndForget(_inbox(uid).add({
        'type': type.wire,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'value': ?value,
      }));

  /// Çıkıştan hemen önce: yazmanın sunucuya ulaşmasını kısa süre bekle.
  Future<void> addInboxAndWait(String uid, InboxType type) async {
    try {
      await _inbox(uid).add({
        'type': type.wire,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      }).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  void markSupportSuggested(String uid, String day) =>
      _fireAndForget(_user(uid).set({'lastSupportSuggestionDay': day}, _merge));

  // ---------------------------------------------------------------- ayarlar

  void addFcmFid(String uid, String fid) =>
      _fireAndForget(_user(uid).set({'fcmFids': FieldValue.arrayUnion([fid])}, _merge));

  Future<void> removeFcmFid(String uid, String fid) =>
      _user(uid).update({'fcmFids': FieldValue.arrayRemove([fid])});

  void setNotificationsEnabled(String uid, bool value) =>
      _fireAndForget(_user(uid).set({'notificationsEnabled': value}, _merge));

  void setAnalyticsEnabled(String uid, bool value) =>
      _fireAndForget(_user(uid).set({'analyticsEnabled': value}, _merge));

  void setTheme(String uid, String themeId) =>
      _fireAndForget(_user(uid).set({'themeId': themeId}, _merge));

  /// Ödüllü reklam sonrası. MVP notu: ödülü istemci yazıyor (sadece bir tema).
  void unlockTheme(String uid, String themeId) => _fireAndForget(_user(uid).set({
        'unlocks': {themeId: FieldValue.serverTimestamp()},
        'themeId': themeId,
      }, _merge));

  /// Hediye (tema/avatar) reklamla açıldığında. Seriyle açılanlar yazılmaz;
  /// en iyi seriden hesaplanır.
  void unlockGift(String uid, String id) =>
      _fireAndForget(_user(uid).set({'unlocks': {id: FieldValue.serverTimestamp()}}, _merge));

  void unlockDailyQuote(String uid, String day) =>
      _fireAndForget(_user(uid).set({'quoteUnlockedDay': day}, _merge));

  // ---------------------------------------------------------------- hesap silme

  /// Hesap silme: internet ŞART. Önce sunucuya erişimi doğrula.
  /// Kişisel veriler + topluluk izleri (profil, notlar, arkadaşlıklar) silinir.
  Future<void> deleteAllUserData(String uid) async {
    const server = GetOptions(source: Source.server);
    await _user(uid).get(server);

    Future<void> deleteAll(Query<Map<String, dynamic>> q) async {
      final docs = await q.get(server);
      for (var i = 0; i < docs.docs.length; i += 400) {
        final batch = _db.batch();
        for (final d in docs.docs.skip(i).take(400)) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    }

    // Arkadaşlarımın listesinden kendimi çıkar.
    final friends = await _user(uid).collection('friends').get(server);
    final unfriend = _db.batch();
    for (final f in friends.docs) {
      unfriend.delete(_user(f.id).collection('friends').doc(uid));
      unfriend.delete(f.reference);
    }
    await unfriend.commit();

    // Başkalarının gönderilerine yazdığım yanıtlar (sayaçla birlikte).
    final replies =
        await _db.collectionGroup('replies').where('authorUid', isEqualTo: uid).get(server);
    for (final r in replies.docs) {
      final note = r.reference.parent.parent;
      try {
        final batch = _db.batch()..delete(r.reference);
        if (note != null) batch.update(note, {'replyCount': FieldValue.increment(-1)});
        await batch.commit();
      } on FirebaseException {
        await r.reference.delete(); // gönderi zaten silinmiş
      }
    }

    // Anonim gönderilerim: kimliğim gönderide yok; sahiplik özel kaydımda.
    final myNotes = await _user(uid).collection('myNotes').get(server);
    for (final n in myNotes.docs) {
      try {
        await (_db.batch()
              ..delete(_db.collection('notes').doc(n.id))
              ..delete(n.reference))
            .commit();
      } on FirebaseException {
        await n.reference.delete();
      }
    }

    await deleteAll(_db.collection('notes').where('authorUid', isEqualTo: uid));
    await deleteAll(_struggles(uid));
    await deleteAll(_checkins(uid));
    await deleteAll(_inbox(uid));
    await deleteAll(_journal(uid));
    await _db.collection('profiles').doc(uid).delete();
    await _user(uid).delete();
  }

  void _fireAndForget(Future<void> write) {
    unawaited(write.catchError((Object e) => debugPrint('Firestore yazma hatası: $e')));
  }
}
