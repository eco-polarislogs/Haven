import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/avatar_badge.dart';
import '../../l10n/tx.dart';
import '../../providers.dart';

/// Topluluktaki "Bildir" ve "Engelle" işlemleri (paylaşım, yanıt ve profil
/// ekranları ortak kullanır). Google Play ve App Store, kullanıcı içeriği olan
/// uygulamalarda içeriği bildirme ve kullanıcıyı engelleme imkânını zorunlu tutar.

/// Bildirme nedeni seçtirir; vazgeçilirse `null`.
Future<String?> pickReportReason(BuildContext context, {required String prompt}) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 8), child: Text(prompt)),
          for (final r in [
            tx('Kırıcı veya küçümseyici'),
            tx('Tetikleyici içerik'),
            tx('Spam veya reklam'),
            tx('Başka bir şey'),
          ])
            ListTile(leading: const Icon(Icons.flag_outlined), title: Text(r), onTap: () => Navigator.pop(ctx, r)),
        ],
      ),
    ),
  );
}

/// Şikâyeti geliştiricinin paneline iletir (arka planda; hata kullanıcıyı durdurmaz).
void sendReportToDeveloper(WidgetRef ref, {required String target, required String reason, required String quote}) {
  final uid = ref.read(uidProvider);
  if (uid == null) return;
  unawaited(
    ref
        .read(supportRepositoryProvider)
        .report(uid: uid, target: target, reason: reason, quote: quote, lang: Tx.code)
        .then((_) {}, onError: (Object e) => debugPrint('Şikâyet iletilemedi: $e')),
  );
}

/// Onay alıp kullanıcıyı engeller. Engellendiyse `true`.
Future<bool> confirmBlock(BuildContext context, WidgetRef ref, {required String otherUid, required String name}) async {
  final uid = ref.read(uidProvider);
  if (uid == null || uid == otherUid) return false;
  final repo = ref.read(communityRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.block_rounded),
      title: Text(tx('{name} engellensin mi?', {'name': name})),
      content: Text(
        tx(
          'Paylaşımlarını ve yanıtlarını artık görmezsin; sana arkadaşlık isteği ya da not gönderemez. Arkadaşsanız arkadaşlığınız biter. Ona haber verilmez; istediğin zaman Profil → Engellediğin kişiler\'den kaldırabilirsin.',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tx('Vazgeç'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tx('Engelle'))),
      ],
    ),
  );
  if (ok != true) return false;
  try {
    await repo.blockUser(uid, otherUid);
    messenger.showSnackBar(SnackBar(content: Text(tx('{name} engellendi.', {'name': name}))));
    return true;
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(tx('Şu an engellenemedi. Biraz sonra tekrar dener misin?'))));
    return false;
  }
}

/// Profil → Engellediğin kişiler.
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedUidsProvider).toList();
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(tx('Engellediğin kişiler'))),
      body: blocked.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  tx('Kimseyi engellemedin. Bir paylaşımın ya da profilin menüsünden engelleyebilirsin.'),
                  textAlign: TextAlign.center,
                  style: t.bodyMedium,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: blocked.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, i) => _BlockedTile(uid: blocked[i]),
            ),
    );
  }
}

class _BlockedTile extends ConsumerWidget {
  const _BlockedTile({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider(uid)).value;
    final name = profile?.nickname ?? tx('Haven üyesi');
    return ListTile(
      leading: AvatarBadge(index: profile?.avatar ?? 0, radius: 22),
      title: Text(name),
      trailing: OutlinedButton(
        onPressed: () async {
          final me = ref.read(uidProvider);
          final messenger = ScaffoldMessenger.of(context);
          if (me == null) return;
          try {
            await ref.read(communityRepositoryProvider).unblockUser(me, uid);
            messenger.showSnackBar(SnackBar(content: Text(tx('{name} artık engelli değil.', {'name': name}))));
          } catch (_) {
            messenger.showSnackBar(SnackBar(content: Text(tx('Şu an yapılamadı. Biraz sonra tekrar dener misin?'))));
          }
        },
        child: Text(tx('Engeli kaldır')),
      ),
    );
  }
}
