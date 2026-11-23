import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'analytics_service.dart';
import 'haven_repository.dart';
import 'local_notifier.dart';

/// İstemci tarafı FCM: izin + cihaz kaydı.
///
/// Bildirimlerin NE ZAMAN ve HANGİ dille gideceğine sunucu karar verir
/// (functions/index.js). Uygulama sadece "bu cihaza ulaşılabilir" bilgisini
/// (`fcmFids`) ve "en son ne zaman buradaydım" bilgisini (`lastActiveAt`)
/// Firestore'a yazar.
///
/// FCM 17+ notu: Eski `getToken()` / `onTokenRefresh` kullanımdan kalktı.
/// Cihaz hedefi artık Firebase Installation ID (FID): `register()` çağrılır,
/// FID `onRegistered` akışından gelir. Sunucu da `token` yerine `fid` ile gönderir.
///
/// Ön plan davranışı: Android, uygulama açıkken gelen bildirimi sistem
/// çubuğunda GÖSTERMEZ. Otomatik nazik hatırlatmalar zaten yalnızca bir
/// süredir görünmeyen kullanıcılara gider, ama Firebase Console'dan gönderilen
/// bir kampanya (ör. ara kontroldeki canlı demo) uygulama açıkken gelebilir.
/// Bu yüzden ön plan mesajlarını `foregroundMessages` ile yayınlıyoruz;
/// SessionBootstrap bunları yumuşak bir uygulama içi not olarak gösteriyor.
/// flutter_local_notifications paketine gerek kalmıyor.
class NotificationService {
  NotificationService(this._repo, this._analytics);

  final HavenRepository _repo;
  final AnalyticsService _analytics;

  String? _uid;
  String? _fid;
  StreamSubscription<String>? _registeredSub;
  StreamSubscription<RemoteMessage>? _openSub;

  Future<void> start(String uid) async {
    if (_uid == uid) return;
    _uid = uid;
    final fcm = FirebaseMessaging.instance;
    try {
      // Android 13+ ve iOS'ta sistem izin penceresini açar (bir kez).
      final settings = await fcm.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      // Önce dinle, sonra kaydol: ilk olayı kaçırmamak için sıra önemli.
      // FID yenilenirse aynı akış yeni değeri tekrar yayınlar.
      await _registeredSub?.cancel();
      _registeredSub = fcm.onRegistered.listen((fid) {
        _fid = fid;
        _repo.addFcmFid(uid, fid);
        if (kDebugMode) debugPrint('FCM FID: $fid');
      });
      await fcm.register();

      _openSub ??= FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);
      final initial = await fcm.getInitialMessage();
      if (initial != null) _onOpened(initial);
    } catch (e) {
      // Offline'da kayıt başarısız olabilir; bir sonraki açılışta tekrar denenir.
      debugPrint('FCM başlatılamadı: $e');
      _uid = null;
    }
  }

  /// Uygulama açıkken gelen bildirimler.
  Stream<RemoteMessage> get foregroundMessages => FirebaseMessaging.onMessage;

  /// Push'a dokunuldu. Topluluk olayıysa (inboxPush) bildirim merkezi açılır;
  /// yerel bildirimlerle aynı yol (HavenApp._openFromNotification).
  void _onOpened(RemoteMessage message) {
    _analytics.nudgeOpened(message.data['level'] as String?);
    if (message.data['type'] == 'inbox') LocalNotifier.onTap?.call('inbox');
  }

  /// Çıkış / hesap silme öncesi: bu cihaz artık bu kullanıcının bildirimlerini
  /// almasın.
  Future<void> stop() async {
    final uid = _uid;
    final fid = _fid;
    _uid = null;
    _fid = null;
    await _registeredSub?.cancel();
    _registeredSub = null;
    try {
      if (uid != null && fid != null) {
        await _repo.removeFcmFid(uid, fid).timeout(const Duration(seconds: 5));
      }
      // FID kaydı silinemese bile unregister sonrası sunucu
      // "installation-id-not-registered" alır ve onu kendisi temizler.
      await FirebaseMessaging.instance.unregister().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('FCM kaydı temizlenemedi: $e');
    }
  }

  void dispose() {
    _registeredSub?.cancel();
    _openSub?.cancel();
  }
}
