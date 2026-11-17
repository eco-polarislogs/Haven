import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers.dart';
import '../community/community_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../safe_space/safe_space_screen.dart';

/// 4 sekmeli ana kabuk. Her sekmenin üst çubuğunda bildirim zili var.
/// "Sakinleş" sekmesi kriz anı güvenli alanıdır: acil arama, nefes,
/// 5-4-3-2-1 ve oyunlar tek yerde.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _screens = ['home', 'community', 'safe_space', 'profile'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellIndexProvider);
    final l = context.l10n;
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [HomeScreen(), CommunityScreen(), SafeSpaceScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          ref.read(shellIndexProvider.notifier).select(i);
          ref.read(analyticsProvider).screen(_screens[i]);
        },
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.wb_sunny_outlined), selectedIcon: const Icon(Icons.wb_sunny), label: l.navToday),
          NavigationDestination(
              icon: const Icon(Icons.groups_outlined), selectedIcon: const Icon(Icons.groups), label: l.navCommunity),
          NavigationDestination(
              icon: const Icon(Icons.self_improvement_outlined), selectedIcon: const Icon(Icons.self_improvement_rounded), label: l.navCalm),
          NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: l.navProfile),
        ],
      ),
    );
  }
}
