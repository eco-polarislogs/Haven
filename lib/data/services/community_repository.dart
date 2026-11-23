import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/struggle_catalog.dart';
import '../../core/utils/streak.dart';
import '../../l10n/tx.dart';
import '../models/community.dart';

/// Topluluk: profiller, notlar, destekler, bildirimler, arkadaşlıklar.
///
/// Güvenlik firestore.rules ile sunucuda zorlanır:
///  - not metni sunucuda da kaba ifade filtresinden geçer,
///  - bir not yalnızca yazarın kendi seçtiği çembere paylaşılabilir,
///  - destek/şikayet kişi başı 1 kez (sayaç + kişisel kayıt aynı batch'te),
///  - başkasının bildirim kutusuna yalnızca hazır mesaj kimliği yazılabilir.
class CommunityRepository {
  CommunityRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _profiles => _db.collection('profiles');
  CollectionReference<Map<String, dynamic>> get _notes => _db.collection('notes');
  DocumentReference<Map<String, dynamic>> _user(String uid) => _db.collection('users').doc(uid);
  CollectionReference<Map<String, dynamic>> _friends(String uid) => _user(uid).collection('friends');
  CollectionReference<Map<String, dynamic>> _inbox(String uid) => _user(uid).collection('inbox');

  // ---------------------------------------------------------------- profil

  Stream<PublicProfile?> watchProfile(String uid) =>
      _profiles.doc(uid).snapshots().map((d) => d.exists ? PublicProfile.fromDoc(d) : null);

