# Haven — Yayın kontrol listesi

Son kontrol: 23 Kasım 2026 · sürüm 3.2.1 (4)

## 1. Kodda hazır olanlar (doğrulandı)

| Konu | Durum | Nasıl doğrulandı |
|---|---|---|
| Google ile giriş (Android), Apple ile giriş kodu (iOS) | Hazır | Emülatörde giriş; Firebase'de debug + yükleme anahtarı SHA-1/SHA-256 kayıtlı |
| Firestore veritabanı + güvenlik kuralları | Yayında (17 Kasım 2026); 23 Kasım sıkılaştırması (paylaşımda yalnızca uygulamanın alanları, ad ≤ 24 ve temiz, sunucu saati) henüz deploy edilmedi: `firebase deploy --only firestore:rules` | `rules_test/`: kayıt, günlük değerlendirme, notlar, paylaşım, destek, yanıt, arkadaşlık, engelleme, destek talebi, şikâyet, geliştirici işlemleri ve hesap silme; uygulamanın gönderdiği verinin aynısıyla emülatörde 12/12. Çalıştır: `firebase emulators:exec --only firestore --project demo-haven "npm --prefix rules_test test"` (Java gerekir) |
| Analytics (ekran + 20 özel olay) | Hazır | `analytics_service.dart`; DebugView ile izlenebilir |
| Bildirimler: cihazda zamanlanan günlük/kişisel hatırlatmalar, bildirim merkezi, FCM | Hazır | Hepsi uygulama kapalıyken de gelir ve ekranın üstünden kayar (yüksek öncelikli kanal; FCM için `default_notification_channel_id`). Profil → Hatırlatmalar kapatılınca zamanlanmış bildirimler anında iptal edilir. Sunucu push'u (Blaze) açılırsa aynı topluluk olayı telefonda iki kez görünmez (ortak `inbox` etiketi). `test/features_test.dart` |
| Gizlilik politikası + hesap silme sayfası | Yayında | https://ecren-7050e.web.app/gizlilik · https://ecren-7050e.web.app/hesap-silme |
| Topluluk: paylaşım, yanıt, destek, arkadaş, cesaret notu, anonim paylaşım | Hazır | Testler + emülatör |
| **Bildir / Engelle** (Play kullanıcı içeriği politikası) | Hazır | `test/moderation_actions_test.dart`, kurallar yayında |
| Destek ve öneriler + Geliştirici paneli + şikâyetleri kaldırma | Hazır | Emülatörde uçtan uca denendi |
| 5 dil (tr, en, es, zh, hi) | Hazır | `test/translation_test.dart` eksik çeviri bırakmaz |
| Reklam altyapısı (banner, ana sayfa kartı, ödüllü) | Test kimlikleriyle hazır | Gerçek kimlikler için bkz. 2.2 |
| İmzalı sürüm paketi (AAB) | Hazır | `flutter build appbundle --release` → 101,7 MB, CN=Haven yükleme anahtarıyla imzalı |
| 16 KB sayfa boyutu uyumu (Android 15+) | Uyumlu | Paketteki tüm 64-bit `.so` dosyaları ≥ 0x4000 hizalı |
| Hesap silme (uygulama içi + web sayfası) | Hazır | Profil → Hesabımı sil (önce kimlik yeniden doğrulanır; vazgeçilirse hiçbir şey silinmez); `site/hesap-silme.html` |

## 2. Senin yapman gerekenler (hesap / ödeme / kişisel bilgi)

### 2.1 Google Play Console — kritik yol
1. ~~Play Console geliştirici hesabı aç~~ ✓ açıldı.
2. Uygulama oluştur → **Dahili test** kanalına `build/app/outputs/bundle/release/app-release.aab` yükle. Dahili test incelemesiz ve hemen yayına girer; "mağazaya yüklendi" şartı için ilk kanıt budur.
3. **Kapalı test** başlat. 2023 sonrası açılan kişisel hesaplarda üretime geçmek için **en az 12 testçinin 14 gün kesintisiz** katılması gerekir. Hocanı da testçi listesine ekle.
4. İlk yüklemeden sonra Play Console → *Uygulama bütünlüğü → Uygulama imzalama* sayfasındaki **uygulama imzalama anahtarı SHA-1 ve SHA-256** değerlerini Firebase'e ekle. Bunu yapmazsan Play'den indirilen sürümde Google ile giriş çalışmaz. Değerleri Claude'a verirsen `firebase apps:android:sha:create` ile o ekler.

