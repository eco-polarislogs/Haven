import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sürüm (release) paketi R8 ile küçültülür. AGP 9'da R8, yalnızca yansımayla
/// oluşturulan sınıfların kurucularını da siler; koruma kuralları olmadan uygulama
/// telefonda AÇILIŞTA çöküyordu ("Failed to create an instance of
/// androidx.work.impl.WorkDatabase"). Hata ayıklama sürümünde görünmez.
void main() {
  test('R8 koruma kuralları sürüm derlemesine bağlı', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(RegExp(r'release\s*\{[\s\S]*?proguardFiles\("proguard-rules.pro"\)').hasMatch(gradle), isTrue);

    final rules = File('android/app/proguard-rules.pro').readAsStringSync();
    expect(rules, contains('-keep class * extends androidx.room.RoomDatabase { <init>(); }'));
    expect(rules, contains('androidx.work.impl.WorkDatabase_Impl'));
  });

  // Destek taleplerine eklenen sürüm (kAppVersion) mağazadaki sürümle aynı olmalı;
  // geliştirici panelinde hatanın hangi sürümde olduğu buna göre okunur.
  test('uygulama içi sürüm pubspec sürümüyle aynı', () {
    final pubspec = RegExp(r'^version:\s*([\d.]+)\+\d+', multiLine: true)
        .firstMatch(File('pubspec.yaml').readAsStringSync())!
        .group(1);
    final constants = File('lib/core/constants/app_constants.dart').readAsStringSync();
    expect(constants, contains("const kAppVersion = '$pubspec';"));
  });
}
