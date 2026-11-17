import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/moderation/content_moderator.dart';
import '../../core/utils/time_ago.dart';
import '../../l10n/l10n.dart';
import '../../providers.dart';
import '../support/hard_day_sheet.dart';

/// "Notlarım": kendine yazdığın özel notlar. Kimseyle paylaşılmaz.
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final notes = ref.watch(journalProvider).value ?? const [];
    final uid = ref.watch(uidProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.myNotes)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_journal',
        onPressed: () => showAddJournalSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.addNote),
      ),
      body: notes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.menu_book_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(l.noNotesYet, textAlign: TextAlign.center, style: t.bodyLarge),
                  const SizedBox(height: 6),
                  Text('Bu notları yalnızca sen görürsün.', style: t.bodySmall),
                ]),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
              itemCount: notes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final n = notes[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n.text, style: t.bodyLarge?.copyWith(height: 1.4)),
                          const SizedBox(height: 6),
                          Text(timeAgo(n.createdAt), style: t.labelSmall),
                        ]),
                      ),
                      IconButton(
                        tooltip: 'Sil',
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: uid == null ? null : () => ref.read(repositoryProvider).deleteJournal(uid, n.id),
                      ),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}

Future<void> showAddJournalSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddJournalSheet(),
    );

class _AddJournalSheet extends ConsumerStatefulWidget {
  const _AddJournalSheet();

  @override
  ConsumerState<_AddJournalSheet> createState() => _AddJournalSheetState();
}

class _AddJournalSheetState extends ConsumerState<_AddJournalSheet> {
  final _controller = TextEditingController();

  static const _prompts = [
    'Bugün bana iyi gelen bir şey…',
    'Şu an hissettiğim…',
    'Kendime söylemek istediğim…',
    'Yarın için küçük bir niyet…',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    final uid = ref.read(uidProvider);
    if (text.isEmpty || uid == null) return;
    ref.read(repositoryProvider).addJournal(uid, text);
    final nav = Navigator.of(context);
    final root = nav.context;
    nav.pop();
    // Özel not olduğu için kelime filtresi uygulanmaz; ama kriz işareti varsa
    // kullanıcıyı yalnız bırakmayız.
    if (ContentModerator.check(text, maxLength: 2000).verdict == ModerationVerdict.crisis) {
      showCrisisSheet(root);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.addNote, style: t.titleLarge),
            const SizedBox(height: 4),
            Text('Bu not yalnızca sana özel. Yargı yok; ne hissediyorsan yazabilirsin.', style: t.bodySmall),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 4,
              maxLines: 8,
              maxLength: 1000,
              decoration: const InputDecoration(hintText: 'Bugün…'),
            ),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final p in _prompts)
                ActionChip(label: Text(p, style: t.labelSmall), onPressed: () => _controller.text = p),
            ]),
            const SizedBox(height: 12),
            FilledButton(onPressed: _save, child: Text(l.save)),
          ]),
        ),
      ),
    );
  }
}
