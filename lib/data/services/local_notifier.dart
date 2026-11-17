import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants/app_constants.dart';
import '../../core/constants/struggle_catalog.dart';
import '../../core/utils/day_key.dart';
import '../models/app_user.dart';
import '../../l10n/tx.dart';
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
  static const eveningReminder = 'Bugünlük sayfamızı boş bıraktık ama yarın o alanı senin için saklıyoruz.';

  /// Her mesajın kendi sıcak başlığı (sorunu asla ifşa etmez).
  static const nudgeTitles = ['Merhaba 👋', 'Kendine bir mola ☁️', 'Seni düşünüyoruz 🤍', 'Kapımız hep açık'];
  static const eveningTitle = 'Yarın da buradayız ✨';

  static const _nudgeOffsets = [Duration(days: 1), Duration(days: 2), Duration(days: 3), Duration(days: 7)];
  static const _nudgeIds = [101, 102, 103, 104];
  static const _eveningId = 110;

  /// Gün içi motivasyon (Duolingo tarzı): her gün 13:00'te kısa, her gün
  /// değişen bir mesaj. 7 gün ileriye zamanlanır; uygulama her açıldığında
  /// ve her kayıttan sonra yenilenir. Sorunun adı asla geçmez.
  static const dailyHour = 13;
  static const dailyTitles = [
    'Günün sözü ✨',
    'Küçük bir mola ☁️',
    'Bugün de buradayız 🤍',
    'Kendine bir dakika 🌤',
    'Bir nefeslik ara',
    'Selam 👋',
    'Yanındayız 🤍',
  ];
  static const checkInInvite =
      'Bugün nasıl geçiyor? Günü değerlendirmek birkaç saniye sürer; ne seçersen seç, burada yargı yok.';

  /// Kişiye özel davet: serisi olan kullanıcıya kendi yolunu hatırlatır.
  /// Baskı yok ("bozulur", "kaybedersin" gibi ifadeler asla kullanılmaz).
  static const checkInInviteStreak =
      'Bugün nasıl geçiyor? {n} günlük yolun burada; günü eklemek birkaç saniye sürer. Ne seçersen seç, yargı yok.';

  /// Takma adla kişisel selam (kilit ekranında içerik zaten gizli).
  static const greetingTitle = 'Selam {name} 👋';
  static const _dailyIds = [120, 121, 122, 123, 124, 125, 126];

  /// Saf plan (testli): hangi gün, hangi saatte, hangi mesaj.
  ///
  /// Kişiye göre: seçtiği alanların sözleri genel sözlerle gün aşırı
  /// dönüşümlü gelir (ör. uyku alanı seçen birine dinlenmeyle ilgili sözler);
  /// bugün kayıt yoksa davet, serisi varsa kendi gün sayısıyla, takma adı
  /// varsa adıyla selamlanır. Sorunun adı hiçbir mesajda geçmez.
  @visibleForTesting
  static List<({int slot, DateTime when, String title, String body, Map<String, Object?> args})> dailyPlan(
    DateTime now, {
    required bool checkedInToday,
    List<StruggleCategory> categories = const [],
    int streak = 0,
    String? nickname,
  }) {
    final dayIndex = now.difference(DateTime(now.year)).inDays;
    final own = [for (final c in categories) ...c.affirmationsTr];
    final name = nickname?.trim() ?? '';
    String quote(int i) => (own.isNotEmpty && i.isEven)
        ? own[(i ~/ 2) % own.length]
        : kGeneralAffirmations[(i ~/ (own.isEmpty ? 1 : 2)) % kGeneralAffirmations.length];
    return [
      for (var d = 0; d < _dailyIds.length; d++)
        if (DateTime(now.year, now.month, now.day + d, dailyHour).isAfter(now.add(const Duration(minutes: 30))))
          if (d == 0 && !checkedInToday)
            (
              slot: d,
              when: DateTime(now.year, now.month, now.day + d, dailyHour),
              title: name.isNotEmpty ? greetingTitle : dailyTitles[(dayIndex + d) % dailyTitles.length],
              body: streak > 0 ? checkInInviteStreak : checkInInvite,
              args: {'name': name, 'n': streak},
            )
          else
            (
              slot: d,
              when: DateTime(now.year, now.month, now.day + d, dailyHour),
              title: dailyTitles[(dayIndex + d) % dailyTitles.length],
              body: quote(dayIndex + d),
              args: const <String, Object?>{},
            ),
    ];
  }

  /// Kullanıcının kendi verisiyle (alanlar, seri, takma ad, bildirim tercihi)
  /// tüm telefon bildirimlerini yeniden kurar.
  static Future<void> scheduleFor(AppUser user, {bool? checkedInToday}) {
    final today = todayKey();
    return scheduleGentleNudges(
      enabled: user.notificationsEnabled,
      checkedInToday: checkedInToday ?? user.daily.lastDay == today,
      categories: user.categoryIds.map(categoryByName).nonNulls.toList(),
      streak: user.daily.live(today),
      nickname: user.nickname,
    );
  }

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
  }) => NotificationDetails(
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
      styleInformation: BigTextStyleInformation(body, contentTitle: title, summaryText: subText),
    ),
    iOS: DarwinNotificationDetails(subtitle: subText, threadIdentifier: ch.id),
  );

  /// Her açılışta ve her kayıttan sonra çağrılır.
  static Future<void> scheduleGentleNudges({
    required bool enabled,
    required bool checkedInToday,
    List<StruggleCategory> categories = const [],
    int streak = 0,
    String? nickname,
  }) async {
    if (!_ready) return;
    try {
      for (final id in [..._nudgeIds, _eveningId, ..._dailyIds]) {
        await _plugin.cancel(id: id);
      }
      if (!enabled) return;
      await _refreshChannels();
      final now = DateTime.now();
      final plan = dailyPlan(
        now,
        checkedInToday: checkedInToday,
        categories: categories,
        streak: streak,
        nickname: nickname,
      );
      for (final p in plan) {
        await _schedule(_dailyIds[p.slot], p.when, p.title, p.body, 'daily', p.args);
      }
      for (var i = 0; i < _nudgeIds.length; i++) {
        await _schedule(
          _nudgeIds[i],
          withinWindow(now.add(_nudgeOffsets[i])),
          nudgeTitles[i],
          nudges[i],
          'nudge_${i + 1}',
        );
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

  /// Metinler Türkçe kaynaktır; zamanlama anında kullanıcının diline çevrilir.
  /// (Uygulama dili değişince açılışta yeniden zamanlanır.)
  static Future<void> _schedule(
    int id,
    DateTime when,
    String titleTr,
    String bodyTr,
    String payload, [
    Map<String, Object?> args = const {},
  ]) {
    final title = tx(titleTr, args);
    final body = tx(bodyTr, args);
    return _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(when, tz.UTC),
      notificationDetails: _details(gentleChannel, title: title, body: body),
      // Tam zamanlama izni gerekmez; birkaç dakikalık sapma bu amaç için sorun değil.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Android ayarlarında görünen kanal adlarını etkin dile günceller.
  static Future<void> _refreshChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        gentleChannel.id,
        tx('Hatırlatmalar'),
        description: tx('Gün içinde kısa motivasyon mesajları ve bir süre görünmediğinde hal hatır soran bildirimler.'),
        importance: Importance.high,
      ),
    );
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        socialChannel.id,
        tx('Topluluk'),
        description: tx('Arkadaş ekleme, cesaret notları, destekler ve yanıtlar.'),
        importance: Importance.high,
      ),
    );
  }

  /// Topluluk olayını üst çubukta göster.
  static Future<void> showInbox(InboxItem item) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: item.id.hashCode & 0x7fffffff,
        title: item.title,
        body: item.body,
        notificationDetails: _details(
          socialChannel,
          title: item.title,
          body: item.body,
          subText: 'Haven · ${tx('Topluluk')}',
          category: AndroidNotificationCategory.social,
        ),
        payload: 'inbox',
      );
    } catch (e) {
      debugPrint('Bildirim gösterilemedi: $e');
    }
  }
}
