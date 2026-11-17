import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../models/community.dart';
import '../models/support_ticket.dart';

/// Destek ve öneri talepleri (`feedback/{id}`).
///
/// - Kullanıcı talep gönderir; aynı batch'te geliştiricinin bildirim kutusuna
///   "yeni talep" düşer (Blaze olmadan da uygulama içi bildirim çalışır).
/// - Geliştirici durumu değiştirir / yanıt yazar; kullanıcının bildirim
///   kutusuna "talebin güncellendi" düşer.
/// Erişim kuralları: firestore.rules → match /feedback/{id}.
class SupportRepository {
  SupportRepository(this._db, [this._developers = kDeveloperUids]);

  final FirebaseFirestore _db;
  final Set<String> _developers;

  CollectionReference<Map<String, dynamic>> get _tickets => _db.collection('feedback');
  CollectionReference<Map<String, dynamic>> _inbox(String uid) => _db.collection('users').doc(uid).collection('inbox');

  bool isDeveloper(String? uid) => uid != null && _developers.contains(uid);

  /// Kullanıcının kendi talepleri (bileşik dizin gerekmesin diye sıralama istemcide).
  Stream<List<SupportTicket>> watchMine(String uid) => _tickets
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((q) => q.docs.map(SupportTicket.fromDoc).toList()..sort(SupportTicket.newestFirst));

  /// Geliştirici paneli: tüm talepler, yeniden eskiye.
  Stream<List<SupportTicket>> watchAll() => _tickets
      .orderBy('createdAt', descending: true)
      .limit(300)
      .snapshots()
      .map((q) => q.docs.map(SupportTicket.fromDoc).toList()..sort(SupportTicket.newestFirst));

  static String? _nick(String? n) {
    final s = n?.trim() ?? '';
    if (s.isEmpty) return null;
    return s.length > 24 ? s.substring(0, 24) : s;
  }

  /// Sunucu onayladıysa `true`; internet yoksa `false` (talep kuyrukta
  /// bekler ve bağlantı gelince Firestore kendiliğinden gönderir).
  Future<bool> submit({
    required String uid,
    required TicketKind kind,
    required String text,
    required String lang,
    String? nickname,
    String? target,
  }) async {
    final nick = _nick(nickname);
    assert(target == null || SupportTicket.targetPattern.hasMatch(target));
    final batch = _db.batch()
      ..set(_tickets.doc(), {
        'uid': uid,
        'kind': kind.wire,
        'text': text.trim(),
        'status': TicketStatus.open.wire,
        'nickname': ?nick,
        'target': ?target,
        'lang': lang,
        'platform': defaultTargetPlatform.name,
        'appVersion': kAppVersion,
        'createdAt': FieldValue.serverTimestamp(),
      });
    for (final dev in _developers.where((d) => d != uid)) {
      batch.set(_inbox(dev).doc(), {
        'type': InboxType.feedbackNew.wire,
        'fromUid': uid,
        'fromNickname': ?nick,
        'value': kind.index,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }
    try {
      await batch.commit().timeout(const Duration(seconds: 12));
      return true;
    } on TimeoutException {
      return false;
    }
  }

  /// Topluluktaki bir paylaşımı / yanıtı geliştiriciye şikâyet eder.
  /// İçeriğin kısa bir alıntısı eklenir ki içerik silinse de neyin
  /// bildirildiği anlaşılsın.
  Future<bool> report({
    required String uid,
    required String target,
    required String reason,
    required String quote,
    required String lang,
  }) {
    final q = quote.trim().replaceAll(RegExp(r'\s+'), ' ');
    final cut = q.length > 300 ? '${q.substring(0, 300)}…' : q;
    return submit(uid: uid, kind: TicketKind.report, text: '$reason — “$cut”', lang: lang, target: target);
  }

  /// Geliştirici şikâyet edilen içeriği kaldırır ve talebi "tamamlandı" yapar.
  /// Yanıt siliniyorsa gönderinin yanıt sayacı da 1 azalır.
  Future<void> removeTarget(SupportTicket t, {required String developerUid}) async {
    final path = t.target;
    if (path == null || !SupportTicket.targetPattern.hasMatch(path)) return;
    final batch = _db.batch()..delete(_db.doc(path));
    if (t.targetsReply) {
      final note = _db.doc(path.split('/replies/').first);
      final snap = await note.get();
      if (snap.exists && ((snap.data()?['replyCount'] as num?) ?? 0) > 0) {
        batch.update(note, {'replyCount': FieldValue.increment(-1)});
      }
    }
    batch.update(_tickets.doc(t.id), {'status': TicketStatus.done.wire, 'updatedAt': FieldValue.serverTimestamp()});
    if (t.uid != developerUid) {
      batch.set(_inbox(t.uid).doc(), {
        'type': InboxType.feedbackReply.wire,
        'fromUid': developerUid,
        'fromNickname': 'Haven',
        'value': TicketStatus.done.index,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }
    await batch.commit().timeout(const Duration(seconds: 15));
  }

  /// Geliştirici talebi açınca: "yeni" → "okundu".
  void markSeen(SupportTicket t) {
    if (t.status != TicketStatus.open) return;
    unawaited(
      _tickets
          .doc(t.id)
          .update({'status': TicketStatus.seen.wire, 'updatedAt': FieldValue.serverTimestamp()})
          .catchError((Object e) => debugPrint('Talep güncellenemedi: $e')),
    );
  }

  /// Geliştiricinin yanıtı / durum değişikliği. Yeni bir yanıt yazıldıysa ya
  /// da talep planlandı / tamamlandı olduysa kullanıcıya bildirim gider.
  /// Bildirim gittiyse `true`.
  Future<bool> answer(
    SupportTicket t, {
    required String developerUid,
    required TicketStatus status,
    required String reply,
    required String replyLang,
  }) async {
    final r = reply.trim();
    final newReply = r.isNotEmpty && r != (t.reply ?? '').trim();
    final milestone = status != t.status && (status == TicketStatus.planned || status == TicketStatus.done);
    final notify = (newReply || milestone) && t.uid != developerUid;
    final batch = _db.batch()
      ..update(_tickets.doc(t.id), {
        'status': status.wire,
        if (newReply) 'reply': r,
        if (newReply) 'replyLang': replyLang,
        if (newReply) 'repliedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    if (notify) {
      batch.set(_inbox(t.uid).doc(), {
        'type': InboxType.feedbackReply.wire,
        'fromUid': developerUid,
        'fromNickname': 'Haven',
        'value': status.index,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }
    await batch.commit().timeout(const Duration(seconds: 15));
    return notify;
  }

  Future<void> delete(SupportTicket t) => _tickets.doc(t.id).delete().timeout(const Duration(seconds: 15));
}
