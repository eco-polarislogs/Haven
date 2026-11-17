import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/struggle_catalog.dart';
import '../../core/utils/streak.dart';

/// Firebase Analytics olayları.
///
/// GİZLİLİK KURALI: Buraya asla serbest metin (not içeriği), isim, e-posta veya
/// spesifik tanı (ör. "anorexia") gönderme. Yalnızca kaba kategori + sayılar.
/// AndroidManifest'te reklam kişiselleştirme sinyalleri kapalıdır.
///
/// "Hangi günlerde daha çok zorlanılıyor?" → Console → Custom definitions'a
/// `weekday`, `result`, `category` ekle ve `checkin` olayını kırılımla incele.
class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  Future<void> setEnabled(bool enabled) => _analytics.setAnalyticsCollectionEnabled(enabled);

  Future<void> onboardingCompleted({
    required int struggleCount,
    required int categoryCount,
    required bool community,
  }) =>
      _log('onboarding_completed', {
        'struggle_count': struggleCount,
        'category_count': categoryCount,
        'community': community ? 1 : 0,
      });

  Future<void> checkIn(StruggleCategory category, CheckInResult result, {int? gapDays, int? dailyStreak}) {
    final now = DateTime.now();
    return _log('checkin', {
      'category': category.name,
      'result': result.name,
      'weekday': now.weekday, // 1 = Pazartesi … 7 = Pazar
      'hour': now.hour,
      'gap_days': ?gapDays, // > 1 ise arada kayıt yapılmayan gün(ler) var
      'daily_streak': ?dailyStreak,
    });
  }

  Future<void> supportOpened(String source) => _log('support_opened', {'source': source});
  Future<void> professionalSupportOpened() => _log('professional_support_opened', {});
  Future<void> breathingFinished(int cycles) => _log('breathing_finished', {'cycles': cycles});
  Future<void> gameFinished(String game, int score) =>
      _log('game_finished', {'game': game, 'score': score});
  Future<void> rewardEarned(String reward) => _log('reward_earned', {'reward': reward});
  Future<void> nudgeOpened(String? level) => _log('nudge_opened', {'level': level ?? 'unknown'});
  Future<void> notificationShownInApp() => _log('notification_in_app', {});
  Future<void> notificationCenterOpened(int unread) =>
      _log('notification_center_opened', {'unread': unread});

  // Topluluk (içerik ASLA gönderilmez)
  Future<void> communityJoined(bool joined) => _log('community_joined', {'joined': joined ? 1 : 0});
  Future<void> notePosted(StruggleCategory circle) => _log('note_posted', {'circle': circle.name});
  Future<void> noteBlocked(String verdict) => _log('note_blocked', {'verdict': verdict});
  Future<void> noteSupported() => _log('note_supported', {});
  Future<void> replyPosted() => _log('reply_posted', {});
  Future<void> noteReported() => _log('note_reported', {});
  Future<void> friendAdded() => _log('friend_added', {});
  Future<void> kudosSent() => _log('kudos_sent', {});

  /// Flutter tek bir Android Activity'de çalışır; bu çağrı olmadan Analytics
  /// tüm oturumu "MainActivity" olarak görür. Bkz. core/navigation.dart
  Future<void> screen(String name) async {
    try {
      await _analytics.logScreenView(screenName: name, screenClass: name);
    } catch (e) {
      debugPrint('Analytics hatası: $e');
    }
  }

  Future<void> _log(String name, Map<String, Object> parameters) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics hatası: $e');
    }
  }
}
