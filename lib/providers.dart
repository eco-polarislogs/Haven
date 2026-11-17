import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/country_support.dart';
import 'core/constants/struggle_catalog.dart';
import 'core/theme/theme_presets.dart';
import 'data/models/app_user.dart';
import 'data/models/community.dart';
import 'data/models/journal_entry.dart';
import 'data/models/month_log.dart';
import 'data/models/struggle.dart';
import 'data/models/support_ticket.dart';
import 'data/services/analytics_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/community_repository.dart';
import 'data/services/haven_repository.dart';
import 'data/services/notification_service.dart';
import 'data/services/support_repository.dart';

// Neden Riverpod (kod üretimi olmadan)? Auth durumu ve Firestore akışları
// doğrudan StreamProvider'a oturuyor; AsyncValue.when ile yükleniyor/hata/veri
// durumları tek satırda; servislere BuildContext gerekmiyor.

// ------------------------------------------------------------ servisler
final authServiceProvider = Provider<AuthService>((ref) => AuthService(FirebaseAuth.instance));

final repositoryProvider = Provider<HavenRepository>((ref) => HavenRepository(FirebaseFirestore.instance));

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => CommunityRepository(FirebaseFirestore.instance),
);

final analyticsProvider = Provider<AnalyticsService>((ref) => AnalyticsService(FirebaseAnalytics.instance));

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(ref.watch(repositoryProvider), ref.watch(analyticsProvider));
  ref.onDispose(service.dispose);
  return service;
});

// ------------------------------------------------------------ oturum
final authStateProvider = StreamProvider<User?>((ref) => ref.watch(authServiceProvider).authStateChanges());

final uidProvider = Provider<String?>((ref) => ref.watch(authStateProvider).value?.uid);

// ------------------------------------------------------------ kişisel veri
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(repositoryProvider).watchUser(uid);
});

final strugglesProvider = StreamProvider<List<Struggle>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(const <Struggle>[]);
  return ref.watch(repositoryProvider).watchStruggles(uid);
});

/// Takvim: bir ay = tek doküman = tek okuma. Parametre: `2026-11`
final monthLogProvider = StreamProvider.family<MonthLog, String>((ref, monthKey) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(MonthLog.empty);
  return ref.watch(repositoryProvider).watchMonth(uid, monthKey);
});

/// Tüm alanlardaki ve günlük serideki en iyi seri: hediye tema/avatarları açar.
final bestStreakProvider = Provider<int>((ref) {
  final user = ref.watch(appUserProvider).value;
  final struggles = ref.watch(strugglesProvider).value ?? const <Struggle>[];
  return user?.bestStreak(struggles.map((s) => s.streak.longest)) ?? 0;
});

/// Hediye (tema/avatar) açık mı? Seriyle ya da ödüllü reklamla açılır.
bool isGiftUnlocked({required int unlockStreak, required String id, required int best, AppUser? user}) =>
    unlockStreak == 0 || best >= unlockStreak || (user?.unlockedThemes.contains(id) ?? false);

/// Seçili tema; kilitli bir hediye temaysa varsayılana döner.
final themePresetProvider = Provider<ThemePreset>((ref) {
  final user = ref.watch(appUserProvider).value;
  final preset = ThemePreset.parse(user?.themeId);
  final unlocked = isGiftUnlocked(
    unlockStreak: preset.unlockStreak,
    id: preset.name,
    best: ref.watch(bestStreakProvider),
    user: user,
  );
  return unlocked ? preset : ThemePreset.ocean;
});

/// Giriş yapmadan önce karşılama ekranında seçilen dil (hesap açılınca kaydedilir).
final languageOverrideProvider = NotifierProvider<LanguageOverride, String?>(LanguageOverride.new);

class LanguageOverride extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? code) => state = code;
}

/// Uygulama dili: kullanıcının seçimi → karşılama ekranındaki seçim →
/// telefonun dili (destekleniyorsa) → İngilizce. Tüm içerik 5 dilde.
final localeProvider = Provider<Locale>((ref) {
  final code = ref.watch(appUserProvider).value?.language ?? ref.watch(languageOverrideProvider) ?? deviceLanguage();
  return Locale(kLanguageCodes.contains(code) ? code : 'en');
});

const kLanguageCodes = {'tr', 'en', 'es', 'zh', 'hi'};

/// Destek hatları için ülke: kullanıcının seçimi → telefonun bölgesi → dilden tahmin.
final countryProvider = Provider<CountrySupport>((ref) {
  final chosen = ref.watch(appUserProvider).value?.country;
  return countrySupportFor(
    chosen ?? guessCountry(PlatformDispatcher.instance.locale.countryCode, ref.watch(localeProvider).languageCode),
  );
});

