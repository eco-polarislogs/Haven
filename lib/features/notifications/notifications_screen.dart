import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/time_ago.dart';
import '../../core/widgets/avatar_badge.dart';
import '../../data/models/community.dart';
import '../../l10n/l10n.dart';
import '../../providers.dart';

/// Bildirim merkezi: arkadaş ekleme, cesaret notları, destekler, seriler,
/// giriş/çıkış olayları — hepsi tek yerde.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).notificationCenterOpened(ref.read(unreadCountProvider));
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(inboxProvider);
    final uid = ref.watch(uidProvider);
    final repo = ref.read(communityRepositoryProvider);
    final unreadIds = (items.value ?? const <InboxItem>[]).where((i) => !i.read).map((i) => i.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notificationsTitle),
        actions: [
          if (unreadIds.isNotEmpty && uid != null)
            TextButton(
              onPressed: () => repo.markAllRead(uid, unreadIds.toList()),
              child: Text(context.l10n.markAllRead),
            ),
        ],
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Bildirimlere şu an ulaşamadık.')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 56, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  const Text('Henüz bildirim yok.', textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('Arkadaşların seni eklediğinde ya da notuna destek verdiğinde burada görünecek.',
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) => _InboxTile(
              item: list[i],
              onTap: () {
                if (!list[i].read && uid != null) repo.markRead(uid, list[i].id);
              },
            ),
          );
        },
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({required this.item, required this.onTap});

  final InboxItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListTile(
      onTap: onTap,
      tileColor: item.read ? null : scheme.primaryContainer.withValues(alpha: 0.35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: item.fromAvatar != null
          ? AvatarBadge(index: item.fromAvatar!)
          : CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primaryContainer,
              child: Icon(item.icon, color: scheme.primary),
            ),
      title: Text(item.title,
          style: text.bodyLarge?.copyWith(fontWeight: item.read ? FontWeight.w400 : FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.body.isNotEmpty) Text(item.body),
          const SizedBox(height: 2),
          Text(timeAgo(item.createdAt), style: text.labelSmall),
        ],
      ),
      trailing: item.read
          ? null
          : Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle)),
    );
  }
}
