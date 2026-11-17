# Haven — Yayın kontrol listesi

Son kontrol: 17 Kasım 2026 · sürüm 3.1.0 (2)

## 1. Kodda hazır olanlar (doğrulandı)

| Konu | Durum | Nasıl doğrulandı |
|---|---|---|
| Google ile giriş (Android), Apple ile giriş kodu (iOS) | Hazır | Emülatörde giriş; Firebase'de debug + yükleme anahtarı SHA-1/SHA-256 kayıtlı |
| Firestore veritabanı + güvenlik kuralları | Yayında | `firebase deploy --only firestore:rules` |
| Analytics (ekran + 20 özel olay) | Hazır | `analytics_service.dart`; DebugView ile izlenebilir |
| Bildirimler: cihazda zamanlanan günlük/kişisel hatırlatmalar, bildirim merkezi, FCM | Hazır | Emülatörde; Firebase Console → Messaging kampanyası Blaze gerektirmez |
| Topluluk: paylaşım, yanıt, destek, arkadaş, cesaret notu, anonim paylaşım | Hazır | Testler + emülatör |
| **Bildir / Engelle** (Play kullanıcı içeriği politikası) | Hazır | `test/moderation_actions_test.dart`, kurallar yayında |
| Destek ve öneriler + Geliştirici paneli + şikâyetleri kaldırma | Hazır | Emülatörde uçtan uca denendi |
| 5 dil (tr, en, es, zh, hi) | Hazır | `test/translation_test.dart` eksik çeviri bırakmaz |
| Reklam altyapısı (banner, ana sayfa kartı, ödüllü) | Test kimlikleriyle hazır | Gerçek kimlikler için bkz. 2.2 |
| İmzalı sürüm paketi (AAB) | Hazır | `flutter build appbundle --release` → 101,7 MB, CN=Haven yükleme anahtarıyla imzalı |
| 16 KB sayfa boyutu uyumu (Android 15+) | Uyumlu | Paketteki tüm 64-bit `.so` dosyaları ≥ 0x4000 hizalı |
| Hesap silme (uygulama içi + web sayfası) | Hazır | Profil → Hesabımı sil; `site/hesap-silme.html` |

## 2. Senin yapman gerekenler (hesap / ödeme / kişisel bilgi)

### 2.1 Google Play Console — kritik yol
1. Play Console geliştirici hesabı aç (tek seferlik 25 $).
2. Uygulama oluştur → **Dahili test** kanalına `build/app/outputs/bundle/release/app-release.aab` yükle. Dahili test incelemesiz ve hemen yayına girer; "mağazaya yüklendi" şartı için ilk kanıt budur.
3. **Kapalı test** başlat. 2023 sonrası açılan kişisel hesaplarda üretime geçmek için **en az 12 testçinin 14 gün kesintisiz** katılması gerekir. Hocanı da testçi listesine ekle.
4. İlk yüklemeden sonra Play Console → *Uygulama bütünlüğü → Uygulama imzalama* sayfasındaki **uygulama imzalama anahtarı SHA-1 ve SHA-256** değerlerini Firebase'e ekle. Bunu yapmazsan Play'den indirilen sürümde Google ile giriş çalışmaz. Değerleri Claude'a verirsen `firebase apps:android:sha:create` ile o ekler.

### 2.2 AdMob
1. AdMob hesabı aç → Haven uygulamasını ekle.
2. Üç reklam birimi oluştur: Banner (alt çubuk), Banner (ana sayfa kartı), Ödüllü.
3. Uygulama kimliğini (`ca-app-pub-…~…`) ve üç birim kimliğini Claude'a ver. `AndroidManifest.xml` ve `lib/core/constants/ad_ids.dart` güncellenir.
4. Engelleme kontrolleri: içerik derecelendirmesi en fazla **G**, hassas kategoriler kapalı (README → Reklam güvenliği).

### 2.3 Gizlilik politikası ve hesap silme sayfası
`site/gizlilik.html` ve `site/hesap-silme.html` içinde **[GELİŞTİRİCİ ADI]**, **[E-POSTA]**, **[TARİH]** boşlukları duruyor. Play, ulaşılabilir bir iletişim bilgisi ister. Herkese açık yayımlanacak ad ve e-postayı sen seç (kişisel e-posta yerine proje için ayrı bir adres önerilir), sonra `firebase deploy --only hosting`.

### 2.4 İsteğe bağlı
- **Firebase Blaze planı:** Uygulama tamamen kapalıyken topluluk bildirimlerinin push olarak gelmesi için (`inboxPush`). Blaze olmadan da bildirim merkezi, cihazdaki hatırlatmalar ve Console kampanyaları çalışır.
- **iOS / App Store:** Windows'ta iOS derlenemez; Apple Developer (99 $/yıl) + Mac gerekir. Gereksinim "Google **veya** Apple" ve "App Store **veya** Google Play" olduğu için Android yeterli.
- Firebase'de kullanılmayan "Gently" Android uygulamasını sil.
- Destek hattı numaralarını resmi kaynaklardan yeniden doğrula (ör. Çin 12356).
- Çevirileri anadili konuşan biri gözden geçirsin.

## 3. Play Console formları için hazır cevaplar

**Uygulama içeriği → Veri güvenliği**
| Veri türü | Toplanıyor | Paylaşılıyor | Amaç | Zorunlu mu |
|---|---|---|---|---|
| E-posta adresi (Google girişi) | Evet | Hayır | Hesap yönetimi | Evet |
| Ad (takma ad, kullanıcı seçer) | Evet | Hayır | Uygulama işlevi | Evet |
| Sağlık bilgisi (seçilen alanlar, günlük kayıtlar) | Evet | Hayır | Uygulama işlevi, kişiselleştirme | Evet |
| Diğer uygulama içi mesajlar (paylaşımlar, yanıtlar, destek talepleri) | Evet | Hayır | Uygulama işlevi | Hayır |
| Uygulama etkileşimleri (Analytics) | Evet | Hayır | Analiz | Hayır (Profil'den kapatılabilir) |
| Cihaz veya diğer kimlikler (FCM, reklam kimliği) | Evet | Evet (Google AdMob) | Reklam, bildirim | Evet |
- Veriler aktarım sırasında şifrelenir: **Evet** (Firebase TLS).
- Kullanıcı verilerinin silinmesini isteyebilir: **Evet** (uygulama içi + `https://ecren-7050e.web.app/hesap-silme`).

**Diğer beyanlar**
- Reklam içerir: **Evet**. Reklam kimliği kullanımı: **Evet**, reklam amaçlı.
- Hedef kitle: **18+** önerilir (ruh sağlığı içeriği; Aile politikasının dışında kalır).
- İçerik derecelendirmesi anketi: kullanıcılar arası etkileşim **var**, kullanıcı içeriği **var** (denetimli, bildir/engelle mevcut), konum paylaşımı **yok**.
- Sağlık uygulamaları beyanı: ruh sağlığı ve iyi oluş desteği, alışkanlık takibi; **tıbbi cihaz değildir**, teşhis koymaz (uygulama içinde de yazıyor).
- Uygulama erişimi: giriş Google hesabıyla yapılır; inceleme için bir test Google hesabı bilgisi vermen istenebilir.

## 4. Mağaza sayfası malzemeleri
- Uygulama simgesi 512×512, öne çıkan görsel 1024×500, en az 2 telefon ekran görüntüsü.
- Kısa açıklama (80 karakter) ve tam açıklama (4000 karakter), tercihen 5 dilde.
