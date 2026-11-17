import '../../core/constants/struggle_catalog.dart';
import '../../core/utils/streak.dart';

/// `users/{uid}/struggles/{typeId}` dokümanı.
/// Seri sayaçları ve biten serilerin geçmişi burada denormalize tutulur:
/// ana ekran geçmişi taramadan, alan başına TEK doküman okuyarak çizilir.
class Struggle {
  const Struggle({required this.type, required this.streak, this.lastResult});

  final StruggleType type;
  final StreakState streak;
  final CheckInResult? lastResult;

  String get id => type.id;
  StruggleCategory get category => type.category;

  bool checkedInOn(String day) => streak.lastCheckInDay == day;

  /// Katalogdan kaldırılmış eski bir tip ise `null` döner (sessizce atlanır).
  static Struggle? fromMap(String id, Map<String, dynamic> m) {
    final type = struggleTypeById(id);
    if (type == null) return null;
    return Struggle(
      type: type,
      streak: StreakState(
        current: (m['currentStreak'] as num?)?.toInt() ?? 0,
        longest: (m['longestStreak'] as num?)?.toInt() ?? 0,
        totalKindDays: (m['totalKindDays'] as num?)?.toInt() ?? 0,
        lastKindDay: m['lastKindDay'] as String?,
        lastCheckInDay: m['lastCheckInDay'] as String?,
        history: [for (final h in (m['history'] as List? ?? const [])) ?PastStreak.fromMap(h)],
      ),
      lastResult: CheckInResult.values.asNameMap()[m['lastResult']],
    );
  }
}
