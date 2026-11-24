import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/struggle_catalog.dart';
import '../../core/moderation/content_moderator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/community.dart';
import '../../providers.dart';
import '../support/hard_day_sheet.dart';
import 'community_screen.dart';
import '../../l10n/tx.dart';

Future<void> showComposeNoteSheet(BuildContext context) =>
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => const _ComposeNoteSheet());

class _ComposeNoteSheet extends ConsumerStatefulWidget {
  const _ComposeNoteSheet();

  @override
  ConsumerState<_ComposeNoteSheet> createState() => _ComposeNoteSheetState();
}

class _ComposeNoteSheetState extends ConsumerState<_ComposeNoteSheet> {
  final _controller = TextEditingController();
  StruggleCategory? _circle;
  String? _problem;
  bool _sending = false;

  /// Gönderi başına seçim: isimle (takma ad + avatar + seri) ya da anonim.
  bool _anonymous = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final circle = _circle;
    final me = ref.read(myProfileProvider).value;
    if (circle == null || me == null) return;

    final result = ContentModerator.check(_controller.text, circle: circle);
    final analytics = ref.read(analyticsProvider);
    if (!result.isOk) {
      analytics.noteBlocked(result.verdict.name);
      if (result.verdict == ModerationVerdict.crisis) {
        final nav = Navigator.of(context);
        final rootContext = nav.context;
        nav.pop();
        showCrisisSheet(rootContext);
        return;
      }
      setState(() => _problem = result.message);
      return;
    }

    setState(() {
      _sending = true;
      _problem = null;
    });
    final repo = ref.read(communityRepositoryProvider);
    final streak = currentDailyStreak(ref);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.postNote(author: me, circle: circle, text: _controller.text, streak: streak, anonymous: _anonymous);
      analytics.notePosted(circle, anonymous: _anonymous);
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _anonymous
                ? tx('Anonim olarak paylaşıldı. Birinin gününe ışık olabilir. 💙')
                : tx('Paylaşıldı. Birinin gününe ışık olabilir. 💙'),
          ),
        ),
      );
    } on FirebaseException catch (e) {
      setState(() {
        _sending = false;
        _problem = e.code == 'permission-denied'
            ? tx('Bu not topluluk kurallarına takıldı. Daha yumuşak bir ifadeyle tekrar dener misin?')
            : tx('Not şu an paylaşılamadı. İnternet bağlantını kontrol eder misin?');
      });
    } catch (_) {
      setState(() {
        _sending = false;
        _problem = tx('Not şu an paylaşılamadı. İnternet bağlantını kontrol eder misin?');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider).value;
    final circles = (user?.categoryIds ?? const <String>[]).map(categoryByName).whereType<StruggleCategory>().toList();
    _circle ??= circles.isEmpty ? null : circles.first;
    final t = Theme.of(context).textTheme;
    final me = ref.watch(myProfileProvider).value;
    final profileReady = me != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tx('Bir şey paylaş'), style: t.titleLarge),
              const SizedBox(height: 4),
              Text(
                tx(
                  'Seni güçlendiren bir şeyi paylaş. Ayrıntılara (sayılar, yöntemler) girmeden, hislerinin üzerinden yazmak herkes için daha güvenli.',
                ),
                style: t.bodySmall,
              ),
              const SizedBox(height: 14),
              Text(tx('Hangi çembere?'), style: t.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in circles)
                    ChoiceChip(
                      avatar: Icon(c.icon, size: 16, color: categoryAccent(c)),
                      label: Text(c.shortTitle),
                      selected: _circle == c,
                      onSelected: (_) => setState(() => _circle = c),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(tx('Nasıl görünsün?'), style: t.labelLarge),
              const SizedBox(height: 6),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.person_outline_rounded),
                    label: Text(me?.nickname ?? tx('İsmimle'), overflow: TextOverflow.ellipsis),
                  ),
                  ButtonSegment(value: true, icon: Icon(Icons.visibility_off_outlined), label: Text(tx('Anonim'))),
                ],
                selected: {_anonymous},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _anonymous = s.first),
              ),
              const SizedBox(height: 6),
              Text(
                _anonymous
                    ? tx(
                        'Adın, avatarın ve serin görünmez; "{anonymousName}" olarak paylaşılır. Yalnızca hangi alanda paylaştığın görünür.',
                        {'anonymousName': tx(CommunityNote.anonymousName)},
                      )
                    : tx('Takma adın, avatarın ve serin görünür; hangi alanda paylaştığın da yazar.'),
                style: t.bodySmall,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                maxLength: ContentModerator.maxNoteLength,
                minLines: 3,
                maxLines: 6,
                onChanged: (_) {
                  if (_problem != null) setState(() => _problem = null);
                },
                decoration: InputDecoration(hintText: tx('Bugün kendim için yaptığım küçük bir şey…')),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final p in txList(kNotePrompts))
                    ActionChip(
                      label: Text(p.trim(), style: t.labelSmall),
                      onPressed: () => setState(() => _controller.text = p),
                    ),
                ],
              ),
              if (_problem != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: HavenStyle.of(context)
                      .box(color: HavenStyle.of(context).danger.withValues(alpha: 0.12), radius: 14, outlined: false),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: HavenStyle.of(context).danger),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_problem!, style: t.bodyMedium)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: (_sending || _circle == null || !profileReady) ? null : _send,
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(profileReady ? tx('Paylaş') : tx('Profil hazırlanıyor…')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
