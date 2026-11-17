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

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(appUserProvider).value;
    final uid = ref.watch(uidProvider);
    // Gönderinin güncel hali (destek/yanıt sayıları) akıştan gelir.
    final live =
        [
          ...?ref.watch(feedProvider).value,
          ...?ref.watch(friendsFeedProvider).value,
        ].where((n) => n.id == widget.note.id).firstOrNull ??
        widget.note;
    final replies = ref.watch(repliesProvider(widget.note.id)).value ?? const <NoteReply>[];
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
                            onPressed: () => ref.read(communityRepositoryProvider).deleteReply(widget.note.id, r.id),
                          )
                        : null,
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
