import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/community.dart';

/// Telefonun üst çubuğunda görünen bildirimler — SUNUCU GEREKTİRMEZ.
///
/// 1) Şefkatli hatırlatmalar cihazda zamanlanır: uygulama her açıldığında
///    eskileri iptal edilip yenileri kurulur. Kullanıcı uygulamaya döndükçe
///    hiçbiri gelmez; uzaklaştıkça nazik bir merdivenle hal hatır sorulur.
///    İnternetsiz de çalışır. Dokununca uygulama açılır.
/// 2) Uygulama arka plandayken bildirim kutusuna düşen topluluk olayları
///    (arkadaş ekledi, cesaret notu, destek…) üst çubukta gösterilir.
///    Uygulama tamamen kapalıyken bunlar için sunucu push'u gerekir
///    (functions/index.js → inboxPush, Blaze planı).
class LocalNotifier {
  LocalNotifier._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// Bildirime dokunulunca (uygulama açıkken veya arka plandayken).
  static void Function(String? payload)? onTap;

  static const gentleChannel = AndroidNotificationChannel(
    'haven_gentle',
    'Hatırlatmalar',
    description: 'Bir süre görünmediğinde hal hatır soran şefkatli bildirimler.',
    importance: Importance.high,
  );
  static const socialChannel = AndroidNotificationChannel(
    'haven_social',
    'Topluluk',
    description: 'Arkadaş ekleme, cesaret notları ve destekler.',
    importance: Importance.high,
  );

  /// Şefkatli merdiven: yargı yok, baskı yok; her biri açık bir kapı.
  static const nudges = [
    'Bugün buralarda görünmüyorsun, umarım günün güzel geçiyordur.', // ~1. gün
    'Zor bir gün müydü? Bazen sadece dinlenmek gerekir, yarın yeniden deneyebiliriz.', // ~2. gün
    'Sadece nasıl olduğunu sormak istedik. Kendine iyi bakmayı unutma.', // ~3. gün
    'Gözlerimiz seni aradı. Ne zaman hazır hissedersen burada bekliyoruz.', // ~7. gün
  ];
  static const eveningReminder =
      'Bugünlük sayfamızı boş bıraktık ama yarın o alanı senin için saklıyoruz.';

  /// Her mesajın kendi sıcak başlığı (sorunu asla ifşa etmez).
  static const nudgeTitles = ['Merhaba 👋', 'Kendine bir mola ☁️', 'Seni düşünüyoruz 🤍', 'Kapımız hep açık'];
  static const eveningTitle = 'Yarın da buradayız ✨';

  static const _nudgeOffsets = [Duration(days: 1), Duration(days: 2), Duration(days: 3), Duration(days: 7)];
  static const _nudgeIds = [101, 102, 103, 104];
  static const _eveningId = 110;

  static Future<void> init() async {
    if (_ready || kIsWeb) return;
    try {
      tz_data.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_stat_haven'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) => onTap?.call(r.payload),
      );
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(gentleChannel);
      await android?.createNotificationChannel(socialChannel);
      _ready = true;
    } catch (e) {
      debugPrint('Yerel bildirimler başlatılamadı: $e');
    }
  }

  /// Uygulama bir bildirime dokunularak açıldıysa onun payload'ı.
  static Future<String?> launchPayload() async {
    if (!_ready) return null;
    final d = await _plugin.getNotificationAppLaunchDetails();
    return (d?.didNotificationLaunchApp ?? false) ? d!.notificationResponse?.payload : null;
  }

  /// Şık ve sakin bir bildirim görünümü: başlık + tam görünen uzun metin,
  /// altta küçük "Haven" etiketi, tema rengi, kilit ekranında içerik gizli.
  static NotificationDetails _details(
    AndroidNotificationChannel ch, {
    required String title,
    required String body,
    String subText = 'Haven',
    AndroidNotificationCategory category = AndroidNotificationCategory.reminder,
  }) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          ch.id,
          ch.name,
          channelDescription: ch.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_stat_haven',
          color: const Color(0xFF4A5C93),
          subText: subText,
          ticker: title,
          category: category,
          // Kilit ekranında içerik gizli: yanındaki kimse ne yazdığını görmesin.
          visibility: NotificationVisibility.private,
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: subText,
          ),
        ),
        iOS: DarwinNotificationDetails(subtitle: subText, threadIdentifier: ch.id),
      );

  /// Her açılışta ve her kayıttan sonra çağrılır.
  static Future<void> scheduleGentleNudges({required bool enabled, required bool checkedInToday}) async {
    if (!_ready) return;
    try {
      for (final id in [..._nudgeIds, _eveningId]) {
        await _plugin.cancel(id: id);
      }
      if (!enabled) return;
      final now = DateTime.now();
      for (var i = 0; i < _nudgeIds.length; i++) {
        await _schedule(_nudgeIds[i], withinWindow(now.add(_nudgeOffsets[i])), nudgeTitles[i], nudges[i], 'nudge_${i + 1}');
      }
      // Bugün henüz kayıt yoksa akşam tek bir küçük hatırlatma.
      if (!checkedInToday) {
        final evening = DateTime(now.year, now.month, now.day, 20);
        if (evening.isAfter(now.add(const Duration(minutes: 30)))) {
          await _schedule(_eveningId, evening, eveningTitle, eveningReminder, 'evening');
        }
      }
    } catch (e) {
      debugPrint('Hatırlatmalar zamanlanamadı: $e');
    }
  }

  /// Sessiz saatler: bildirimler yalnızca 10:00–20:59 arasında.
  @visibleForTesting
  static DateTime withinWindow(DateTime t) {
    if (t.hour < 10) return DateTime(t.year, t.month, t.day, 10, 30);
    if (t.hour >= 21) return DateTime(t.year, t.month, t.day + 1, 10, 30);
    return t;
  }

  static Future<void> _schedule(int id, DateTime when, String title, String body, String payload) =>
      _plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(when, tz.UTC),
        notificationDetails: _details(gentleChannel, title: title, body: body),
        // Tam zamanlama izni gerekmez; birkaç dakikalık sapma bu amaç için sorun değil.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: payload,
      );

  /// Topluluk olayını üst çubukta göster.
  static Future<void> showInbox(InboxItem item) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: item.id.hashCode & 0x7fffffff,
        title: item.title,
        body: item.body,
        notificationDetails: _details(socialChannel,
            title: item.title, body: item.body, subText: 'Haven · Topluluk',
            category: AndroidNotificationCategory.social),
        payload: 'inbox',
      );
    } catch (e) {
      debugPrint('Bildirim gösterilemedi: $e');
    }
  }
}
