import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/struggle_catalog.dart';
import '../../core/moderation/content_moderator.dart';
import '../../core/theme/app_theme.dart';
import '../../providers.dart';
import '../support/hard_day_sheet.dart';
import 'community_screen.dart';

Future<void> showComposeNoteSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ComposeNoteSheet(),
    );

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
      await repo.postNote(author: me, circle: circle, text: _controller.text, streak: streak);
      analytics.notePosted(circle);
      nav.pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Notun paylaşıldı. Birinin gününe ışık olabilir. 💙')));
    } on FirebaseException catch (e) {
      setState(() {
        _sending = false;
        _problem = e.code == 'permission-denied'
            ? 'Bu not topluluk kurallarına takıldı. Daha yumuşak bir ifadeyle tekrar dener misin?'
            : 'Not şu an paylaşılamadı. İnternet bağlantını kontrol eder misin?';
      });
    } catch (_) {
      setState(() {
        _sending = false;
        _problem = 'Not şu an paylaşılamadı. İnternet bağlantını kontrol eder misin?';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider).value;
    final circles = (user?.categoryIds ?? const <String>[])
        .map(categoryByName)
        .whereType<StruggleCategory>()
        .toList();
    _circle ??= circles.isEmpty ? null : circles.first;
    final t = Theme.of(context).textTheme;
    final profileReady = ref.watch(myProfileProvider).value != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bir şey paylaş', style: t.titleLarge),
              const SizedBox(height: 4),
              Text('Seni güçlendiren bir şeyi paylaş. Ayrıntılara (sayılar, yöntemler) girmeden, '
                  'hislerinin üzerinden yazmak herkes için daha güvenli.',
                  style: t.bodySmall),
              const SizedBox(height: 14),
              Text('Hangi çembere?', style: t.labelLarge),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in circles)
                  ChoiceChip(
                    avatar: Icon(c.icon, size: 16, color: categoryAccent(c)),
                    label: Text(c.shortTitle),
                    selected: _circle == c,
                    onSelected: (_) => setState(() => _circle = c),
                  ),
              ]),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                maxLength: ContentModerator.maxNoteLength,
                minLines: 3,
                maxLines: 6,
                onChanged: (_) {
                  if (_problem != null) setState(() => _problem = null);
                },
                decoration: const InputDecoration(hintText: 'Bugün kendim için yaptığım küçük bir şey…'),
              ),
              Wrap(spacing: 8, runSpacing: 4, children: [
                for (final p in kNotePrompts)
                  ActionChip(
                    label: Text(p.trim(), style: t.labelSmall),
                    onPressed: () => setState(() => _controller.text = p),
                  ),
              ]),
              if (_problem != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HavenColors.clay.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline_rounded, color: HavenColors.clay),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_problem!, style: t.bodyMedium)),
                  ]),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: (_sending || _circle == null || !profileReady) ? null : _send,
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                label: Text(profileReady ? 'Paylaş' : 'Profil hazırlanıyor…'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
