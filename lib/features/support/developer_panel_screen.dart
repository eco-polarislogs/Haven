import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/time_ago.dart';
import '../../data/models/support_ticket.dart';
import '../../l10n/tx.dart';
import '../../providers.dart';
import '../community/translatable_text.dart';
import 'ticket_widgets.dart';

/// Geliştirici paneli: kullanıcılardan gelen destek ve öneri talepleri.
/// Yalnızca `kDeveloperUids` içindeki hesaplara görünür; Firestore kuralları
/// da başka hiç kimsenin bu talepleri okumasına izin vermez.
class DeveloperPanelScreen extends ConsumerStatefulWidget {
  const DeveloperPanelScreen({super.key});

  @override
  ConsumerState<DeveloperPanelScreen> createState() => _DeveloperPanelScreenState();
}

class _DeveloperPanelScreenState extends ConsumerState<DeveloperPanelScreen> {
  TicketStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tickets = ref.watch(allTicketsProvider);
    if (!ref.watch(isDeveloperProvider)) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(tx('Bu sayfa yalnızca geliştiriciye açık.'))),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(tx('Geliştirici paneli'))),
      body: tickets.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(tx('Talepler yüklenemedi: {e}', {'e': e}), textAlign: TextAlign.center),
          ),
        ),
        data: (all) {
          final count = {for (final s in TicketStatus.values) s: all.where((x) => x.status == s).length};
          final list = _filter == null ? all : all.where((x) => x.status == _filter).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _Count(value: all.length, label: tx('toplam')),
                    _Count(value: count[TicketStatus.open]!, label: tx('yeni')),
                    _Count(value: all.where((x) => x.kind == TicketKind.idea).length, label: tx('öneri')),
                    _Count(value: all.where((x) => x.kind == TicketKind.bug).length, label: tx('hata')),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('${tx('Tümü')} · ${all.length}'),
                      selected: _filter == null,
                      onSelected: (_) => setState(() => _filter = null),
                    ),
                    for (final s in TicketStatus.values) ...[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('${s.label(developer: true)} · ${count[s]}'),
                        selected: _filter == s,
                        onSelected: (_) => setState(() => _filter = s),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            all.isEmpty
                                ? tx('Henüz talep yok. Kullanıcılar Profil → Destek ve öneriler\'den yazabilir.')
                                : tx('Bu durumda talep yok.'),
                            textAlign: TextAlign.center,
                            style: t.bodyMedium,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                        itemBuilder: (context, i) => _DevTicketTile(ticket: list[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: t.bodySmall),
        ],
      ),
    );
  }
}

String _who(SupportTicket ticket) => ticket.nickname ?? tx('İsimsiz');

class _DevTicketTile extends StatelessWidget {
  const _DevTicketTile({required this.ticket});
  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final fresh = ticket.status == TicketStatus.open;
    return ListTile(
      tileColor: fresh ? scheme.primaryContainer.withValues(alpha: 0.3) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        child: Icon(ticket.kind.icon, color: scheme.primary),
      ),
      title: Text(
        ticket.text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: t.bodyLarge?.copyWith(fontWeight: fresh ? FontWeight.w700 : FontWeight.w400),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TicketStatusChip(status: ticket.status, developer: true),
            Text(
              '${ticket.kind.label} · ${_who(ticket)} · ${timeAgo(ticket.createdAt)} · ${ticket.lang.toUpperCase()}',
              style: t.bodySmall,
            ),
            if (ticket.hasReply) Icon(Icons.reply_rounded, size: 16, color: scheme.primary),
          ],
        ),
      ),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _TicketSheet(ticket: ticket),
      ),
    );
  }
}

/// Talep ayrıntısı: tam metin (gerekirse çeviri), cihaz bilgisi, durum ve yanıt.
class _TicketSheet extends ConsumerStatefulWidget {
  const _TicketSheet({required this.ticket});
  final SupportTicket ticket;

  @override
  ConsumerState<_TicketSheet> createState() => _TicketSheetState();
}

class _TicketSheetState extends ConsumerState<_TicketSheet> {
  late final _reply = TextEditingController(text: widget.ticket.reply ?? '');
  late TicketStatus _status = widget.ticket.status == TicketStatus.open ? TicketStatus.seen : widget.ticket.status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ref.read(supportRepositoryProvider).markSeen(widget.ticket);
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    final repo = ref.read(supportRepositoryProvider);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final notified = await repo.answer(
        widget.ticket,
        developerUid: uid,
        status: _status,
        reply: _reply.text,
        replyLang: Tx.code,
      );
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(notified ? tx('Kaydedildi; kullanıcıya bildirim gitti.') : tx('Kaydedildi.'))),
      );
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(tx('Kaydedilemedi: {e}', {'e': e}))));
    }
  }

  Future<void> _delete() async {
    final repo = ref.read(supportRepositoryProvider);
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tx('Bu talebi silmek istiyor musun?')),
        content: Text(tx('Kullanıcı da artık göremez. Bu işlem geri alınamaz.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tx('Vazgeç'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tx('Sil'))),
        ],
      ),
    );
    if (ok != true) return;
    await repo.delete(widget.ticket).catchError((Object _) {});
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ticket.kind.icon, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(ticket.kind.label, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: tx('Talebi sil'),
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _delete,
                ),
              ],
            ),
            Text(
              '${_who(ticket)} · ${timeAgo(ticket.createdAt)} · ${ticket.lang.toUpperCase()} · ${ticket.platform} · v${ticket.appVersion}',
              style: t.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TranslatableText(text: ticket.text, lang: ticket.lang, style: t.bodyLarge),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: ticket.text));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tx('Metin kopyalandı.'))));
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: Text(tx('Kopyala')),
              ),
            ),
            Text(tx('Durum'), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in TicketStatus.values.where((s) => s != TicketStatus.open))
                  ChoiceChip(
                    avatar: Icon(s.icon, size: 16),
                    label: Text(s.label(developer: true)),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _reply,
              minLines: 3,
              maxLines: 8,
              maxLength: SupportTicket.maxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: tx('Kullanıcıya yanıt (isteğe bağlı)'),
                hintText: tx('Teşekkür et, ne yapacağını ya da nasıl çözüleceğini yaz.'),
                alignLabelWithHint: true,
              ),
            ),
            Text(
              tx(
                'Yeni bir yanıt yazarsan ya da durumu "Planlandı" / "Tamamlandı" yaparsan kullanıcıya bildirim gider.',
              ),
              style: t.bodySmall,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_rounded),
                label: Text(tx('Kaydet')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
