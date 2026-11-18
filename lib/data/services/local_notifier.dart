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

  /// Şefkatli merdiven: uygulamaya 1, 2, 3 ve 7 gün girilmezse. Yargı yok,
  /// baskı yok; her biri açık bir kapı. Her basamağın birkaç çeşidi var ve
  /// hangisinin geleceği bildirimin gününe göre seçilir ([variantFor]): aynı
  /// kişiye aynı cümle art arda gelmez. (başlık, metin)
  static const nudgeLadder = <List<(String, String)>>[
    // ~1. gün: şefkatli merak
    [
      ('Merhaba 👋', 'Bugün buralarda görünmüyorsun, umarım günün güzel geçiyordur.'),
      ('Selam 🌤', 'Bugün seni biraz özledik. Bir dakikan olursa uğra; olmazsa da sorun değil.'),
      ('Küçük bir merhaba', 'Günün nasıl geçiyor? İstersen birkaç saniyeliğine uğrayabilirsin.'),
      ('Buradayız ☁️', 'Yoğun bir gün olabilir. Ne zaman istersen kapımız açık.'),
    ],
    // ~2. gün: zor günleri olağan karşılamak
    [
      ('Kendine bir mola ☁️', 'Zor bir gün müydü? Bazen sadece dinlenmek gerekir, yarın yeniden deneyebiliriz.'),
      ('Yavaşlamak da olur', 'Bazı günler ağır gelir. Dinlenmek de yolun bir parçası; hazır olduğunda buradayız.'),
      ('Bir nefeslik ara', 'Her şeyi bugün yapmak zorunda değilsin. Kısa bir nefes bile iyi gelebilir.'),
      ('Seni düşündük', 'Dün biraz sessizdik. Nasıl hissediyorsan, o his de burada kabul görür.'),
    ],
    // ~3. gün: içten bir hal hatır
    [
      ('Seni düşünüyoruz 🤍', 'Sadece nasıl olduğunu sormak istedik. Kendine iyi bakmayı unutma.'),
      ('Nasılsın? 🤍', 'Birkaç gündür görüşemedik. Sadece iyi olduğunu bilmek istedik.'),
      ('Yanındayız 🤍', 'Bu birkaç gün nasıl geçti bilmiyoruz ama yalnız olmadığını bilmeni istiyoruz.'),
      ('Kendine iyi bak', 'Su içtin mi, biraz dinlenebildin mi? Küçük şeyler de önemli.'),
    ],
    // ~7. gün: açık kapı
    [
      ('Kapımız hep açık', 'Gözlerimiz seni aradı. Ne zaman hazır hissedersen burada bekliyoruz.'),
      ('Yerin hazır', 'Bir haftadır görüşemedik. Acele yok; döndüğünde kaldığın yerden, yargısız devam ederiz.'),
      ('Liman burada ⚓', 'Bazen uzaklaşmak gerekir. Geri gelmek istediğinde liman burada.'),
      ('Yeni bir sayfa ✨', 'Her gün yeniden başlamak için bir fırsat. Hazır olduğunda seni bekliyoruz.'),
    ],
  ];

  /// Merdivendeki tüm metinler ve başlıklar (denetim ve çeviri testleri için).
  static List<String> get nudges => [for (final step in nudgeLadder) for (final n in step) n.$2];
  static List<String> get nudgeTitles => [for (final step in nudgeLadder) for (final n in step) n.$1];

  /// Akşam 20:00, yalnızca o gün kayıt yoksa: tek, küçük bir hatırlatma.
  static const eveningReminders = <(String, String)>[
    ('Yarın da buradayız ✨', 'Bugünlük sayfamızı boş bıraktık ama yarın o alanı senin için saklıyoruz.'),
    ('Günü kapatırken 🌙', 'İstersen bugünü birkaç saniyede kaydedebilirsin. İstemezsen de yarın yeniden buradayız.'),
    ('İyi akşamlar 🌙', 'Bugün nasıl geçti? Ne seçersen seç, burada yargı yok.'),
    ('Akşam molası', 'Günün yorgunluğunu bırakmadan önce kendine bir dakika ayırmak ister misin?'),
    ('Bugünü düşünürken', 'Küçük bir adım da adımdır. Bugünü eklemek istersen Haven burada.'),
    ('Sakin bir akşam dileriz', 'Bugünkü kaydını yapmadıysan dert etme; yarın yeni bir gün.'),
  ];

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
    'Sana bir not 💌',
    'Öğle molası ☕',
    'Bugünün cümlesi',
    'Kısa bir hatırlatma 🌤',
    'Bir gülümseme kadar',
    'Yavaşça, kendi hızında',
    'Liman burada ⚓',
  ];

  /// Bugün henüz kayıt yoksa 13:00'teki davet.
  static const checkInInvites = [
    'Bugün nasıl geçiyor? Günü değerlendirmek birkaç saniye sürer; ne seçersen seç, burada yargı yok.',
    'Öğle arası küçük bir mola: bugün kendine nasıl davrandın? Birkaç saniyede kaydedebilirsin.',
    'Günün yarısı geride kaldı. Nasıl hissettiğini eklemek ister misin? Her cevap burada kabul görür.',
    'Kendine bir dakika ayır: bugün neler iyi gitti, neler zordu? Hepsi burada değerli.',
  ];

  /// Kişiye özel davet: serisi olan kullanıcıya kendi yolunu hatırlatır.
  /// Baskı yok ("bozulur", "kaybedersin" gibi ifadeler asla kullanılmaz).
  static const checkInInvitesStreak = [
    'Bugün nasıl geçiyor? {n} günlük yolun burada; günü eklemek birkaç saniye sürer. Ne seçersen seç, yargı yok.',
    '{n} gündür kendine zaman ayırıyorsun, bu çok değerli. Bugünü de eklemek ister misin?',
    '{n} günlük emeğin seninle. Bugün nasıl geçti? Birkaç saniyede kaydedebilirsin.',
    'Şimdiye kadar {n} gün; her biri senin emeğin. Bugünü de birlikte ekleyelim mi?',
  ];

  /// Takma adla kişisel selam (kilit ekranında içerik zaten gizli).
  static const greetingTitles = [
    'Selam {name} 👋',
    'Merhaba {name} 🌤',
    '{name}, nasılsın?',
    'İyi günler {name} ✨',
    '{name}, küçük bir mola?',
  ];
  static const _dailyIds = [120, 121, 122, 123, 124, 125, 126];

  /// O güne düşen çeşit: aynı gün hep aynısı (uygulama yeniden açılıp
  /// bildirimler yeniden kurulsa da), ertesi gün sıradaki.
  @visibleForTesting
  static T variantFor<T>(List<T> pool, DateTime day) =>
      pool[(DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay) %
          pool.length];

  /// Profil → "Deneme bildirimi gönder" (test sürecinde bildirimin uygulama
  /// kapalıyken de geldiğini görmek için).
  static const testTitle = 'Haven bildirimleri çalışıyor ✨';
  static const testBody = 'Bu bir deneme bildirimi. Hatırlatmaların ve topluluk bildirimlerin böyle gelecek.';
  static const _testId = 130;

  /// Birkaç saniye sonrasına tek bir deneme bildirimi kurar; uygulama kapatılsa
  /// da gelir. Bildirim izni yoksa ister; izin verilmezse `false`.
  static Future<bool> sendTest({Duration after = const Duration(seconds: 10)}) async {
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null && !(await android.areNotificationsEnabled() ?? true)) {
        if (!(await android.requestNotificationsPermission() ?? false)) return false;
      }
      await _refreshChannels();
      await _schedule(_testId, DateTime.now().add(after), testTitle, testBody, 'test');
      return true;
    } catch (e) {
      debugPrint('Deneme bildirimi kurulamadı: $e');
      return false;
    }
  }

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
              title: name.isNotEmpty ? variantFor(greetingTitles, now) : dailyTitles[(dayIndex + d) % dailyTitles.length],
              body: variantFor(streak > 0 ? checkInInvitesStreak : checkInInvites, now),
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
        final when = withinWindow(now.add(_nudgeOffsets[i]));
        final (title, body) = variantFor(nudgeLadder[i], when);
        await _schedule(_nudgeIds[i], when, title, body, 'nudge_${i + 1}');
      }
      // Bugün henüz kayıt yoksa akşam tek bir küçük hatırlatma.
      if (!checkedInToday) {
        final evening = DateTime(now.year, now.month, now.day, 20);
        if (evening.isAfter(now.add(const Duration(minutes: 30)))) {
          final (title, body) = variantFor(eveningReminders, evening);
          await _schedule(_eveningId, evening, title, body, 'evening');
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
