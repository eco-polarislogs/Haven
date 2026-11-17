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
import '../../providers.dart';
import '../notifications/notification_bell.dart';
import '../onboarding/struggle_picker_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../ads/rewarded_unlock.dart';
import '../rewards/gifts_screen.dart';
import '../support/professional_support_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    // Servisleri await'lerden ÖNCE al (Riverpod 3: ekran kalkınca ref kullanılamaz).
    final navigator = Navigator.of(context);
    final uid = ref.read(uidProvider);
    final repo = ref.read(repositoryProvider);
    final notifications = ref.read(notificationServiceProvider);
    final auth = ref.read(authServiceProvider);
    ref.read(shellIndexProvider.notifier).select(0);
    if (uid != null) await repo.addInboxAndWait(uid, InboxType.logout);
    await notifications.stop();
    await auth.signOut();
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
        title: const Text('Her şeyi silmek istediğine emin misin?'),
        content: const Text('Seçtiğin alanlar, tüm kayıtların, topluluk notların, arkadaşlıkların ve '
            'hesabın kalıcı olarak silinecek. Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Evet, sil')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted || uid == null) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await notifications.stop();
      await repo.deleteAllUserData(uid);
      await auth.deleteAccount();
      navigator.popUntil((route) => route.isFirst);
    } on AuthFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Silme işlemi için internet bağlantısı gerekiyor. Bağlantın gelince tekrar dener misin?')));
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
      appBar: AppBar(title: const Text('Profil'), actions: const [NotificationBell(), SizedBox(width: 4)]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                Row(children: [
                  AvatarBadge(index: user.avatar, radius: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user.nickname ?? '', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      InkWell(
                        onTap: profile == null
                            ? null
                            : () {
                                Clipboard.setData(ClipboardData(text: profile.friendCode));
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(content: Text('Arkadaş kodun kopyalandı.')));
                              },
                        child: Row(children: [
                          Text('Arkadaş kodu: ${profile?.friendCode ?? '…'}', style: t.bodySmall),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded, size: 14),
                        ]),
                      ),
                    ]),
                  ),
                  IconButton(
                    tooltip: 'Profili düzenle',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editProfile(context, ref, user),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  _Stat('${user.daily.live(todayKey())}', 'günlük seri', Icons.local_fire_department_rounded),
                  _Stat('${user.daily.longest}', 'en uzun seri', Icons.emoji_events_outlined),
                  _Stat('$totalKind', 'iyi geçen gün', Icons.light_mode_outlined),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            color: scheme.tertiary.withValues(alpha: 0.13),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              leading: Icon(Icons.volunteer_activism_outlined, color: scheme.tertiary),
              title: const Text('Destek al', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Kriz hatları ve profesyonel desteğe nasıl ulaşılır'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => pushScreen(context, 'professional_support', const ProfessionalSupportScreen()),
            ),
          ),
          const SectionTitle('Yolculuğum'),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Mücadele alanlarım'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => pushScreen(context, 'edit_struggles', const StrugglePickerScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.card_giftcard_outlined),
                title: Text(context.l10n.giftsTitle),
                subtitle: const Text('Seriyle açılan temalar ve avatarlar'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => pushScreen(context, 'gifts', const GiftsScreen()),
              ),
            ]),
          ),
          const SectionTitle('Topluluk ve bildirimler'),
          Card(
            child: Column(children: [
              SwitchListTile(
                value: user.communityJoined,
                onChanged: (v) {
                  repo.setCommunityJoined(uid, v);
                  ref.read(analyticsProvider).communityJoined(v);
                  if (v) {
                    unawaited(ref
                        .read(communityRepositoryProvider)
                        .ensureProfile(uid, nickname: user.nickname ?? 'Haven üyesi', avatar: user.avatar, daily: user.daily)
                        .catchError((Object e) => debugPrint('Profil: $e')));
                  }
                },
                secondary: const Icon(Icons.groups_outlined),
                title: const Text('Topluluğa katıl'),
                subtitle: const Text('Takma adın, avatarın ve serin görünür.'),
              ),
              SwitchListTile(
                value: user.notificationsEnabled,
                onChanged: (v) => repo.setNotificationsEnabled(uid, v),
                secondary: const Icon(Icons.notifications_active_outlined),
                title: const Text('Hatırlatmalar'),
                subtitle: const Text('Her gün 13.00\'te kısa bir motivasyon mesajı; bir süre görünmediğinde de '
                    'hal hatır sorarız. Yalnızca 10:00–21:00 arası.'),
              ),
              SwitchListTile(
                value: user.analyticsEnabled,
                onChanged: (v) {
                  repo.setAnalyticsEnabled(uid, v);
                  ref.read(analyticsProvider).setEnabled(v);
                },
                secondary: const Icon(Icons.insights_outlined),
                title: const Text('Anonim kullanım istatistikleri'),
                subtitle: const Text('Not içeriklerin ve kimliğin asla paylaşılmaz.'),
              ),
              SwitchListTile(
                value: user.adsAllowed,
                onChanged: (v) => repo.setAdsOptIn(uid, v),
                secondary: const Icon(Icons.verified_user_outlined),
                title: const Text('Filtreli reklamlar'),
                subtitle: const Text('Alt çubukta küçük bir reklam; temaları ve hediyeleri reklamla açabilme. '
                    'Hassas alanlarda varsayılan kapalı; Sakinleş ekranında asla reklam yok.'),
              ),
            ]),
          ),
          SectionTitle(context.l10n.themes),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final p in ThemePreset.values)
              Builder(builder: (context) {
                final open = isGiftUnlocked(
                    unlockStreak: p.unlockStreak, id: p.name, best: best, user: user);
                return ChoiceChip(
                  // Kilitli temada reklam izni varsa "reklamla aç" simgesi.
                  avatar: open
                      ? CircleAvatar(backgroundColor: p.primary, radius: 8)
                      : Icon(user.adsAllowed ? Icons.ondemand_video_rounded : Icons.lock_outline_rounded,
                          size: 16),
                  label: Text(p.label),
                  selected: currentTheme == p,
                  onSelected: open ? (_) => repo.setTheme(uid, p.name) : (_) => offerThemeUnlock(context, ref, p),
                );
              }),
          ]),
          SectionTitle(context.l10n.language),
          DropdownButtonFormField<String?>(
            initialValue: kLanguageCodes.contains(user.language) ? user.language : 'tr',
            decoration: const InputDecoration(prefixIcon: Icon(Icons.translate_rounded)),
            items: [
              for (final e in kLanguageNames.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (code) => repo.setLanguage(uid, code),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text('Psikolojik içerik metinleri şimdilik Türkçedir; çevirileri uzman gözden geçirmesiyle eklenecek.',
                style: t.bodySmall),
          ),
          const SectionTitle('Hesap'),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Gizlilik politikası'),
                onTap: () => launchUrl(Uri.parse(kPrivacyPolicyUrl)),
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Çıkış yap'),
                onTap: () => _signOut(context, ref),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: scheme.error),
                title: Text('Hesabımı ve tüm verilerimi sil', style: TextStyle(color: scheme.error)),
                onTap: () => _deleteAccount(context, ref),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Text('Haven bir tedavi aracı değildir; profesyonel desteğin yerini tutmaz.',
              textAlign: TextAlign.center, style: t.bodySmall),
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
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Profilini düzenle', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLength: 24,
                  onChanged: (_) => setSheet(() => error = null),
                  decoration: InputDecoration(labelText: 'Takma ad', errorText: error),
                ),
                Row(children: [
                  AvatarBadge(index: avatar, radius: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Varsayılan adı: ${defaultNickname(avatar)}',
                        style: Theme.of(ctx).textTheme.bodyMedium),
                  ),
                  if (controller.text.trim() != defaultNickname(avatar))
                    TextButton(
                      onPressed: () => setSheet(() {
                        controller.text = defaultNickname(avatar);
                        error = null;
                      }),
                      child: const Text('Bu adı kullan'),
                    ),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  for (var i = 0; i < kAvatars.length; i++)
                    if (isGiftUnlocked(
                        unlockStreak: kAvatars[i].unlockStreak,
                        id: 'avatar_$i',
                        best: best,
                        user: user))
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
                              width: 2.5),
                        ),
                        child: AvatarBadge(index: i, radius: 22),
                      ),
                    ),
                ]),
                const SizedBox(height: 8),
                Text('Seri ilerledikçe Hediyelerim\'de yeni avatarlar açılır.',
                    style: Theme.of(ctx).textTheme.bodySmall),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    final r = ContentModerator.check(controller.text, minLength: 2, maxLength: 24);
                    if (!r.isOk) {
                      setSheet(() => error = 'Bu takma ad kullanılamıyor.');
                      return;
                    }
                    if (uid != null) {
                      final nick = controller.text.trim();
                      repo.updateIdentity(uid, nickname: nick, avatar: avatar);
                      unawaited(community
                          .ensureProfile(uid, nickname: nick, avatar: avatar, daily: user.daily)
                          .catchError((Object e) => debugPrint('Profil: $e')));
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Kaydet'),
                ),
              ]),
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
      child: Column(children: [
        Icon(icon, color: scheme.tertiary),
        const SizedBox(height: 4),
        Text(value, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: t.labelSmall, textAlign: TextAlign.center),
      ]),
    );
  }
}
