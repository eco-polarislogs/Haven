import '../../l10n/tx.dart';

String timeAgo(DateTime? t) {
  if (t == null) return tx('az önce');
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return tx('az önce');
  if (d.inMinutes < 60) return tx('{inMinutes} dk önce', {'inMinutes': d.inMinutes});
  if (d.inHours < 24) return tx('{inHours} sa önce', {'inHours': d.inHours});
  if (d.inDays < 7) return tx('{inDays} gün önce', {'inDays': d.inDays});
  return '${t.day}.${t.month}.${t.year}';
}
