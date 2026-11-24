import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/struggle_catalog.dart';
import '../../core/moderation/content_moderator.dart';
import '../../core/utils/streak.dart';
import '../../core/widgets/avatar_badge.dart';
import '../../data/models/community.dart';
import '../../l10n/l10n.dart';
import '../../providers.dart';
import 'struggle_selector.dart';
import '../../l10n/tx.dart';
import '../../core/theme/app_theme.dart';

/// Haven'ın kendi kayıt akışı: 1) takma ad + avatar, 2) alanlar,
/// 3) topluluk tercihi, 4) rıza. Google sadece kimliği doğruladı; gerisi burada.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _pages = PageController();
  late final TextEditingController _nick;
  late int _avatar;
  late bool _anonymous;
  bool _nickEdited = false;
  late final Set<String> _initial;
  late final Set<String> _selected;
  late bool _community;
  bool _consent = false;
  int _step = 0;
  String? _nickError;

  @override
  void initState() {
    super.initState();
    final user = ref.read(appUserProvider).value;
    _avatar = user?.avatar ?? Random().nextInt(kFreeAvatarCount);
    _anonymous = user?.anonymous ?? true;
    _nick = TextEditingController(text: user?.nickname ?? defaultNickname(_avatar));
    _nickEdited = user?.nickname != null;
    _initial = {...?user?.struggleIds};
    _selected = {..._initial};
    _community = user?.communityJoined ?? true;
  }

  @override
  void dispose() {
    _pages.dispose();
    _nick.dispose();
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
    0 => _nick.text.trim().length >= 2,
    1 => _selected.isNotEmpty,
    2 => true,
    _ => _consent,
  };

  void _next() {
    if (_step == 0) {
      final r = ContentModerator.check(_nick.text, minLength: 2, maxLength: 24);
      if (!r.isOk) {
        setState(
          () => _nickError = r.verdict == ModerationVerdict.tooLong
              ? tx('Takma ad en fazla 24 karakter olabilir.')
              : tx('Bu takma ad kullanılamıyor. Başka bir tane dener misin?'),
        );
        return;
      }
      _nickError = null;
    }
    if (_step == 3) return _finish();
    setState(() => _step++);
    _pages.animateToPage(_step, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  void _back() {
    setState(() => _step--);
    _pages.animateToPage(_step, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  void _finish() {
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    final repo = ref.read(repositoryProvider);
    final community = ref.read(communityRepositoryProvider);
    final analytics = ref.read(analyticsProvider);
    final daily = ref.read(appUserProvider).value?.daily;
    final nickname = _nick.text.trim();

    repo.completeOnboarding(
      uid,
      nickname: nickname,
      avatar: _avatar,
      anonymous: _anonymous,
      selected: _selected,
      previous: _initial,
      communityJoined: _community,
    );
    // Herkese açık profil (arkadaşlar için) — internet gerekir; olmazsa
    // Profil ekranından tekrar denenir.
    unawaited(
      community
          .ensureProfile(uid, nickname: nickname, avatar: _avatar, daily: daily ?? const DailyStreak())
          .catchError((Object e) => debugPrint('Profil oluşturulamadı: $e')),
    );
    if (_initial.isEmpty) repo.addInbox(uid, InboxType.welcome);
    analytics.onboardingCompleted(
      struggleCount: _selected.length,
      categoryCount: _selected.map((id) => struggleTypeById(id)!.category).toSet().length,
      community: _community,
    );
    // Yönlendirme yok: AuthGate kayıt tamamlanınca ana kabuğa geçer.
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    final titles = [l.stepProfile, l.stepAreas, l.stepCommunity, l.stepConsent];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: Container(
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= _step ? scheme.primary : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_step + 1}/4 · ${titles[_step]}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.primary),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _ProfileStep(
                    controller: _nick,
                    avatar: _avatar,
                    anonymous: _anonymous,
                    error: _nickError,
                    onAvatar: (i) => setState(() {
                      _avatar = i;
                      // Anonim ve takma adı elle değiştirmediyse, avatara göre yeni öneri.
                      if (_anonymous && !_nickEdited) _nick.text = defaultNickname(i);
                    }),
                    onAnonymous: (v) => setState(() {
                      _anonymous = v;
                      _nickEdited = false;
                      _nick.text = v ? defaultNickname(_avatar) : '';
                    }),
                    onChanged: () => setState(() {
                      _nickError = null;
                      _nickEdited = true;
                    }),
                    onShuffle: () => setState(() {
                      _nickEdited = false;
                      _nick.text = suggestNickname(avatar: _avatar);
                    }),
                  ),
                  _Scroll(
                    children: [
                      _Heading(l.areasTitle, '${l.areasSubtitle} ⓘ'),
                      StruggleSelector(
                        selected: _selected,
                        onToggle: (id) =>
                            setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id)),
                      ),
                    ],
                  ),
                  _CommunityStep(value: _community, onChanged: (v) => setState(() => _community = v)),
                  _ConsentStep(value: _consent, onChanged: (v) => setState(() => _consent = v)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (_step > 0) TextButton(onPressed: _back, child: Text(l.backButton)),
                  const Spacer(),
                  FilledButton(
                    onPressed: _canContinue ? _next : null,
                    child: Text(_step < 3 ? tx('Devam') : 'Haven\'a gir'),
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

class _Scroll extends StatelessWidget {
  const _Scroll({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 16), children: children);
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, this.subtitle);
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle, style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.controller,
    required this.avatar,
    required this.anonymous,
    required this.error,
    required this.onAvatar,
    required this.onAnonymous,
    required this.onChanged,
    required this.onShuffle,
  });

  final TextEditingController controller;
  final int avatar;
  final bool anonymous;
  final String? error;
  final ValueChanged<int> onAvatar;
  final ValueChanged<bool> onAnonymous;
  final VoidCallback onChanged;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    Widget choice(bool value, IconData icon, String title, String desc) {
      final selected = anonymous == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onAnonymous(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: selected ? scheme.primary : scheme.outline),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(desc, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
    }

    return _Scroll(
      children: [
        _Heading(l.profileTitle, l.profileSubtitle),
        Center(child: AvatarBadge(index: avatar, radius: 48)),
        const SizedBox(height: 16),
        Text(l.chooseAvatar, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // Kayıtta ücretsiz 7 hayvan; diğerleri "Hediyelerim"de seriyle açılır.
            for (var i = 0; i < kFreeAvatarCount; i++)
              GestureDetector(
                onTap: () => onAvatar(i),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: i == avatar ? scheme.primary : Colors.transparent, width: 2.5),
                  ),
                  child: AvatarBadge(index: i, radius: 24),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            choice(true, Icons.visibility_off_outlined, l.anonymousOption, l.anonymousOptionDesc),
            const SizedBox(width: 10),
            choice(false, Icons.badge_outlined, l.namedOption, l.namedOptionDesc),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: controller,
          maxLength: 24,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: anonymous ? l.nicknameLabel : l.nameLabel,
            errorText: error,
            suffixIcon: anonymous
                ? IconButton(tooltip: l.suggestAnother, icon: const Icon(Icons.casino_outlined), onPressed: onShuffle)
                : null,
          ),
        ),
        Text(
          anonymous
              ? tx('Toplulukta yalnızca bu takma ad ve avatarın görünür. Kim olduğunu kimse bilmez.')
              : tx('Adın yalnızca toplulukta görünür; e-postan ve kayıtların asla paylaşılmaz.'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CommunityStep extends StatelessWidget {
  const _CommunityStep({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    Widget rule(IconData icon, String s) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(s, style: text.bodyMedium)),
        ],
      ),
    );
    return _Scroll(
      children: [
        _Heading(
          tx('Aynı yolda yürüyenlerle buluş'),
          tx(
            'Haven topluluğunda benzer zorlukları yaşayan insanlar birbirine destek notları bırakır, serilerini görür ve cesaret verir.',
          ),
        ),
        HavenCard(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                rule(Icons.badge_outlined, tx('Toplulukta yalnızca takma adın, avatarın ve serin görünür.')),
                rule(Icons.lock_outline_rounded, tx('Gerçek adın, e-postan ve kişisel kayıtların asla paylaşılmaz.')),
                rule(
                  Icons.shield_outlined,
                  tx('Notlar kırıcı, küçümseyici veya tetikleyici içerik içeremez; otomatik olarak denetlenir.'),
                ),
                rule(Icons.flag_outlined, tx('Rahatsız edici bir not görürsen tek dokunuşla bildirebilirsin.')),
                rule(
                  Icons.volunteer_activism_outlined,
                  tx('Topluluk bir tedavi yerine geçmez; kriz anında destek hatları her zaman bir dokunuş uzağında.'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: value,
          onChanged: onChanged,
          title: Text(tx('Topluluğa katılmak istiyorum')),
          subtitle: Text(tx('İstediğin zaman Profil\'den değiştirebilirsin.')),
        ),
      ],
    );
  }
}

class _ConsentStep extends StatelessWidget {
  const _ConsentStep({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _Scroll(
      children: [
        _Heading(tx('Son bir adım'), tx('Haven\'ın nasıl çalıştığını bilmeni istiyoruz.')),
        HavenCard(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx(
                    'Haven bir tedavi ya da teşhis aracı değildir ve profesyonel desteğin yerini tutmaz. Kendini güvende hissetmediğin bir an olursa lütfen 112\'yi ara.',
                  ),
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  tx(
                    'Birazdan telefonun, arada bir nazikçe hal hatırını sormamıza izin verip vermediğini soracak. Asla yargılayıcı mesajlar göndermeyiz.',
                  ),
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  tx(
                    'Topluluk kuralları: saygılı ol. Kırıcı, tetikleyici, yöntem anlatan ya da kişisel bilgi içeren paylaşımlar kaldırılır; kuralları çiğneyen hesaplar engellenebilir. Rahatsız eden bir içeriği ya da kişiyi Bildir ve Engelle ile hemen gizleyebilirsin.',
                  ),
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            tx(
              'Seçtiğim alanların ve günlük kayıtlarımın, bana özel bir deneyim sunulması amacıyla hesabımda saklanmasına açık rıza veriyorum (KVKK) ve topluluk kurallarını kabul ediyorum.',
            ),
            style: text.bodyMedium,
          ),
        ),
      ],
    );
  }
}
