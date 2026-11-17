import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/day_key.dart';
import '../../core/widgets/avatar_badge.dart';
import '../../providers.dart';
import 'post_card.dart';

/// Bir topluluk üyesinin profili (X tarzı): avatar, takma ad, seri, rekor,
/// paylaşımları; "Arkadaş ekle" / "Cesaret gönder". Gerçek ad, e-posta ve
/// hangi alanlarla mücadele ettiği burada görünmez.
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.uid, required this.fallbackName});

  final String uid;
  final String fallbackName;

  Future<void> _addFriend(BuildContext context, WidgetRef ref) async {
    final me = ref.read(myProfileProvider).value;
    final other = ref.read(profileProvider(uid)).value;
    final messenger = ScaffoldMessenger.of(context);
    if (me == null || other == null) return;
    try {
      await ref.read(communityRepositoryProvider).addFriend(me, other);
      ref.read(analyticsProvider).friendAdded();
      messenger.showSnackBar(SnackBar(content: Text('${other.nickname} artık arkadaşın.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Arkadaş eklenemedi.')));
    }
  }

  Future<void> _kudos(BuildContext context, WidgetRef ref) async {
    final me = ref.read(myProfileProvider).value;
    final repo = ref.read(communityRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (me == null) return;
    final id = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          for (var i = 0; i < kKudosMessages.length; i++)
            ListTile(
              leading: const Icon(Icons.favorite_border_rounded),
              title: Text(kKudosMessages[i]),
              onTap: () => Navigator.pop(ctx, i),
            ),
        ]),
      ),
    );
    if (id == null) return;
    try {
      await repo.sendKudos(me, uid, id);
      ref.read(analyticsProvider).kudosSent();
      messenger.showSnackBar(const SnackBar(content: Text('Cesaret notun gönderildi.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Not şu an gönderilemedi.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final p = HavenPalette.of(context);
    final profile = ref.watch(profileProvider(uid)).value;
    final notes = ref.watch(userNotesProvider(uid)).value ?? const [];
    final myUid = ref.watch(uidProvider);
    final isMe = myUid == uid;
    final isFriend = (ref.watch(friendIdsProvider).value ?? const []).contains(uid);
    final user = ref.watch(appUserProvider).value;
    final today = todayKey();
    final visible = notes.where((n) => !n.hidden && !(user?.reportedNotes.contains(n.id) ?? false)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(profile?.nickname ?? fallbackName)),
      body: ListView(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(colors: [p.deep, Color.lerp(p.deep, p.primary, 0.75)!]),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              child: AvatarBadge(index: profile?.avatar ?? 0, radius: 34),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(profile?.nickname ?? fallbackName,
                    style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.local_fire_department_rounded, color: p.accent, size: 20),
                  const SizedBox(width: 4),
                  Text('${profile?.daily.live(today) ?? 0} günlük seri',
                      style: t.bodyMedium?.copyWith(color: Colors.white)),
                  const SizedBox(width: 12),
                  Icon(Icons.emoji_events_outlined, color: p.accent, size: 18),
                  const SizedBox(width: 4),
                  Text('Rekor ${profile?.daily.longest ?? 0}', style: t.bodyMedium?.copyWith(color: Colors.white)),
                ]),
              ]),
            ),
          ]),
        ),
        if (!isMe)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                child: isFriend
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Arkadaşsınız'),
                      )
                    : FilledButton.icon(
                        onPressed: profile == null ? null : () => _addFriend(context, ref),
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: const Text('Arkadaş ekle'),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _kudos(context, ref),
                  icon: const Icon(Icons.favorite_border_rounded),
                  label: const Text('Cesaret gönder'),
                ),
              ),
            ]),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
          child: Text('Paylaşımlar', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        ),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Henüz paylaşım yok.', textAlign: TextAlign.center),
          )
        else
          for (final n in visible) ...[
            PostCard(note: n, supported: user?.supportedNotes.contains(n.id) ?? false),
            const Divider(height: 1),
          ],
        const SizedBox(height: 24),
      ]),
    );
  }
}
