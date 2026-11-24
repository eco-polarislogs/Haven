import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/struggle_catalog.dart';
import '../../core/navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/day_key.dart';
import '../../core/utils/streak.dart';
import '../../core/widgets/avatar_badge.dart';
import '../../data/models/community.dart';
import '../../providers.dart';
import '../notifications/notification_bell.dart';
import 'compose_note_sheet.dart';
import 'friends_tab.dart';
import 'post_card.dart';
import 'user_profile_screen.dart';
import '../../l10n/tx.dart';

/// Topluluk, X (Twitter) düzeninde: üstte avatarın ve sekmeler
/// (Senin için · Arkadaşlar · Kişiler), akışın başında "paylaş" satırı,
/// sağ altta yuvarlak "+" düğmesi. Gönderiye dokununca yanıtlar, avatara
/// dokununca kişinin profili açılır.
///
/// X'ten farklı olarak: beğeni yerine "destek", herkese açık takipçi/beğeni
/// sayısı ve sıralama yok; her gönderi ve yanıt paylaşılmadan önce denetlenir.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;
    final joined = user?.communityJoined ?? false;

    if (!joined) {
      return Scaffold(
        appBar: AppBar(title: Text(tx('Topluluk')), actions: const [NotificationBell()]),
        body: const _JoinView(),
      );
    }

    final me = ref.watch(myProfileProvider).value;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: me == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Center(
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => pushScreen(
                        context,
                        'user_profile',
                        UserProfileScreen(uid: me.uid, fallbackName: me.nickname),
                      ),
                      child: AvatarBadge(index: me.avatar, radius: 17),
                    ),
                  ),
                ),
          title: Text(tx('Topluluk')),
          actions: const [NotificationBell(), SizedBox(width: 4)],
          bottom: TabBar(
            tabs: [
              Tab(text: tx('Senin için')),
              Tab(text: tx('Arkadaşlar')),
              Tab(text: tx('Kişiler')),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            heroTag: 'fab_community',
            tooltip: tx('Paylaş'),
            shape: const CircleBorder(),
            onPressed: () => showComposeNoteSheet(context),
            child: const Icon(Icons.add_rounded, size: 30),
          ),
        ),
        body: const TabBarView(children: [_ForYouTab(), _FriendsFeedTab(), FriendsTab()]),
      ),
    );
  }
}

// ----------------------------------------------------------------- katılım

class _JoinView extends ConsumerWidget {
  const _JoinView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: scheme.primaryContainer,
            child: Icon(Icons.forum_outlined, size: 42, color: scheme.primary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          tx('Aynı yolda yürüyenlerle buluş'),
          textAlign: TextAlign.center,
          style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          tx(
            'Kısa paylaşımlar yap, başkalarının paylaşımlarına destek ver ve yanıt yaz, arkadaşlarının serisini gör. Toplulukta yalnızca takma adın, avatarın ve serin görünür.',
          ),
          textAlign: TextAlign.center,
          style: t.bodyLarge,
        ),
        const SizedBox(height: 16),
        _RuleLine(icon: Icons.shield_outlined, text: tx('Her paylaşım ve yanıt yayınlanmadan önce denetlenir.')),
        _RuleLine(icon: Icons.visibility_off_outlined, text: tx('Takipçi ve beğeni yarışı yok; kimse puanlanmaz.')),
        _RuleLine(
          icon: Icons.flag_outlined,
          text: tx('Rahatsız eden bir şeyi bildirdiğinde senin için hemen gizlenir.'),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () {
            final uid = ref.read(uidProvider);
            final user = ref.read(appUserProvider).value;
            if (uid == null || user == null) return;
            ref.read(repositoryProvider).setCommunityJoined(uid, true);
            ref.read(analyticsProvider).communityJoined(true);
            unawaited(
              ref
                  .read(communityRepositoryProvider)
                  .ensureProfile(
                    uid,
                    nickname: user.nickname ?? tx('Haven üyesi'),
                    avatar: user.avatar,
                    daily: user.daily,
                  )
                  .catchError((Object e) => debugPrint('Profil: $e')),
            );
          },
          icon: const Icon(Icons.login_rounded),
          label: Text(tx('Topluluğa katıl')),
        ),
      ],
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    ),
  );
}

// ----------------------------------------------------------------- akışlar

/// "Senin için": seçtiğin alanların çemberlerindeki son paylaşımlar,
/// üstte konu (çember) filtreleri.
class _ForYouTab extends ConsumerStatefulWidget {
  const _ForYouTab();

  @override
  ConsumerState<_ForYouTab> createState() => _ForYouTabState();
}

