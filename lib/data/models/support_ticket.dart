import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../l10n/tx.dart';

/// Talep türü. `wire` Firestore'da saklanan değerdir (firestore.rules ile aynı).
enum TicketKind {
  idea('idea', Icons.lightbulb_outline_rounded),
  bug('bug', Icons.bug_report_outlined),
  help('help', Icons.help_outline_rounded),
  other('other', Icons.chat_bubble_outline_rounded),

  /// Topluluktaki bir paylaşım / yanıt için şikâyet (formda seçilmez; "Bildir"
  /// menüsünden otomatik oluşur, `target` içeriğin yolunu taşır).
  report('report', Icons.flag_outlined);

  const TicketKind(this.wire, this.icon);

  /// Destek formunda kullanıcının seçebildiği türler.
  static const selectable = [TicketKind.idea, TicketKind.bug, TicketKind.help, TicketKind.other];
  final String wire;
  final IconData icon;

  static TicketKind parse(String? s) => values.firstWhere((k) => k.wire == s, orElse: () => TicketKind.other);

  String get label => switch (this) {
    TicketKind.idea => tx('Öneri'),
    TicketKind.bug => tx('Hata bildir'),
    TicketKind.help => tx('Yardım'),
    TicketKind.other => tx('Diğer'),
    TicketKind.report => tx('Şikâyet'),
  };

  String get hint => switch (this) {
    TicketKind.idea => tx('Haven\'da neyi daha iyi yapabiliriz? Aklındaki özelliği ya da değişikliği anlat.'),
    TicketKind.bug => tx('Ne oldu, hangi ekranda? Ne yaptığında ortaya çıktı, ne olmasını beklerdin?'),
    TicketKind.help => tx('Takıldığın yeri yaz; sana yol gösterelim.'),
    TicketKind.other => tx('Aklındaki her şeyi yazabilirsin.'),
    TicketKind.report => '',
  };
}

/// Talebin durumu: yeni → okundu → planlandı → tamamlandı.
/// Yalnızca geliştirici değiştirebilir (firestore.rules).
enum TicketStatus {
  open('open', Icons.mark_email_unread_outlined),
  seen('seen', Icons.drafts_outlined),
  planned('planned', Icons.event_note_outlined),
  done('done', Icons.task_alt_rounded);

  const TicketStatus(this.wire, this.icon);
  final String wire;
  final IconData icon;

  static TicketStatus parse(String? s) => values.firstWhere((k) => k.wire == s, orElse: () => TicketStatus.open);

  /// Kullanıcının gözünden ("Gönderildi") ya da geliştiricinin gözünden ("Yeni").
  String label({bool developer = false}) => switch (this) {
    TicketStatus.open => developer ? tx('Yeni') : tx('Gönderildi'),
    TicketStatus.seen => tx('Okundu'),
    TicketStatus.planned => tx('Planlandı'),
    TicketStatus.done => tx('Tamamlandı'),
  };
}

/// `feedback/{id}` — kullanıcıdan geliştiriciye destek / öneri talebi.
/// Yalnızca sahibi ve geliştirici okuyabilir; toplulukta görünmez.
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.uid,
    required this.kind,
    required this.text,
    required this.status,
    required this.lang,
    this.platform = '',
    this.appVersion = '',
    this.nickname,
    this.target,
    this.reply,
    this.replyLang,
    this.createdAt,
    this.repliedAt,
  });

  static const minLength = 10;
  static const maxLength = 1500;

  final String id;
  final String uid;
  final TicketKind kind;
  final String text;
  final TicketStatus status;
  final String lang;
  final String platform;
  final String appVersion;

  /// Kullanıcı "takma adımı ekle" dediyse; yoksa talep isimsizdir.
  final String? nickname;

  /// Şikâyetlerde içeriğin yolu: `notes/{id}` ya da `notes/{id}/replies/{rid}`.
  final String? target;
  final String? reply;
  final String? replyLang;
  final DateTime? createdAt;
  final DateTime? repliedAt;

  bool get hasReply => reply != null && reply!.trim().isNotEmpty;

  /// Şikâyet edilen içerik bir yanıt mı?
  bool get targetsReply => target?.contains('/replies/') ?? false;

  /// firestore.rules → feedback.target ile aynı biçim.
  static final targetPattern = RegExp(r'^notes/[A-Za-z0-9]{1,40}(/replies/[A-Za-z0-9]{1,40})?$');

  factory SupportTicket.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return SupportTicket(
      id: d.id,
      uid: m['uid'] as String? ?? '',
      kind: TicketKind.parse(m['kind'] as String?),
      text: m['text'] as String? ?? '',
      status: TicketStatus.parse(m['status'] as String?),
      lang: m['lang'] as String? ?? 'tr',
      platform: m['platform'] as String? ?? '',
      appVersion: m['appVersion'] as String? ?? '',
      nickname: m['nickname'] as String?,
      target: m['target'] as String?,
      reply: m['reply'] as String?,
      replyLang: m['replyLang'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      repliedAt: (m['repliedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Yeniden eskiye; sunucu saati henüz gelmemiş (yeni yazılmış) talep en üstte.
  static int newestFirst(SupportTicket a, SupportTicket b) {
    final x = a.createdAt, y = b.createdAt;
    if (x == null) return y == null ? 0 : -1;
    if (y == null) return 1;
    return y.compareTo(x);
  }
}