/// Telefonun dili Haven'ın desteklediği dillerdense o, değilse İngilizce.
String deviceLanguage() {
  final c = PlatformDispatcher.instance.locale.languageCode;
  return kLanguageCodes.contains(c) ? c : 'en';
}

/// Kendine yazdığın özel notlar (günlük). Kimseyle paylaşılmaz.
final journalProvider = StreamProvider<List<JournalEntry>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(repositoryProvider).watchJournal(uid);
});

// ------------------------------------------------------------ topluluk
final myProfileProvider = StreamProvider<PublicProfile?>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(communityRepositoryProvider).watchProfile(uid);
});

/// Kullanıcının çemberleri = seçtiği kategoriler (topluluğa katıldıysa).
final feedProvider = StreamProvider<List<CommunityNote>>((ref) {
  final user = ref.watch(appUserProvider).value;
  if (user == null || !user.communityJoined) return Stream.value(const []);
  return ref.watch(communityRepositoryProvider).watchFeed(user.categoryIds);
});

/// "Arkadaşlar" akışı: arkadaşların + kendi paylaşımların.
final friendsFeedProvider = StreamProvider<List<CommunityNote>>((ref) {
  final uid = ref.watch(uidProvider);
  final ids = ref.watch(friendIdsProvider).value ?? const <String>[];
  if (uid == null) return Stream.value(const []);
  return ref.watch(communityRepositoryProvider).watchAuthorsFeed([uid, ...ids]);
});

/// Bir kullanıcının profil sayfasındaki paylaşımları.
final userNotesProvider = StreamProvider.family<List<CommunityNote>, String>(
  (ref, uid) => ref.watch(communityRepositoryProvider).watchAuthorsFeed([uid]),
);

final profileProvider = StreamProvider.family<PublicProfile?, String>(
  (ref, uid) => ref.watch(communityRepositoryProvider).watchProfile(uid),
);

final repliesProvider = StreamProvider.family<List<NoteReply>, String>(
  (ref, noteId) => ref.watch(communityRepositoryProvider).watchReplies(noteId),
);

/// Kendi anonim gönderilerimin kimlikleri (silme menüsü için; yalnızca bende).
final myAnonNoteIdsProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(const {});
  return ref.watch(communityRepositoryProvider).watchMyAnonNoteIds(uid);
});

/// Okuyanın alanları: başkalarının paylaşımlarında bu alanlar için
/// tetikleyici olabilecek ifadeler gizlenir (ContentModerator.maskFor).
final readerCategoriesProvider = Provider<List<StruggleCategory>>(
  (ref) => (ref.watch(appUserProvider).value?.categoryIds ?? const <String>[])
      .map(categoryByName)
      .whereType<StruggleCategory>()
      .toList(),
);

final friendIdsProvider = StreamProvider<List<String>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(communityRepositoryProvider).watchFriendIds(uid);
});

final friendProfilesProvider = StreamProvider<List<PublicProfile>>((ref) {
  final ids = ref.watch(friendIdsProvider).value ?? const <String>[];
  return ref.watch(communityRepositoryProvider).watchProfiles(ids);
});

// ------------------------------------------------------------ bildirim merkezi
final inboxProvider = StreamProvider<List<InboxItem>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(communityRepositoryProvider).watchInbox(uid);
});

final unreadCountProvider = Provider<int>(
  (ref) => (ref.watch(inboxProvider).value ?? const []).where((i) => !i.read).length,
);

// ------------------------------------------------------------ destek ve öneriler
final supportRepositoryProvider = Provider<SupportRepository>((ref) => SupportRepository(FirebaseFirestore.instance));

/// Bu hesap geliştirici mi? (Geliştirici paneli yalnızca ona görünür.)
final isDeveloperProvider = Provider<bool>(
  (ref) => ref.watch(supportRepositoryProvider).isDeveloper(ref.watch(uidProvider)),
);

final myTicketsProvider = StreamProvider<List<SupportTicket>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(supportRepositoryProvider).watchMine(uid);
});

final allTicketsProvider = StreamProvider<List<SupportTicket>>((ref) {
  if (!ref.watch(isDeveloperProvider)) return Stream.value(const []);
  return ref.watch(supportRepositoryProvider).watchAll();
});

/// Geliştirici panelindeki okunmamış (yeni) talep sayısı.
final openTicketCountProvider = Provider<int>(
  (ref) => (ref.watch(allTicketsProvider).value ?? const []).where((t) => t.status == TicketStatus.open).length,
);

// ------------------------------------------------------------ gezinme
class ShellIndex extends Notifier<int> {
  @override
  int build() => 0;
  void select(int index) => state = index;
}

final shellIndexProvider = NotifierProvider<ShellIndex, int>(ShellIndex.new);
