import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/moderation/content_moderator.dart';
import '../../core/navigation.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/avatar_badge.dart';
import '../../data/models/support_ticket.dart';
import '../../l10n/tx.dart';
import '../../providers.dart';
import '../community/translatable_text.dart';
import 'professional_support_screen.dart';
import 'ticket_widgets.dart';

/// "Destek ve öneriler": kullanıcı geliştiriciye öneri, hata bildirimi ya da
/// soru gönderir; gönderdiği talepleri, durumlarını ve geliştiricinin
/// yanıtını burada görür. Talepler toplulukta görünmez.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _text = TextEditingController();
  TicketKind _kind = TicketKind.idea;
  bool _withName = false;
  bool _sending = false;
  bool _crisis = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    // Talep acil bir durumu anlatıyorsa beklemeden destek hatlarını göster.
    final crisis =
        ContentModerator.check(v, minLength: 1, maxLength: SupportTicket.maxLength * 2).verdict ==
        ModerationVerdict.crisis;
    setState(() => _crisis = crisis);
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (text.length < SupportTicket.minLength) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(tx('Biraz daha ayrıntı yazar mısın? (en az {n} karakter)', {'n': SupportTicket.minLength})),
        ),
      );
      return;
    }
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    final last = (ref.read(myTicketsProvider).value ?? const <SupportTicket>[]).firstOrNull;
    if (last != null && (last.createdAt == null || DateTime.now().difference(last.createdAt!).inSeconds < 60)) {
      messenger.showSnackBar(
        SnackBar(content: Text(tx('Az önce bir talep gönderdin; bir dakika sonra tekrar dener misin?'))),
      );
      return;
    }
    // Servisleri await'ten ÖNCE al (Riverpod 3).
    final repo = ref.read(supportRepositoryProvider);
    final nickname = _withName ? ref.read(appUserProvider).value?.nickname : null;
    final lang = Tx.code;
    setState(() => _sending = true);
    try {
      final confirmed = await repo.submit(uid: uid, kind: _kind, text: text, lang: lang, nickname: nickname);
      if (!mounted) return;
      _text.clear();
      setState(() => _crisis = false);
      FocusScope.of(context).unfocus();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            confirmed
                ? tx('Teşekkürler! Talebin geliştiriciye ulaştı. Yanıt gelince bildirim alacaksın.')
                : tx('Şu an internet yok; talebin kaydedildi ve bağlantı gelince otomatik gönderilecek.'),
          ),
        ),
      );
    } on FirebaseException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(tx('Talep gönderilemedi ({code}). Biraz sonra tekrar dener misin?', {'code': e.code}))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(SupportTicket t) async {
    final repo = ref.read(supportRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tx('Bu talebi silmek istiyor musun?')),
        content: Text(tx('Geliştirici de artık göremez. Bu işlem geri alınamaz.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tx('Vazgeç'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tx('Sil'))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await repo.delete(t);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(tx('Talep silinemedi. Biraz sonra tekrar dener misin?'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tickets = ref.watch(myTicketsProvider);
    final nickname = ref.watch(appUserProvider).value?.nickname;

    return Scaffold(
      appBar: AppBar(title: Text(tx('Destek ve öneriler'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            color: scheme.primaryContainer.withValues(alpha: 0.45),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.forum_outlined, color: scheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx('Haven\'ı birlikte geliştirelim'),
                          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tx(
                            'Önerilerin, karşılaştığın hatalar ve soruların doğrudan geliştiriciye ulaşır. Toplulukta görünmez; yanıtı burada ve bildirimlerinde görürsün.',
                          ),
                          style: t.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SectionTitle(tx('Ne hakkında?')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in TicketKind.values)
                ChoiceChip(
                  avatar: Icon(k.icon, size: 18),
                  label: Text(k.label),
                  selected: _kind == k,
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _text,
            onChanged: _onChanged,
            minLines: 5,
            maxLines: 10,
            maxLength: SupportTicket.maxLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: _kind.hint, alignLabelWithHint: true),
          ),
          if (_crisis) ...[
            const SizedBox(height: 4),
            Card(
              color: scheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx('Şu an kendini güvende hissetmiyorsan lütfen bekleme.'),
                      style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tx(
                        'Bu form acil durumlar için değil; yanıt birkaç gün sürebilir. Destek hatları seni hemen dinleyebilir.',
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => pushScreen(context, 'professional_support', const ProfessionalSupportScreen()),
                      icon: const Icon(Icons.phone_in_talk_rounded),
                      label: Text(tx('Destek hatlarını aç')),
                    ),
                  ],
                ),
              ),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _withName,
            onChanged: nickname == null ? null : (v) => setState(() => _withName = v),
            title: Text(tx('Takma adımı ekle')),
            subtitle: Text(
              _withName
                  ? tx('Geliştirici talebini "{name}" adıyla görür.', {'name': nickname ?? ''})
                  : tx('Talebin isimsiz gider; yanıt yine sana ulaşır.'),
            ),
          ),
          Text(
            tx(
              'Talebe yalnızca uygulama dili, cihaz türü ve sürüm eklenir. Mücadele alanların ve notların paylaşılmaz.',
            ),
            style: t.bodySmall,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded),
            label: Text(tx('Geliştiriciye gönder')),
          ),
          SectionTitle(tx('Taleplerim')),
          tickets.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
            ),
            error: (e, _) => Text(tx('Talepler şu an yüklenemedi.'), style: t.bodySmall),
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      tx('Henüz bir talep göndermedin. Aklına gelen her fikir Haven\'ı daha iyi yapar.'),
                      style: t.bodySmall,
                    ),
                  )
                : Column(
                    children: [
                      for (final ticket in list) _MyTicketCard(ticket: ticket, onDelete: () => _delete(ticket)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MyTicketCard extends StatelessWidget {
  const _MyTicketCard({required this.ticket, required this.onDelete});

  final SupportTicket ticket;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ticket.kind.icon, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(ticket.kind.label, style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                ),
                TicketStatusChip(status: ticket.status),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(ticket.text, style: t.bodyMedium),
            ),
            if (ticket.hasReply) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.support_agent_rounded, size: 18, color: scheme.primary),
                        const SizedBox(width: 6),
                        Text(tx('Geliştiricinin yanıtı'), style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text(timeAgo(ticket.repliedAt), style: t.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TranslatableText(text: ticket.reply!, lang: ticket.replyLang ?? 'tr', style: t.bodyMedium),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Text(timeAgo(ticket.createdAt), style: t.bodySmall),
                const Spacer(),
                IconButton(
                  tooltip: tx('Talebi sil'),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
