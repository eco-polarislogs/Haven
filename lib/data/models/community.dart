import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/struggle_catalog.dart';
import '../../core/utils/streak.dart';

DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;

/// `profiles/{uid}` — HERKESE AÇIK (giriş yapmış kullanıcılara).
/// Bilerek az bilgi: takma ad, avatar, seri. Gerçek ad, e-posta ve hangi
/// alanlarla mücadele edildiği burada YOK.
class PublicProfile {
  const PublicProfile({
    required this.uid,
    required this.nickname,
    required this.avatar,
    required this.friendCode,
    required this.daily,
  });

  final String uid;
  final String nickname;
  final int avatar;
  final String friendCode;
  final DailyStreak daily;

  factory PublicProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return PublicProfile(
      uid: d.id,
      nickname: m['nickname'] as String? ?? 'Haven üyesi',
      avatar: (m['avatar'] as num?)?.toInt() ?? 0,
      friendCode: m['friendCode'] as String? ?? '------',
      daily: DailyStreak(
        current: (m['dailyStreak'] as num?)?.toInt() ?? 0,
        longest: (m['longestDailyStreak'] as num?)?.toInt() ?? 0,
        lastDay: m['lastActivityDay'] as String?,
      ),
    );
  }
}

/// `notes/{noteId}` — bir çembere (kategoriye) paylaşılan destek notu.
class CommunityNote {
  const CommunityNote({
    required this.id,
    required this.authorUid,
    required this.nickname,
    required this.avatar,
    required this.streak,
    required this.circle,
    required this.text,
    required this.createdAt,
    required this.supportCount,
    required this.reportCount,
    this.replyCount = 0,
    this.anonymous = false,
  });

  /// Anonim gönderilerde görünen ad.
  static const anonymousName = 'Anonim üye';

  final String id;

  /// Anonim gönderilerde BOŞ: yazarın kimliği herkese açık belgede tutulmaz;
  /// sahiplik yalnızca yazarın kendi özel `users/{uid}/myNotes` kaydındadır.
  final String authorUid;
  final bool anonymous;
  final String nickname;
  final int avatar;
  final int streak;
  final StruggleCategory? circle;
  final String text;
  final DateTime? createdAt;
  final int supportCount;
  final int reportCount;
  final int replyCount;

  /// 3 ve üzeri bildirimde not akıştan kalkar.
  bool get hidden => reportCount >= 3;

  factory CommunityNote.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return CommunityNote(
      id: d.id,
      authorUid: m['authorUid'] as String? ?? '',
      nickname: m['nickname'] as String? ?? 'Haven üyesi',
      avatar: (m['avatar'] as num?)?.toInt() ?? 0,
      streak: (m['streak'] as num?)?.toInt() ?? 0,
      circle: categoryByName(m['circleId'] as String?),
      text: m['text'] as String? ?? '',
      createdAt: _date(m['createdAt']),
      supportCount: (m['supportCount'] as num?)?.toInt() ?? 0,
      reportCount: (m['reportCount'] as num?)?.toInt() ?? 0,
      replyCount: (m['replyCount'] as num?)?.toInt() ?? 0,
      anonymous: m['anonymous'] == true,
    );
  }
}

/// `notes/{noteId}/replies/{id}` — bir gönderiye yanıt (aynı sıkı denetimden geçer).
class NoteReply {
  const NoteReply({
    required this.id,
    required this.authorUid,
    required this.nickname,
    required this.avatar,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String authorUid;
  final String nickname;
  final int avatar;
  final String text;
  final DateTime? createdAt;

  factory NoteReply.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return NoteReply(
      id: d.id,
      authorUid: m['authorUid'] as String? ?? '',
      nickname: m['nickname'] as String? ?? 'Haven üyesi',
      avatar: (m['avatar'] as num?)?.toInt() ?? 0,
      text: m['text'] as String? ?? '',
      createdAt: _date(m['createdAt']),
    );
  }
}

enum InboxType {
  welcome('welcome'),
  login('login'),
  logout('logout'),
  friendAdded('friend_added'),
  kudos('kudos'),
  noteSupport('note_support'),
  noteReply('note_reply'),
  friendStreak('friend_streak'),
  streakMilestone('streak_milestone'),
  supportSuggestion('support_suggestion'),
  unknown('unknown');

