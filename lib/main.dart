import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/services/local_notifier.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Offline-first: Kriz anında internet olmasa bile uygulama açılır, son
  // veriler önbellekten gelir; check-in'ler kuyruğa alınıp bağlantı gelince
  // otomatik senkronize edilir.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Telefon üst çubuğu bildirimleri (cihazda zamanlanan şefkatli hatırlatmalar).
  await LocalNotifier.init();

  // Reklam SDK'sı burada BAŞLATILMIYOR — bkz. AdService.
  runApp(const ProviderScope(child: HavenApp()));
}