  /// Kayıtta ve profil düzenlemede. Arkadaş kodu ilk oluşturmada atanır, değişmez.
  Future<void> ensureProfile(
    String uid, {
    required String nickname,
    required int avatar,
    required DailyStreak daily,
  }) async {
    final ref = _profiles.doc(uid);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.set({
        'nickname': nickname,
        'avatar': avatar,
        'friendCode': snap.data()!['friendCode'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }
    await ref.set({
      'nickname': nickname,
      'avatar': avatar,
      'friendCode': generateFriendCode(),
      'dailyStreak': daily.current,
      'longestDailyStreak': daily.longest,
      'lastActivityDay': daily.lastDay,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Topluluğa katılmış ama herkese açık profili hiç oluşmamış kullanıcı için
  /// (ör. kayıt ya da katılma anında internet yoktu). Profil yoksa paylaşım,
  /// yanıt ve arkadaş ekleme "Profil hazırlanıyor…" durumunda takılı kalır.
  /// Oturum her açıldığında çağrılır; profil varsa hiçbir şey yazmaz.
  Future<void> repairProfile(
    String uid, {
    required String nickname,
    required int avatar,
    required DailyStreak daily,
  }) async {
    final snap = await _profiles.doc(uid).get();
    if (snap.exists) return;
    await ensureProfile(uid, nickname: nickname, avatar: avatar, daily: daily);
  }

  /// Arkadaşların seriyi görebilmesi için herkese açık profile yansıt.
  void syncStreak(String uid, PublicProfile profile, DailyStreak daily) => _fireAndForget(
    _profiles.doc(uid).set({
      'nickname': profile.nickname,
      'friendCode': profile.friendCode,
      'dailyStreak': daily.current,
      'longestDailyStreak': daily.longest,
      'lastActivityDay': daily.lastDay,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)),
  );

  Stream<List<PublicProfile>> watchProfiles(List<String> uids) {
    if (uids.isEmpty) return Stream.value(const []);
    return _profiles
        .where(FieldPath.documentId, whereIn: uids.take(30).toList())
        .snapshots()
        .map((q) => q.docs.map(PublicProfile.fromDoc).toList()..sort((a, b) => b.daily.current - a.daily.current));
  }

  Future<PublicProfile?> findByFriendCode(String code) async {
    final q = await _profiles.where('friendCode', isEqualTo: code.trim().toUpperCase()).limit(1).get();
    return q.docs.isEmpty ? null : PublicProfile.fromDoc(q.docs.first);
  }

  // ---------------------------------------------------------------- notlar

  /// Kullanıcının çemberlerindeki son notlar (birleşik akış).
  Stream<List<CommunityNote>> watchFeed(List<String> circleIds) {
    if (circleIds.isEmpty) return Stream.value(const []);
    return _notes
        .where('circleId', whereIn: circleIds.take(30).toList())
        .orderBy('createdAt', descending: true)
        .limit(60)
        .snapshots()
        .map((q) => q.docs.map(CommunityNote.fromDoc).toList());
  }

  /// Tek bir gönderinin canlı hali (detay ekranı): destek/yanıt sayıları anında
  /// güncellenir; gönderi silinir ya da geliştirici kaldırırsa `null` gelir.
  Stream<CommunityNote?> watchNote(String noteId) => _notes
      .doc(noteId)
      .snapshots()
      // Çevrimdışıyken önbellekte olmayan gönderi "silinmiş" sanılmasın.
      .where((d) => d.exists || !d.metadata.isFromCache)
      .map((d) => d.exists ? CommunityNote.fromDoc(d) : null);

  /// [anonymous] true ise gönderide ad, avatar, seri ve yazar kimliği YOK;
  /// sahiplik (silebilmek için) aynı batch'te yazarın özel kaydına yazılır.
  Future<void> postNote({
    required PublicProfile author,
    required StruggleCategory circle,
    required String text,
    required int streak,
    bool anonymous = false,
  }) {
    final ref = _notes.doc();
    final common = {
      'circleId': circle.name,
      // Sunucu filtresinin satır atlamayla atlatılmaması için tek satır.
      'text': text.trim().replaceAll(RegExp(r'\s+'), ' '),
      'createdAt': FieldValue.serverTimestamp(),
      'supportCount': 0,
      'reportCount': 0,
      // Okuyan farklı dildeyse "Çevir" düğmesi için.
      'lang': Tx.code,
    };
    final batch = _db.batch();
    if (anonymous) {
      batch
        ..set(ref, {...common, 'anonymous': true, 'nickname': CommunityNote.anonymousName, 'avatar': -1, 'streak': 0})
        ..set(_myNotes(author.uid).doc(ref.id), {'at': FieldValue.serverTimestamp()});
    } else {
      batch.set(ref, {
        ...common,
        'anonymous': false,
        'authorUid': author.uid,
        'nickname': author.nickname,
        'avatar': author.avatar,
        'streak': streak,
      });
    }
    return batch.commit().timeout(const Duration(seconds: 15));
  }

  CollectionReference<Map<String, dynamic>> _myNotes(String uid) => _user(uid).collection('myNotes');

  /// Kullanıcının anonim gönderilerinin kimlikleri (yalnızca kendisi okuyabilir).
  Stream<Set<String>> watchMyAnonNoteIds(String uid) =>
      _myNotes(uid).snapshots().map((q) => q.docs.map((d) => d.id).toSet());

  Future<void> supportNote(CommunityNote note, PublicProfile me) {
    final ref = _notes.doc(note.id);
    final batch = _db.batch()
      ..set(ref.collection('supports').doc(me.uid), {'at': FieldValue.serverTimestamp()})
      ..update(ref, {'supportCount': FieldValue.increment(1)})
      ..set(_user(me.uid), {
        'supportedNotes': FieldValue.arrayUnion([note.id]),
      }, SetOptions(merge: true));
    // Anonim gönderinin yazarı bilinmez → bildirim gönderilmez.
    if (note.authorUid.isNotEmpty && note.authorUid != me.uid) {
      batch.set(_inbox(note.authorUid).doc(), _fromMe(me, InboxType.noteSupport));
    }
    return batch.commit().timeout(const Duration(seconds: 15));
  }

  Future<void> reportNote(CommunityNote note, String myUid, String reason) {
    final ref = _notes.doc(note.id);
    final batch = _db.batch()
      ..set(ref.collection('reports').doc(myUid), {'reason': reason, 'at': FieldValue.serverTimestamp()})
      ..update(ref, {'reportCount': FieldValue.increment(1)})
      ..set(_user(myUid), {
        'reportedNotes': FieldValue.arrayUnion([note.id]),
      }, SetOptions(merge: true));
    return batch.commit().timeout(const Duration(seconds: 15));
  }

  /// Gönderiyi ve (anonimse) yazarın özel sahiplik kaydını birlikte siler.
  Future<void> deleteNote(String noteId, String myUid) =>
      (_db.batch()
            ..delete(_notes.doc(noteId))
            ..delete(_myNotes(myUid).doc(noteId)))
          .commit()
          .timeout(const Duration(seconds: 15));

  /// "Arkadaşlar" akışı: arkadaşlarının (ve senin) son paylaşımları.
  Stream<List<CommunityNote>> watchAuthorsFeed(List<String> authorIds) {
    if (authorIds.isEmpty) return Stream.value(const []);
    return _notes
        .where('authorUid', whereIn: authorIds.take(30).toList())
        .orderBy('createdAt', descending: true)
        .limit(60)
        .snapshots()
        .map((q) => q.docs.map(CommunityNote.fromDoc).toList());
  }

  Stream<List<NoteReply>> watchReplies(String noteId) => _notes
      .doc(noteId)
      .collection('replies')
      .orderBy('createdAt')
      .limit(100)
      .snapshots()
      .map((q) => q.docs.map(NoteReply.fromDoc).toList());

  /// Yanıt + sayaç + gönderi sahibine bildirim, tek batch.
  Future<void> postReply(CommunityNote note, PublicProfile me, String text) {
    final ref = _notes.doc(note.id);
    final batch = _db.batch()
      ..set(ref.collection('replies').doc(), {
        'authorUid': me.uid,
        'nickname': me.nickname,
        'avatar': me.avatar,
        'text': text.trim().replaceAll(RegExp(r'\s+'), ' '),
        'createdAt': FieldValue.serverTimestamp(),
        'lang': Tx.code,
      })
      ..update(ref, {'replyCount': FieldValue.increment(1)});
    if (note.authorUid.isNotEmpty && note.authorUid != me.uid) {
      batch.set(_inbox(note.authorUid).doc(), _fromMe(me, InboxType.noteReply));
    }
    return batch.commit().timeout(const Duration(seconds: 15));
  }

  /// Yanıtı siler ve sayacı 1 azaltır (gönderi silinmişse yalnızca yanıtı).
  Future<void> deleteReply(String noteId, String replyId) async {
    final note = _notes.doc(noteId);
    final reply = note.collection('replies').doc(replyId);
    try {
      await (_db.batch()
            ..delete(reply)
            ..update(note, {'replyCount': FieldValue.increment(-1)}))
          .commit()
          .timeout(const Duration(seconds: 15));
    } on FirebaseException {
      await reply.delete();
    }
  }

  // ---------------------------------------------------------------- arkadaşlar

  Stream<List<String>> watchFriendIds(String uid) =>
      _friends(uid).snapshots().map((q) => q.docs.map((d) => d.id).toList());

  /// Karşılıklı arkadaşlık + karşı tarafa bildirim, tek batch.
  Future<void> addFriend(PublicProfile me, PublicProfile other) {
    final batch = _db.batch()
      ..set(_friends(me.uid).doc(other.uid), {'since': FieldValue.serverTimestamp()})
      ..set(_friends(other.uid).doc(me.uid), {'since': FieldValue.serverTimestamp()})
      ..set(_inbox(other.uid).doc(), _fromMe(me, InboxType.friendAdded));
    return batch.commit().timeout(const Duration(seconds: 15));
  }

  Future<void> removeFriend(String myUid, String otherUid) {
    final batch = _db.batch()
      ..delete(_friends(myUid).doc(otherUid))
      ..delete(_friends(otherUid).doc(myUid));
    return batch.commit().timeout(const Duration(seconds: 15));
  }

  // ---------------------------------------------------------------- engelleme

  /// Kullanıcıyı engeller: listeme eklenir, arkadaşlık iki taraftan da silinir.
  /// Sunucu kuralı engellenen kişinin bana arkadaşlık / not / bildirim
  /// göndermesini reddeder; istemci de paylaşımlarını ve yanıtlarını gizler.
  Future<void> blockUser(String myUid, String otherUid) {
    final batch = _db.batch()
      ..set(_user(myUid), {
        'blockedUids': FieldValue.arrayUnion([otherUid]),
      }, SetOptions(merge: true))
      ..delete(_friends(myUid).doc(otherUid))
      ..delete(_friends(otherUid).doc(myUid));
    return batch.commit().timeout(const Duration(seconds: 15));
  }

  Future<void> unblockUser(String myUid, String otherUid) => _user(myUid).set({
    'blockedUids': FieldValue.arrayRemove([otherUid]),
  }, SetOptions(merge: true)).timeout(const Duration(seconds: 15));

  /// Bildirilen yanıt benim için hemen gizlenir (geliştiriciye giden şikâyet
  /// SupportRepository.report ile ayrıca yazılır).
  Future<void> hideReply(String myUid, String replyId) => _user(myUid).set({
    'reportedReplies': FieldValue.arrayUnion([replyId]),
  }, SetOptions(merge: true)).timeout(const Duration(seconds: 15));

  Future<void> sendKudos(PublicProfile me, String friendUid, int messageId) =>
      _inbox(friendUid).add(_fromMe(me, InboxType.kudos, messageId: messageId)).timeout(const Duration(seconds: 15));

  void notifyFriendsOfMilestone(PublicProfile me, List<String> friendIds, int days) {
    if (friendIds.isEmpty) return;
    // Kural her bildirimde alıcının engel listesine bakar (get); Firestore bir
    // batch'te en fazla 20 erişime izin verdiği için 15'erli gönderilir.
    final ids = friendIds.take(400).toList();
    for (var i = 0; i < ids.length; i += 15) {
      final batch = _db.batch();
      for (final f in ids.skip(i).take(15)) {
        batch.set(_inbox(f).doc(), _fromMe(me, InboxType.friendStreak, value: days));
      }
      _fireAndForget(batch.commit());
    }
  }

  Map<String, Object> _fromMe(PublicProfile me, InboxType type, {int? messageId, int? value}) => {
    'type': type.wire,
    'fromUid': me.uid,
    'fromNickname': me.nickname,
    'fromAvatar': me.avatar,
    'messageId': ?messageId,
    'value': ?value,
    'createdAt': FieldValue.serverTimestamp(),
    'read': false,
  };

  // ---------------------------------------------------------------- bildirim kutusu

  Stream<List<InboxItem>> watchInbox(String uid) =>
      _inbox(uid)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots()
          .map((q) => q.docs.map(InboxItem.fromDoc).toList());

  void markRead(String uid, String itemId) => _fireAndForget(_inbox(uid).doc(itemId).update({'read': true}));

  void markAllRead(String uid, Iterable<String> ids) {
    final batch = _db.batch();
    for (final id in ids.take(400)) {
      batch.update(_inbox(uid).doc(id), {'read': true});
    }
    _fireAndForget(batch.commit());
  }

  void _fireAndForget(Future<void> write) {
    unawaited(write.catchError((Object e) => debugPrint('Topluluk yazma hatası: $e')));
  }
}
