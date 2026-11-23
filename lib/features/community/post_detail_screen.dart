import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/moderation/content_moderator.dart';
import '../../core/navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/avatar_badge.dart';
import '../../data/models/community.dart';
import '../../providers.dart';
import '../support/hard_day_sheet.dart';
import 'moderation_actions.dart';
import 'post_card.dart';
import 'translatable_text.dart';
import 'user_profile_screen.dart';
import '../../l10n/tx.dart';

/// Gönderi + yanıtlar. Yanıtlar, gönderinin çemberine özel tetikleyici
/// kelimeler dahil aynı denetimden geçer; kriz ifadesi paylaşılmaz, destek
/// paneli açılır.
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.note});
  final CommunityNote note;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _controller = TextEditingController();
  String? _problem;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final me = ref.read(myProfileProvider).value;
    if (me == null) return;
    final result = ContentModerator.check(_controller.text, circle: widget.note.circle, minLength: 2);
    final analytics = ref.read(analyticsProvider);
    if (!result.isOk) {
      analytics.noteBlocked(result.verdict.name);
      if (result.verdict == ModerationVerdict.crisis) {
        _controller.clear();
        showCrisisSheet(context);
        return;
      }
      setState(() => _problem = result.message);
      return;
    }
    setState(() {
      _sending = true;
      _problem = null;
    });
    final repo = ref.read(communityRepositoryProvider);
    try {
      await repo.postReply(widget.note, me, _controller.text);
      analytics.replyPosted();
      _controller.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } on FirebaseException catch (e) {
      setState(
        () => _problem = e.code == 'permission-denied'
            ? tx('Bu yanıt topluluk kurallarına takıldı. Daha yumuşak bir ifadeyle tekrar dener misin?')
            : tx('Yanıt şu an gönderilemedi.'),
      );
    } catch (_) {
      setState(() => _problem = tx('Yanıt şu an gönderilemedi.'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Yanıtı bildirir: benim için hemen gizlenir, geliştiriciye şikâyet gider.
  Future<void> _reportReply(NoteReply r) async {
    final uid = ref.read(uidProvider);
    final repo = ref.read(communityRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final reason = await pickReportReason(context, prompt: tx('Bu yanıtı neden bildiriyorsun? Senin için hemen gizlenir.'));
    if (reason == null || uid == null || !mounted) return;
    try {
      await repo.hideReply(uid, r.id);
      sendReportToDeveloper(ref, target: 'notes/${widget.note.id}/replies/${r.id}', reason: reason, quote: r.text);
      messenger.showSnackBar(
        SnackBar(content: Text(tx('Teşekkürler. Bu yanıt senin için gizlendi ve incelemeye gönderildi.'))),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(tx('Bildirim şu an gönderilemedi.'))));
    }
  }

  /// Kendi yanıtını siler (yanlışlıkla dokunmaya karşı onaylı).
  Future<void> _deleteReply(NoteReply r) async {
    final repo = ref.read(communityRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx('Yanıtını silmek istiyor musun?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tx('Vazgeç'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tx('Sil'))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await repo.deleteReply(widget.note.id, r.id);
    } on TimeoutException {
      // Çevrimdışı: silme kuyrukta, bağlantı gelince tamamlanır.
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(tx('Şu an yapılamadı. Biraz sonra tekrar dener misin?'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(appUserProvider).value;
    final uid = ref.watch(uidProvider);
    // Gönderinin canlı hali: destek/yanıt sayıları hangi ekrandan açılırsa
    // açılsın (akış, kişi profili) anında güncellenir.
    final noteAsync = ref.watch(noteProvider(widget.note.id));
    if (noteAsync.hasValue && noteAsync.value == null) {
      // Yazarı sildi ya da geliştirici şikâyet üzerine kaldırdı.
      return Scaffold(
        appBar: AppBar(title: Text(tx('Paylaşım'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speaker_notes_off_outlined, size: 48, color: scheme.outline),
                const SizedBox(height: 12),
                Text(
                  tx('Bu paylaşım artık yok. Yazarı silmiş ya da topluluk kuralları gereği kaldırılmış olabilir.'),
                  textAlign: TextAlign.center,
                  style: t.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }
    final live = noteAsync.value ?? widget.note;
    final blocked = ref.watch(blockedUidsProvider);
    final replies = (ref.watch(repliesProvider(widget.note.id)).value ?? const <NoteReply>[])
        .where((r) => !blocked.contains(r.authorUid) && !(user?.reportedReplies.contains(r.id) ?? false))
        .toList();
    final myProfile = ref.watch(myProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(tx('Paylaşım'))),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                PostCard(note: live, supported: user?.supportedNotes.contains(live.id) ?? false, tappable: false),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    replies.isEmpty ? tx('Henüz yanıt yok. İlk yanıtı sen yazabilirsin.') : tx('Yanıtlar'),
                    style: t.labelLarge?.copyWith(color: scheme.outline),
                  ),
                ),
                for (final r in replies)
                  ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 2, 4, 2),
                    leading: GestureDetector(
                      onTap: () => pushScreen(
                        context,
                        'user_profile',
                        UserProfileScreen(uid: r.authorUid, fallbackName: r.nickname),
                      ),
                      child: AvatarBadge(index: r.avatar, radius: 18),
                    ),
                    title: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: r.nickname,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: '  · ${timeAgo(r.createdAt)}',
                            style: t.bodySmall?.copyWith(color: scheme.outline),
                          ),
                        ],
                      ),
                    ),
                    subtitle: TranslatableText(text: r.text, lang: r.lang, style: t.bodyMedium),
                    trailing: r.authorUid == uid
                        ? IconButton(
                            tooltip: tx('Sil'),
                            icon: const Icon(Icons.delete_outline_rounded, size: 20),
                            onPressed: () => _deleteReply(r),
                          )
                        : PopupMenuButton<String>(
                            icon: Icon(Icons.more_horiz_rounded, size: 20, color: scheme.outline),
                            onSelected: (v) => v == 'block'
                                ? confirmBlock(context, ref, otherUid: r.authorUid, name: r.nickname)
                                : _reportReply(r),
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'report', child: Text(tx('Bildir'))),
                              PopupMenuItem(
                                value: 'block',
                                child: Text(tx('{name} adlı kişiyi engelle', {'name': r.nickname})),
                              ),
                            ],
                          ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_problem != null)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: HavenColors.clay.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: HavenColors.clay, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_problem!, style: t.bodySmall)),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
              child: Row(
                children: [
                  if (myProfile != null) AvatarBadge(index: myProfile.avatar, radius: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLength: ContentModerator.maxNoteLength,
                      minLines: 1,
                      maxLines: 4,
                      onChanged: (_) {
                        if (_problem != null) setState(() => _problem = null);
                      },
                      decoration: InputDecoration(
                        hintText: tx('Destekleyici bir yanıt yaz…'),
                        counterText: '',
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: tx('Gönder'),
                    onPressed: (_sending || myProfile == null) ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
