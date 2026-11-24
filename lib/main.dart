import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Tasarımların yazı tipleri (SIL OFL): Ayarlar → Lisanslar sayfasında görünür.
  LicenseRegistry.addLicense(_fontLicenses);

  // Reklam SDK'sı burada BAŞLATILMIYOR — bkz. AdService.
  runApp(const ProviderScope(child: HavenApp()));
}

Stream<LicenseEntry> _fontLicenses() async* {
  const fonts = {
    'Inter': 'inter',
    'Plus Jakarta Sans': 'plusjakartasans',
    'Outfit': 'outfit',
    'Nunito': 'nunito',
    'Lora': 'lora',
    'Atkinson Hyperlegible Next': 'atkinsonhyperlegiblenext',
  };
  for (final e in fonts.entries) {
    yield LicenseEntryWithLineBreaks([e.key], await rootBundle.loadString('assets/fonts/licenses/${e.value}.txt'));
  }
}