  const InboxType(this.wire);
  final String wire;

  static InboxType parse(String? s) =>
      InboxType.values.firstWhere((t) => t.wire == s, orElse: () => InboxType.unknown);
}

/// `users/{uid}/inbox/{id}` — uygulama içi bildirim merkezi.
/// Başka kullanıcılar buraya YALNIZCA hazır mesaj kimliği (messageId)
/// yazabilir; serbest metin yok (firestore.rules).
class InboxItem {
  const InboxItem({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.read,
    this.fromUid,
    this.fromNickname,
    this.fromAvatar,
    this.messageId,
    this.value,
  });

  final String id;
  final InboxType type;
  final DateTime? createdAt;
  final bool read;
  final String? fromUid;
  final String? fromNickname;
  final int? fromAvatar;
  final int? messageId;
  final int? value;

  factory InboxItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return InboxItem(
      id: d.id,
      type: InboxType.parse(m['type'] as String?),
      createdAt: _date(m['createdAt']),
      read: m['read'] as bool? ?? false,
      fromUid: m['fromUid'] as String?,
      fromNickname: m['fromNickname'] as String?,
      fromAvatar: (m['fromAvatar'] as num?)?.toInt(),
      messageId: (m['messageId'] as num?)?.toInt(),
      value: (m['value'] as num?)?.toInt(),
    );
  }

  String get _who => fromNickname ?? 'Bir arkadaşın';

  String get title => switch (type) {
        InboxType.welcome => 'Haven\'a hoş geldin',
        InboxType.login => 'Hesabına giriş yapıldı',
        InboxType.logout => 'Hesabından çıkış yapıldı',
        InboxType.friendAdded => '$_who seni arkadaş olarak ekledi',
        InboxType.kudos => '$_who sana bir not gönderdi',
        InboxType.noteSupport => '$_who paylaşımına destek verdi',
        InboxType.noteReply => '$_who paylaşımına yanıt verdi',
        InboxType.friendStreak => '$_who ${value ?? ''} günlük seriye ulaştı',
        InboxType.streakMilestone => '${value ?? ''} günlük seri!',
        InboxType.supportSuggestion => 'Seni düşünüyoruz',
        InboxType.unknown => 'Haven',
      };

  String get body => switch (type) {
        InboxType.welcome => 'Burası senin güvenli limanın. Kendi hızında, yargısız.',
        InboxType.login => 'Bu sen değilsen hemen Profil → Çıkış yap\'a dokun.',
        InboxType.logout => 'Bir dahaki sefere görüşmek üzere.',
        InboxType.friendAdded => 'Artık birbirinizin serisini görebilir, cesaret notu gönderebilirsiniz.',
        InboxType.kudos => (messageId != null && messageId! < kKudosMessages.length)
            ? kKudosMessages[messageId!]
            : 'Seni düşünüyor.',
        InboxType.noteSupport => 'Paylaştığın not birine iyi geldi. 💙',
        InboxType.noteReply => 'Topluluk sekmesinden yanıtı okuyabilirsin.',
        InboxType.friendStreak => 'Ona bir cesaret notu göndermeye ne dersin?',
        InboxType.streakMilestone => 'Kendine her gün geri döndün. Bu çok değerli.',
        InboxType.supportSuggestion =>
          'Son günlerin zor geçmiş görünüyor. Bir uzmanla konuşmak iyi gelebilir; Destek al bölümüne göz at.',
        InboxType.unknown => '',
      };

  IconData get icon => switch (type) {
        InboxType.welcome => Icons.waving_hand_outlined,
        InboxType.login => Icons.login_rounded,
        InboxType.logout => Icons.logout_rounded,
        InboxType.friendAdded => Icons.person_add_alt_1_outlined,
        InboxType.kudos => Icons.favorite_border_rounded,
        InboxType.noteSupport => Icons.volunteer_activism_outlined,
        InboxType.noteReply => Icons.chat_bubble_outline_rounded,
        InboxType.friendStreak => Icons.local_fire_department_outlined,
        InboxType.streakMilestone => Icons.local_fire_department_rounded,
        InboxType.supportSuggestion => Icons.volunteer_activism_outlined,
        InboxType.unknown => Icons.notifications_none_rounded,
      };
}
