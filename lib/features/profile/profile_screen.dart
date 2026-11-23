import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/moderation/content_moderator.dart';
import '../../core/navigation.dart';
import '../../core/utils/day_key.dart';
import '../../core/widgets/avatar_badge.dart';
import '../../core/widgets/gentle_states.dart';
import '../../data/models/app_user.dart';
import '../../data/models/community.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/local_notifier.dart';
import '../../providers.dart';
import '../notifications/notification_bell.dart';
import '../onboarding/struggle_picker_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../ads/rewarded_unlock.dart';
import '../rewards/gifts_screen.dart';
import 'badges.dart';
import '../community/moderation_actions.dart';
import '../support/developer_panel_screen.dart';
import '../support/feedback_screen.dart';
import '../support/professional_support_screen.dart';
import '../../l10n/tx.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    // Servisleri await'lerden ÖNCE al (Riverpod 3: ekran kalkınca ref kullanılamaz).
    final navigator = Navigator.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final uid = ref.read(uidProvider);
    final repo = ref.read(repositoryProvider);
    final notifications = ref.read(notificationServiceProvider);
    final auth = ref.read(authServiceProvider);
    // Çıkış birkaç saniye sürer (bu cihazın bildirim kaydı sunucudan silinir).
    // Bu arada ekran kilitlenir: tekrar basılmaz, kullanıcı ne olduğunu görür.
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3)),
                const SizedBox(width: 20),
                Expanded(child: Text(tx('Çıkış yapılıyor…'))),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      await Future.wait([
        if (uid != null) repo.addInboxAndWait(uid, InboxType.logout),
        notifications.stop(),
      ]).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Çıkış öncesi temizlik tamamlanamadı: $e');
    }
    await auth.signOut();
    debugPrint(
      '[çıkış] firebase: ${auth.currentUser == null ? 'kapalı' : 'AÇIK'}, '
      'uygulama: ${container.read(authStateProvider).value == null ? 'kapalı' : 'AÇIK'}',
    );
    // Ekran her durumda karşılama ekranına döner (bkz. syncAuthState).
    syncAuthState(container);
    container.read(shellIndexProvider.notifier).select(0);
    navigator.popUntil((route) => route.isFirst);
  }

  /// Google Play ve App Store için ZORUNLU: uygulama içi hesap silme.
  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(uidProvider);
    final notifications = ref.read(notificationServiceProvider);
    final repo = ref.read(repositoryProvider);
    final auth = ref.read(authServiceProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx('Her şeyi silmek istediğine emin misin?')),
        content: Text(
          tx(
            'Seçtiğin alanlar, tüm kayıtların, topluluk notların, arkadaşlıkların ve hesabın kalıcı olarak silinecek. Bu işlem geri alınamaz.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tx('Vazgeç'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tx('Evet, sil'))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted || uid == null) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      // Vazgeçerse hiçbir şey silinmez.
      if (!await auth.confirmIdentity()) return;
      await notifications.stop();
      await repo.deleteAllUserData(uid);
      await auth.deleteAccount();
      syncAuthState(container);
      navigator.popUntil((route) => route.isFirst);
    } on AuthFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(tx('Silme işlemi için internet bağlantısı gerekiyor. Bağlantın gelince tekrar dener misin?')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;
    final uid = ref.watch(uidProvider);
    final profile = ref.watch(myProfileProvider).value;
    if (user == null || uid == null) return const GentleLoading();

    final repo = ref.read(repositoryProvider);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final struggles = ref.watch(strugglesProvider).value ?? const [];
    final totalKind = struggles.fold<int>(0, (sum, s) => sum + s.streak.totalKindDays);
    final best = ref.watch(bestStreakProvider);
    final currentTheme = ref.watch(themePresetProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tx('Profil')), actions: const [NotificationBell(), SizedBox(width: 4)]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      AvatarBadge(index: user.avatar, radius: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.nickname ?? '', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            InkWell(
                              onTap: profile == null
                                  ? null
                                  : () {
                                      Clipboard.setData(ClipboardData(text: profile.friendCode));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(content: Text(tx('Arkadaş kodun kopyalandı.'))));
                                    },
                              child: Row(
                                children: [
                                  Text(tx('Arkadaş kodu: {p}', {'p': profile?.friendCode ?? '…'}), style: t.bodySmall),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.copy_rounded, size: 14),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: tx('Profili düzenle'),
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _editProfile(context, ref, user),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _Stat('${user.daily.live(todayKey())}', tx('günlük seri'), Icons.local_fire_department_rounded),
                      _Stat('${user.daily.longest}', tx('en uzun seri'), Icons.emoji_events_outlined),
                      _Stat('$totalKind', tx('iyi geçen gün'), Icons.light_mode_outlined),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            color: scheme.tertiary.withValues(alpha: 0.13),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              leading: Icon(Icons.volunteer_activism_outlined, color: scheme.tertiary),
              title: Text(tx('Destek al'), style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(tx('Kriz hatları ve profesyonel desteğe nasıl ulaşılır')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => pushScreen(context, 'professional_support', const ProfessionalSupportScreen()),
            ),
          ),
          const SizedBox(height: 12),
          const BadgesSection(),
          SectionTitle(tx('Yolculuğum')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: Text(tx('Mücadele alanlarım')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => pushScreen(context, 'edit_struggles', const StrugglePickerScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.card_giftcard_outlined),
                  title: Text(context.l10n.giftsTitle),
                  subtitle: Text(tx('Seriyle açılan temalar ve avatarlar')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => pushScreen(context, 'gifts', const GiftsScreen()),
                ),
              ],
            ),
          ),
          SectionTitle(tx('Topluluk ve bildirimler')),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: user.communityJoined,
                  onChanged: (v) {
                    repo.setCommunityJoined(uid, v);
                    ref.read(analyticsProvider).communityJoined(v);
                    if (v) {
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
                    }
                  },
                  secondary: const Icon(Icons.groups_outlined),
                  title: Text(tx('Topluluğa katıl')),
                  subtitle: Text(tx('Takma adın, avatarın ve serin görünür.')),
                ),
                ListTile(
                  leading: const Icon(Icons.block_rounded),
                  title: Text(tx('Engellediğin kişiler')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user.blockedUids.isNotEmpty) Text('${user.blockedUids.length}'),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                  onTap: () => pushScreen(context, 'blocked_users', const BlockedUsersScreen()),
                ),
                SwitchListTile(
                  value: user.notificationsEnabled,
                  onChanged: (v) => repo.setNotificationsEnabled(uid, v),
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: Text(tx('Hatırlatmalar')),
                  subtitle: Text(
                    tx(
                      'Her gün 13.00\'te kısa bir motivasyon mesajı; bir süre görünmediğinde de hal hatır sorarız. Yalnızca 10:00–21:00 arası.',
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.notification_add_outlined),
                  title: Text(tx('Deneme bildirimi gönder')),
                  subtitle: Text(tx('Uygulamayı kapat; birkaç saniye içinde telefonuna bir bildirim gelir.')),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await LocalNotifier.sendTest();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? tx('Deneme bildirimi 10 saniye içinde gelecek. Şimdi uygulamayı kapatabilirsin.')
                              : tx('Bildirim izni kapalı. Telefonun Ayarlar → Uygulamalar → Haven → Bildirimler bölümünden açabilirsin.'),
                        ),
                      ),
                    );
                  },
                ),
                SwitchListTile(
                  value: user.analyticsEnabled,
                  onChanged: (v) {
                    repo.setAnalyticsEnabled(uid, v);
                    ref.read(analyticsProvider).setEnabled(v);
                  },
                  secondary: const Icon(Icons.insights_outlined),
                  title: Text(tx('Anonim kullanım istatistikleri')),
                  subtitle: Text(tx('Not içeriklerin ve kimliğin asla paylaşılmaz.')),
                ),
                SwitchListTile(
                  value: user.adsAllowed,
                  onChanged: (v) => repo.setAdsOptIn(uid, v),
                  secondary: const Icon(Icons.verified_user_outlined),
                  title: Text(tx('Filtreli reklamlar')),
                  subtitle: Text(
                    tx(
                      'Alt çubukta küçük bir reklam; temaları ve hediyeleri reklamla açabilme. Hassas alanlarda varsayılan kapalı; Sakinleş ekranında asla reklam yok.',
                    ),
                  ),
                ),
              ],
            ),
          ),
          SectionTitle(context.l10n.themes),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final p in ThemePreset.values)
                Builder(
                  builder: (context) {
                    final open = isGiftUnlocked(unlockStreak: p.unlockStreak, id: p.name, best: best, user: user);
                    return ChoiceChip(
                      // Kilitli temada reklam izni varsa "reklamla aç" simgesi.
                      avatar: open
                          ? CircleAvatar(backgroundColor: p.primary, radius: 8)
                          : Icon(user.adsAllowed ? Icons.ondemand_video_rounded : Icons.lock_outline_rounded, size: 16),
                      label: Text(p.label),
                      selected: currentTheme == p,
                      onSelected: open ? (_) => repo.setTheme(uid, p.name) : (_) => offerThemeUnlock(context, ref, p),
                    );
                  },
                ),
            ],
          ),
          SectionTitle(context.l10n.language),
          DropdownButtonFormField<String?>(
            initialValue: ref.watch(localeProvider).languageCode,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.translate_rounded)),
            items: [for (final e in kLanguageNames.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (code) => repo.setLanguage(uid, code),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text(
              tx('Tüm içerik 5 dilde. Çeviriler özenle hazırlandı; yine de bir uzmanın tavsiyesinin yerini tutmaz.'),
              style: t.bodySmall,
            ),
          ),
          SectionTitle(tx('Destek ve öneriler')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: Text(tx('Geliştiriciye yaz')),
                  subtitle: Text(tx('Öneri, hata bildirimi ya da soru; yanıtı burada görürsün.')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => pushScreen(context, 'feedback', const FeedbackScreen()),
                ),
                if (ref.watch(isDeveloperProvider))
                  ListTile(
                    leading: Badge(
                      isLabelVisible: ref.watch(openTicketCountProvider) > 0,
                      label: Text('${ref.watch(openTicketCountProvider)}'),
                      child: const Icon(Icons.inbox_outlined),
                    ),
                    title: Text(tx('Geliştirici paneli')),
                    subtitle: Text(tx('Kullanıcılardan gelen talepler (yalnızca sana görünür)')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => pushScreen(context, 'developer_panel', const DeveloperPanelScreen()),
                  ),
              ],
            ),
          ),
          SectionTitle(tx('Hesap')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(tx('Gizlilik politikası')),
                  onTap: () => launchUrl(Uri.parse(kPrivacyPolicyUrl)),
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: Text(tx('Çıkış yap')),
                  onTap: () => _signOut(context, ref),
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: scheme.error),
                  title: Text(tx('Hesabımı ve tüm verilerimi sil'), style: TextStyle(color: scheme.error)),
                  onTap: () => _deleteAccount(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tx('Haven bir tedavi aracı değildir; profesyonel desteğin yerini tutmaz.'),
            textAlign: TextAlign.center,
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref, AppUser user) async {
    final uid = ref.read(uidProvider);
    final best = ref.read(bestStreakProvider);
    final repo = ref.read(repositoryProvider);
    final community = ref.read(communityRepositoryProvider);
    final controller = TextEditingController(text: user.nickname);
    var avatar = user.avatar;
    String? error;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(tx('Profilini düzenle'), style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLength: 24,
                    onChanged: (_) => setSheet(() => error = null),
                    decoration: InputDecoration(labelText: ctx.l10n.nicknameLabel, errorText: error),
                  ),
                  Row(
                    children: [
                      AvatarBadge(index: avatar, radius: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tx('Varsayılan adı: {p}', {'p': defaultNickname(avatar)}),
                          style: Theme.of(ctx).textTheme.bodyMedium,
                        ),
                      ),
                      if (controller.text.trim() != defaultNickname(avatar))
                        TextButton(
                          onPressed: () => setSheet(() {
                            controller.text = defaultNickname(avatar);
                            error = null;
                          }),
                          child: Text(tx('Bu adı kullan')),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < kAvatars.length; i++)
                        if (isGiftUnlocked(
                          unlockStreak: kAvatars[i].unlockStreak,
                          id: 'avatar_$i',
                          best: best,
                          user: user,
                        ))
                          GestureDetector(
                            onTap: () => setSheet(() {
                              // Ad hâlâ bir avatarın varsayılan adıysa (ya da boşsa) yeni
                              // avatarın adı gelir; kullanıcının kendi yazdığı ada dokunulmaz.
                              final current = controller.text.trim();
                              if (current.isEmpty || kAvatars.any((a) => a.nick == current)) {
                                controller.text = defaultNickname(i);
                              }
                              avatar = i;
                              error = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: i == avatar ? Theme.of(ctx).colorScheme.primary : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: AvatarBadge(index: i, radius: 22),
                            ),
                          ),
                      // Kilitli hediye avatarlar: dokununca seriyle açılma bilgisi
                      // ve isteğe bağlı "reklam izle ve aç".
                      for (var i = 0; i < kAvatars.length; i++)
                        if (!isGiftUnlocked(
                          unlockStreak: kAvatars[i].unlockStreak,
                          id: 'avatar_$i',
                          best: best,
                          user: user,
                        ))
                          GestureDetector(
                            onTap: () => offerAvatarUnlock(
                              ctx,
                              ref,
                              i,
                              onUnlocked: () {
                                if (!ctx.mounted) return;
                                setSheet(() {
                                  avatar = i;
                                  final current = controller.text.trim();
                                  if (current.isEmpty || kAvatars.any((a) => a.nick == current)) {
                                    controller.text = defaultNickname(i);
                                  }
                                });
                              },
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: i == avatar ? Theme.of(ctx).colorScheme.primary : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: AvatarBadge(index: i, radius: 22, locked: i != avatar),
                            ),
                          ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tx('Seri ilerledikçe Hediyelerim\'de yeni avatarlar açılır.'),
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      final r = ContentModerator.check(controller.text, minLength: 2, maxLength: 24);
                      if (!r.isOk) {
                        setSheet(() => error = tx('Bu takma ad kullanılamıyor.'));
                        return;
                      }
                      if (uid != null) {
                        final nick = controller.text.trim();
                        repo.updateIdentity(uid, nickname: nick, avatar: avatar);
                        unawaited(
                          community
                              .ensureProfile(uid, nickname: nick, avatar: avatar, daily: user.daily)
                              .catchError((Object e) => debugPrint('Profil: $e')),
                        );
                      }
                      Navigator.pop(ctx);
                    },
                    child: Text(tx('Kaydet')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.icon);
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: scheme.tertiary),
          const SizedBox(height: 4),
          Text(value, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: t.labelSmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
