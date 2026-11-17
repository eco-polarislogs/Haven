import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/moderation/content_moderator.dart';
import '../../core/navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/avatar_badge.dart';
import '../../data/models/community.dart';
import '../../providers.dart';
import 'post_detail_screen.dart';
import 'user_profile_screen.dart';

/// X (Twitter) tarzı gönderi kartı: avatar | ad · seri · zaman / çember /
/// metin / yanıt · destek · menü. Avatara dokununca profil, karta dokununca
/// yanıtlar açılır. Her yanıt da gönderilerle aynı sıkı denetimden geçer.
class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.note, required this.supported, this.tappable = true});

  final CommunityNote note;
  final bool supported;
  final bool tappable;

  Future<void> _support(BuildContext context, WidgetRef ref) async {
    final me = ref.read(myProfileProvider).value;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(communityRepositoryProvider);
    final analytics = ref.read(analyticsProvider);
    if (me == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Profilin hazırlanıyor, birazdan tekrar dene.')));
      return;
    }
    try {
      await repo.supportNote(note, me);
      analytics.noteSupported();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Destek şu an gönderilemedi.')));
    }
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(uidProvider);
    final repo = ref.read(communityRepositoryProvider);
    final analytics = ref.read(analyticsProvider);
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text('Bu paylaşımı neden bildiriyorsun? Senin için hemen gizlenir.'),
            ),
            for (final r in const [
              'Kırıcı veya küçümseyici',
              'Tetikleyici içerik',
              'Spam veya reklam',
              'Başka bir şey',
            ])
              ListTile(leading: const Icon(Icons.flag_outlined), title: Text(r), onTap: () => Navigator.pop(ctx, r)),
          ],
        ),
      ),
    );
    if (reason == null || uid == null) return;
    try {
      await repo.reportNote(note, uid, reason);
      analytics.noteReported();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Teşekkürler. Bu paylaşım senin için gizlendi; topluluğu güvende tuttuğun için sağ ol.'),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Bildirim şu an gönderilemedi.')));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(communityRepositoryProvider);
    final uid = ref.read(uidProvider);
    final nav = Navigator.of(context);
    if (uid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paylaşımını silmek istiyor musun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok == true) {
      await repo.deleteNote(note.id, uid);
      if (!tappable && nav.canPop()) nav.pop(); // detay ekranındaysak geri dön
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final uid = ref.watch(uidProvider);
    // Anonim gönderinin sahibini yalnızca yazarın kendi özel kaydı bilir.
    final mine = note.anonymous
        ? (ref.watch(myAnonNoteIdsProvider).value ?? const {}).contains(note.id)
        : note.authorUid == uid;
    final circle = note.circle;
    // Okuyanın alanları için tetikleyici olabilecek ifadeler gizlenir.
    final masked = ContentModerator.maskFor(note.text, ref.watch(readerCategoriesProvider));

    void openProfile() {
      if (note.anonymous) return; // anonim gönderide profil yok
      pushScreen(context, 'user_profile', UserProfileScreen(uid: note.authorUid, fallbackName: note.nickname));
    }

    return InkWell(
      onTap: tappable ? () => pushScreen(context, 'post_detail', PostDetailScreen(note: note)) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: openProfile,
              child: note.anonymous
                  ? CircleAvatar(
                      radius: 22,
                      backgroundColor: scheme.surfaceContainerHighest,
                      child: Icon(Icons.visibility_off_outlined, color: scheme.outline),
                    )
                  : AvatarBadge(index: note.avatar, radius: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: GestureDetector(
                                onTap: openProfile,
                                child: Text(
                                  note.nickname,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (!note.anonymous) ...[StreakBadge(days: note.streak), const SizedBox(width: 6)],
                            if (note.anonymous && mine) ...[
                              Text('(sen)', style: t.bodySmall?.copyWith(color: scheme.outline)),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                '· ${timeAgo(note.createdAt)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.bodySmall?.copyWith(color: scheme.outline),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 28,
                        width: 32,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.more_horiz_rounded, size: 20, color: scheme.outline),
                          onSelected: (v) => v == 'delete' ? _delete(context, ref) : _report(context, ref),
                          itemBuilder: (_) => [
                            if (mine)
                              const PopupMenuItem(value: 'delete', child: Text('Paylaşımımı sil'))
                            else
                              const PopupMenuItem(value: 'report', child: Text('Bildir')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (circle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(circle.icon, size: 13, color: categoryAccent(circle)),
                          const SizedBox(width: 4),
                          Text(circle.shortTitle, style: t.labelSmall?.copyWith(color: categoryAccent(circle))),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 6, 8, 6),
                    child: Text(masked.text, style: t.bodyLarge?.copyWith(height: 1.4)),
                  ),
                  if (masked.hidden > 0) const HiddenWordsNote(),
                  Row(
                    children: [
                      _Action(
                        icon: Icons.chat_bubble_outline_rounded,
                        count: note.replyCount,
                        onTap: tappable ? () => pushScreen(context, 'post_detail', PostDetailScreen(note: note)) : null,
                      ),
                      const SizedBox(width: 18),
                      _Action(
                        icon: supported ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        count: note.supportCount,
                        color: supported ? scheme.primary : null,
                        onTap: (supported || mine) ? null : () => _support(context, ref),
                        label: supported ? 'Destek verdin' : 'Destek',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.count, this.onTap, this.color, this.label});
  final IconData icon;
  final int count;
  final VoidCallback? onTap;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.outline;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 5),
            Text(
              label == null ? '$count' : '$label · $count',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Senin için gizlendi" notu: okuyanı koruyan gizlemenin açıklaması.
class HiddenWordsNote extends StatelessWidget {
  const HiddenWordsNote({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 14, color: scheme.outline),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Senin için hassas olabilecek ifadeler gizlendi.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}
