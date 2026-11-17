import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/day_key.dart';
import '../../core/widgets/avatar_badge.dart';
import '../../data/models/community.dart';
import '../../providers.dart';
import '../../l10n/tx.dart';

/// Duolingo tarzı seri arkadaşları. Sıralama/lider tablosu YOK: kıyas,
/// yetersizlik hissi doğurabilir. Sadece birbirini görmek ve cesaret vermek.
class FriendsTab extends ConsumerWidget {
  const FriendsTab({super.key});

  Future<void> _addFriend(BuildContext context, WidgetRef ref) async {
    final me = ref.read(myProfileProvider).value;
    final repo = ref.read(communityRepositoryProvider);
    final analytics = ref.read(analyticsProvider);
    final friendIds = ref.read(friendIdsProvider).value ?? const <String>[];
    final messenger = ScaffoldMessenger.of(context);
    if (me == null) return;
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: Text(tx('Arkadaş ekle')),
          content: TextField(
            controller: c,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            decoration: InputDecoration(labelText: tx('Arkadaş kodu'), hintText: tx('ör. K7M2QX')),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tx('Vazgeç'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Ekle')),
          ],
        );
      },
    );
    if (code == null || code.trim().length != 6) return;
    try {
      final other = await repo.findByFriendCode(code);
      if (other == null) {
        messenger.showSnackBar(SnackBar(content: Text(tx('Bu koda sahip biri bulunamadı.'))));
      } else if (other.uid == me.uid) {
        messenger.showSnackBar(SnackBar(content: Text(tx('Bu senin kendi kodun. 🙂'))));
      } else if (friendIds.contains(other.uid)) {
        messenger.showSnackBar(
          SnackBar(content: Text(tx('{nickname} zaten arkadaşın.', {'nickname': other.nickname}))),
        );
      } else {
        await repo.addFriend(me, other);
        analytics.friendAdded();
        messenger.showSnackBar(
          SnackBar(content: Text(tx('{nickname} artık arkadaşın.', {'nickname': other.nickname}))),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(tx('Arkadaş eklenemedi. İnternet bağlantını kontrol eder misin?'))),
      );
    }
  }

  Future<void> _kudos(BuildContext context, WidgetRef ref, PublicProfile friend) async {
    final me = ref.read(myProfileProvider).value;
    final repo = ref.read(communityRepositoryProvider);
    final analytics = ref.read(analyticsProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (me == null) return;
    final id = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                tx('{nickname} için bir cesaret notu seç', {'nickname': friend.nickname}),
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            for (var i = 0; i < kKudosMessages.length; i++)
              ListTile(
                leading: const Icon(Icons.favorite_border_rounded),
                title: Text(tx(kKudosMessages[i])),
                onTap: () => Navigator.pop(ctx, i),
              ),
          ],
        ),
      ),
    );
    if (id == null) return;
    try {
      await repo.sendKudos(me, friend.uid, id);
      analytics.kudosSent();
      messenger.showSnackBar(
        SnackBar(content: Text(tx('Notun {nickname} için gönderildi.', {'nickname': friend.nickname}))),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(tx('Not şu an gönderilemedi.'))));
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, PublicProfile friend) async {
    final uid = ref.read(uidProvider);
    final repo = ref.read(communityRepositoryProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx('{nickname} arkadaşlarından çıkarılsın mı?', {'nickname': friend.nickname})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tx('Vazgeç'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tx('Çıkar'))),
        ],
      ),
    );
    if (ok == true && uid != null) await repo.removeFriend(uid, friend.uid);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(myProfileProvider).value;
    final friends = ref.watch(friendProfilesProvider).value ?? const <PublicProfile>[];
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final today = todayKey();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
      children: [
        Card(
          color: scheme.primaryContainer.withValues(alpha: 0.6),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx('Arkadaş kodun'), style: t.labelLarge),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      me?.friendCode ?? '······',
                      style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 4),
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      tooltip: 'Kopyala',
                      onPressed: me == null
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: me.friendCode));
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text(tx('Arkadaş kodun kopyalandı.'))));
                            },
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tx(
                    'Bu kodu güvendiğin kişilerle paylaş. Arkadaşlar birbirinin serisini görür ve hazır cesaret notları gönderebilir.',
                  ),
                  style: t.bodySmall,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: me == null ? null : () => _addFriend(context, ref),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(tx('Arkadaş ekle')),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (friends.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(Icons.people_outline_rounded, size: 48, color: scheme.primary),
                const SizedBox(height: 8),
                Text(tx('Henüz arkadaşın yok'), style: t.titleMedium),
                const SizedBox(height: 4),
                Text(tx('Yolculuğu birlikte yürümek daha kolay.'), style: t.bodyMedium),
              ],
            ),
          )
        else
          for (final f in friends)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                  leading: AvatarBadge(index: f.avatar),
                  title: Text(f.nickname, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        StreakBadge(days: f.daily.live(today)),
                        const SizedBox(width: 8),
                        Text('En uzun: ${f.daily.longest}', style: t.labelSmall),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: tx('Cesaret gönder'),
                        icon: Icon(Icons.favorite_border_rounded, color: scheme.primary),
                        onPressed: () => _kudos(context, ref, f),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (_) => _remove(context, ref, f),
                        itemBuilder: (_) => [PopupMenuItem(value: 'remove', child: Text(tx('Arkadaşlardan çıkar')))],
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