### 2.2 AdMob
1. AdMob hesabı aç → Haven uygulamasını ekle.
2. Üç reklam birimi oluştur: Banner (alt çubuk), Banner (ana sayfa kartı), Ödüllü.
3. Uygulama kimliğini (`ca-app-pub-…~…`) ve üç birim kimliğini Claude'a ver. `AndroidManifest.xml` ve `lib/core/constants/ad_ids.dart` güncellenir.
4. Engelleme kontrolleri: içerik derecelendirmesi en fazla **G**, hassas kategoriler kapalı (README → Reklam güvenliği).

### 2.3 Gizlilik politikası ve hesap silme sayfası ✓
Geliştirici: Ecren Solmazgül · solmazgulecren@gmail.com · yürürlük 17 Kasım 2026. Yayında:
- Gizlilik politikası: https://ecren-7050e.web.app/gizlilik
- Hesap silme: https://ecren-7050e.web.app/hesap-silme

Değiştirirsen: `firebase deploy --only hosting`.

### 2.4 Uygulama kapalıyken kullanıcıya bildirim göndermek
**Otomatik (cihazda, sunucusuz, ücretsiz):** Uygulama her açılışta telefona şunları kurar; uygulama kapalıyken ve internet yokken de gelir:
- Her gün 13.00: kişiye özel mesaj (takma adıyla selam, kendi serisi, seçtiği alanlara göre söz).
- Bugün kayıt yoksa 20.00'de tek bir nazik hatırlatma.
- Uygulamaya girmezse 1., 2., 3. ve 7. günde "seni düşünüyoruz" merdiveni. Kullanıcı geri döndükçe bunlar iptal edilip yeniden kurulur.

**Elle, istediğin an (Firebase Console, Blaze gerekmez):**
1. Firebase Console → *Messaging* → **Yeni kampanya** → *Bildirimler*.
2. Başlık ve metni yaz (nazik dil; sorunun adını yazma).
3. Hedef: uygulama `com.havenapp.haven`. Bir süredir girmeyenleri geri çekmek için koşul ekle: **Son uygulama etkileşimi** → ör. 3 günden önce. Dile göre ayrı kampanya: **Diller** → Türkçe / English / …
4. Zamanlama: *Şimdi* ya da *Yinelenen* (ör. her gün 13.00, kullanıcının saat diliminde).
5. Gönder. Bildirim uygulama kapalıyken de gelir ve ekranın üstünden kayarak görünür (kanal artık varsayılan; *Ek seçenekler → Android bildirim kanalı* boş bırakılabilir).

**Sunucudan otomatik push (Blaze gerekir):** Arkadaş ekleme, cesaret notu, yanıt gibi topluluk olaylarının uygulama kapalıyken push olarak gelmesi ve sunucu tarafı hatırlatmalar `functions/` içinde hazır. Blaze'e geçince (kart gerekir, bu kullanımda ücretsiz kotanın içinde kalır): `firebase deploy --only functions`.

### 2.5 İsteğe bağlı
- **Firebase Blaze planı:** bkz. 2.4, sunucudan otomatik push.
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

## 4. Mağaza sayfası malzemeleri ✓
Hepsi `store/` klasöründe (kopyası masaüstünde: *Haven Mağaza*); hangi dosyanın Play Console'da nereye gittiği `store/README.md`'de.
- Simge 512×512, öne çıkan grafik 1024×500 (Türkçe + İngilizce).
- 5 telefon ekran görüntüsü 1080×1920 (Türkçe + İngilizce): uygulamanın gerçek ekranları, örnek verilerle.
- Uygulama adı, kısa açıklama, tam açıklama (Türkçe + İngilizce), Play karakter sınırlarının içinde.
- Telefona doğrudan kurulabilen APK (gösterim ve deneme için): masaüstünde `Haven-3.2.0-3.apk` (3.2.1 (4) için yeniden derlenmeli). Play'den kapalı test sürümünü kurmadan önce bu APK'yı kaldır; imzaları farklı olduğu için üzerine kurulmaz.
