import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation.dart';
import '../../l10n/l10n.dart';
import '../../providers.dart';
import 'notifications_screen.dart';

/// Her sekmenin üst çubuğundaki bildirim zili; okunmamış sayısını gösterir.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return IconButton(
      tooltip: context.l10n.notificationsTitle,
      onPressed: () => pushScreen(context, 'notifications', const NotificationsScreen()),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 9 ? '9+' : '$unread'),
        child: Icon(unread > 0 ? Icons.notifications_rounded : Icons.notifications_none_rounded),
      ),
    );
  }
}
