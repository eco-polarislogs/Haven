String timeAgo(DateTime? t) {
  if (t == null) return 'az önce';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'az önce';
  if (d.inMinutes < 60) return '${d.inMinutes} dk önce';
  if (d.inHours < 24) return '${d.inHours} sa önce';
  if (d.inDays < 7) return '${d.inDays} gün önce';
  return '${t.day}.${t.month}.${t.year}';
}
