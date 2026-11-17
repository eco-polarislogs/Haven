import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/community.dart';
import '../../data/services/local_notifier.dart';
import '../../providers.dart';

/// Oturum açık ve kayıt tamamken çalışan "görünmez" katman:
/// - `lastActiveAt`'i açılışta ve uygulama her öne geldiğinde günceller,
/// - telefonda zamanlanan şefkatli hatırlatma merdivenini yeniden kurar
///   (kullanıcı döndükçe hiçbiri gelmez; uzaklaştıkça nazikçe hal hatır sorulur),
/// - FCM iznini ve cihaz kaydını başlatır,
/// - topluluk olaylarını (arkadaş ekledi, cesaret notu, destek…) telefonun
///   üst çubuğunda bildirim olarak gösterir.
class SessionBootstrap extends ConsumerStatefulWidget {
  const SessionBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SessionBootstrap> createState() => _SessionBootstrapState();
}

class _SessionBootstrapState extends ConsumerState<SessionBootstrap> with WidgetsBindingObserver {
  StreamSubscription<RemoteMessage>? _foregroundSub;
  Set<String>? _seenInbox;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foregroundSub = ref.read(notificationServiceProvider).foregroundMessages.listen(_showPush);
    ref.listenManual(inboxProvider, (_, next) => _onInbox(next.value));
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (!mounted) return;
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    ref.read(repositoryProvider).touchActive(uid, force: true);
    final user = ref.read(appUserProvider).value;
    unawaited(ref.read(analyticsProvider).setEnabled(user?.analyticsEnabled ?? true));
    unawaited(ref.read(notificationServiceProvider).start(uid));
    _rescheduleNudges();
  }

  /// Kullanıcı buradaysa merdiven baştan kurulur: ilk nazik mesaj ancak
  /// yarın, o da uygulamaya hiç girilmezse gelir.
  void _rescheduleNudges() {
    final user = ref.read(appUserProvider).value;
    if (user == null) return;
    // Kişiye göre: alanlarının sözleri, kendi serisi ve takma adı.
    unawaited(LocalNotifier.scheduleFor(user));
  }

  void _onInbox(List<InboxItem>? items) {
    if (items == null || !mounted) return;
    final ids = items.map((i) => i.id).toSet();
    final seen = _seenInbox;
    _seenInbox = ids;
    if (seen == null) return; // ilk yükleme: eski bildirimleri tekrar gösterme
    // Başka bir kullanıcıdan gelen yeni olaylar → telefonun üst çubuğu.
    for (final item in items.where((i) => !seen.contains(i.id) && !i.read && i.fromUid != null).take(3)) {
      unawaited(LocalNotifier.showInbox(item));
    }
  }

  void _showPush(RemoteMessage message) {
    final n = message.notification;
    if (n == null || !mounted) return;
    final text = [n.title, n.body].whereType<String>().join('\n');
    if (text.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 6)));
    ref.read(analyticsProvider).notificationShownInApp();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    ref.read(repositoryProvider).touchActive(uid);
    _rescheduleNudges();
  }

  @override
  void dispose() {
    _foregroundSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
