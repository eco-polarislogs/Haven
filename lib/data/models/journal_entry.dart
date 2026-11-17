import 'package:cloud_firestore/cloud_firestore.dart';

/// `users/{uid}/journal/{id}` — kullanıcının KENDİNE yazdığı özel notlar.
/// Kimseyle paylaşılmaz; topluluk notlarından ayrıdır.
class JournalEntry {
  const JournalEntry({required this.id, required this.text, required this.createdAt});

  final String id;
  final String text;
  final DateTime? createdAt;

  factory JournalEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    final ts = m['createdAt'];
    return JournalEntry(
      id: d.id,
      text: m['text'] as String? ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
