import '../../core/utils/streak.dart';

/// `users/{uid}` dokümanı — ÖZEL. Sadece sahibi okuyabilir.
class AppUser {
  const AppUser({
    required this.uid,
    required this.struggleIds,
    required this.categoryIds,
    required this.notificationsEnabled,
    required this.analyticsEnabled,
    required this.themeId,
    required this.unlockedThemes,
    required this.communityJoined,
    required this.daily,
    required this.supportedNotes,
    required this.reportedNotes,
    this.nickname,
    this.avatar = 0,
    this.anonymous = true,
    this.adsOptIn,
    this.language,
    this.country,
    this.quoteUnlockedDay,
    this.lastSupportSuggestionDay,
  });

  /// Kullanıcı kimliğini gizlemeyi seçti mi? (takma ad avatardan önerilir)
  final bool anonymous;

  /// null = varsayılan (hassas kategorilerde reklam KAPALI); true/false = kullanıcı seçimi.
  final bool? adsOptIn;

  /// 'tr' | 'en' | 'es' | 'zh' | 'hi' — null ise cihaz dili.
  final String? language;

  /// Destek hatları için seçilen ülke (ISO kodu); null = telefondan tahmin.
  final String? country;

  /// Bu kategoriler için reklamlar varsayılan olarak kapalıdır: zayıflama,
  /// bahis, alkol gibi reklamlar tetikleyici olabilir.
  static const sensitiveForAds = {'eating', 'selfHarm', 'substance', 'behavioral'};

  bool get adsAllowed => adsOptIn ?? !categoryIds.any(sensitiveForAds.contains);

  /// Tüm alanlardaki ve günlük serideki en iyi seri (hediyeleri açar).
  int bestStreak(Iterable<int> struggleBests) => [daily.longest, ...struggleBests].fold(0, (a, b) => a > b ? a : b);

  final String uid;
  final List<String> struggleIds;
  final List<String> categoryIds;
  final bool notificationsEnabled;
  final bool analyticsEnabled;
  final String themeId;
  final Set<String> unlockedThemes;
  final bool communityJoined;
  final DailyStreak daily;
  final Set<String> supportedNotes;
  final Set<String> reportedNotes;
  final String? nickname;
  final int avatar;
  final String? quoteUnlockedDay;
  final String? lastSupportSuggestionDay;

  /// Profil (takma ad) ve en az bir alan seçildiyse kayıt tamamdır.
  bool get isOnboarded => struggleIds.isNotEmpty && (nickname?.isNotEmpty ?? false);

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) {
    final unlocks = (m['unlocks'] as Map<String, dynamic>?) ?? const {};
    List<String> strings(String k) => List<String>.from(m[k] as List? ?? const []);
    return AppUser(
      uid: uid,
      struggleIds: strings('struggleIds'),
      categoryIds: strings('categoryIds'),
      notificationsEnabled: m['notificationsEnabled'] as bool? ?? true,
      analyticsEnabled: m['analyticsEnabled'] as bool? ?? true,
      themeId: m['themeId'] as String? ?? 'ocean',
      unlockedThemes: unlocks.keys.toSet(),
      communityJoined: m['communityJoined'] as bool? ?? false,
      daily: DailyStreak(
        current: (m['dailyStreak'] as num?)?.toInt() ?? 0,
        longest: (m['longestDailyStreak'] as num?)?.toInt() ?? 0,
        lastDay: m['lastActivityDay'] as String?,
      ),
      supportedNotes: strings('supportedNotes').toSet(),
      reportedNotes: strings('reportedNotes').toSet(),
      nickname: m['nickname'] as String?,
      avatar: (m['avatar'] as num?)?.toInt() ?? 0,
      anonymous: m['anonymous'] as bool? ?? true,
      adsOptIn: m['adsOptIn'] as bool?,
      language: m['language'] as String?,
      country: m['country'] as String?,
      quoteUnlockedDay: m['quoteUnlockedDay'] as String?,
      lastSupportSuggestionDay: m['lastSupportSuggestionDay'] as String?,
    );
  }
}