class _ForYouTabState extends ConsumerState<_ForYouTab> with AutomaticKeepAliveClientMixin {
  StruggleCategory? _filter;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = ref.watch(appUserProvider).value;
    final circles = (user?.categoryIds ?? const <String>[]).map(categoryByName).whereType<StruggleCategory>().toList();
    final filter = circles.contains(_filter) ? _filter : null;

    return _Feed(
      async: ref.watch(feedProvider),
      where: (n) => filter == null || n.circle == filter,
      header: circles.length < 2
          ? null
          : SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  _TopicChip(label: tx('Tümü'), selected: filter == null, onTap: () => setState(() => _filter = null)),
                  for (final c in circles)
                    _TopicChip(
                      label: c.shortTitle,
                      icon: c.icon,
                      selected: filter == c,
                      onTap: () => setState(() => _filter = c),
                    ),
                ],
              ),
            ),
      empty: _Message(
        icon: Icons.light_mode_outlined,
        title: tx('İlk ışığı sen yak'),
        body: tx('Çemberlerinde henüz paylaşım yok. Seni güçlendiren küçük bir şeyi paylaşarak başlayabilirsin.'),
      ),
    );
  }
}

/// "Arkadaşlar": arkadaşlarının ve senin paylaşımların.
class _FriendsFeedTab extends ConsumerStatefulWidget {
  const _FriendsFeedTab();

  @override
  ConsumerState<_FriendsFeedTab> createState() => _FriendsFeedTabState();
}

class _FriendsFeedTabState extends ConsumerState<_FriendsFeedTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final hasFriends = (ref.watch(friendIdsProvider).value ?? const []).isNotEmpty;
    return _Feed(
      async: ref.watch(friendsFeedProvider),
      where: (_) => true,
      empty: _Message(
        icon: Icons.people_outline_rounded,
        title: hasFriends ? tx('Arkadaşların henüz paylaşmadı') : tx('Arkadaşlarının paylaşımları burada'),
        body: hasFriends
            ? tx('Bir şey paylaştıklarında ilk burada görürsün.')
            : tx('Bir paylaşımda avatara dokunup ya da arkadaş koduyla birini ekleyebilirsin.'),
        action: hasFriends
            ? null
            : TextButton.icon(
                onPressed: () => DefaultTabController.of(context).animateTo(2),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: Text(tx('Kişiler')),
              ),
      ),
    );
  }
}

class _Feed extends ConsumerWidget {
  const _Feed({required this.async, required this.where, required this.empty, this.header});

  final AsyncValue<List<CommunityNote>> async;
  final bool Function(CommunityNote) where;
  final Widget empty;
  final Widget? header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _Message(
        icon: Icons.hourglass_top_rounded,
        title: tx('Akış hazırlanıyor'),
        body: tx('Topluluk akışı ilk kez kuruluyor olabilir. Birkaç dakika içinde tekrar bak.'),
      ),
      data: (notes) {
        final visible = notes
            .where(
              (n) =>
                  !n.hidden &&
                  !(user?.reportedNotes.contains(n.id) ?? false) &&
                  !(user?.blockedUids.contains(n.authorUid) ?? false) &&
                  where(n),
            )
            .toList();
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 112),
          itemCount: visible.isEmpty ? 3 : visible.length + 2,
          itemBuilder: (context, i) {
            if (i == 0) return header ?? const SizedBox.shrink();
            if (i == 1) return const _ComposerRow();
            if (visible.isEmpty) return empty;
            final n = visible[i - 2];
            final post = PostCard(note: n, supported: user?.supportedNotes.contains(n.id) ?? false);
            // Bazı tasarımlarda her gönderi ayrı bir kart; Klasik'te çizgiyle ayrılmış liste.
            if (HavenStyle.of(context).t.feedCards) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: HavenCard(clipBehavior: Clip.antiAlias, child: post),
              );
            }
            return Column(children: [post, const Divider(height: 1)]);
          },
        );
      },
    );
  }
}

/// Akışın başındaki "Bugün neyi paylaşmak istersin?" satırı.
class _ComposerRow extends ConsumerWidget {
  const _ComposerRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(myProfileProvider).value;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        InkWell(
          onTap: () => showComposeNoteSheet(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                AvatarBadge(index: me?.avatar ?? 0, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tx('Bugün neyi paylaşmak istersin?'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.outline),
                  ),
                ),
                Icon(Icons.edit_outlined, color: scheme.primary),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      avatar: icon == null ? null : Icon(icon, size: 16),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body, this.action});
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(title, style: t.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(body, style: t.bodyMedium, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    );
  }
}

/// Paylaşım anında gösterilecek seri.
int currentDailyStreak(WidgetRef ref) =>
    ref.read(appUserProvider).value?.daily.live(todayKey()) ?? const DailyStreak().current;
