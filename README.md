# Haven

*Haven: İngilizcede "güvenli liman, sığınak".* Kaygı, depresif duygu durum, OKB, bedene yönelik tekrarlayan davranışlar, yeme ve beden algısı, davranışsal ve madde bağımlılıkları, öfke, travma, uyku ve kendine zarar verme gibi zorluklarla mücadele edenler için yargısız, şefkat odaklı iyileşme yol arkadaşı ve güvenli topluluk.

**Öne çıkanlar:** 11 kategori / 28 alan (DSM-5-TR & ICD-11 grupları, WHO/NIMH verileri) · sade ana sayfa (seri, rekor, günün sözü, ilerleme, notlar) · I Am Sober tarzı seri geçmişi ve "kendi rekorunla yarış" · X (Twitter) düzeninde denetimli topluluk: gönderi, yanıt, destek, profil, arkadaş akışı · uygulama içi bildirim merkezi + şık üst çubuk bildirimleri · Sakinleş: nefes, 5-4-3-2-1, 3 oyun, acil arama · 8 renk teması · 30 hayvan avatarı (her birinin değiştirilebilir varsayılan adı var) · 5 dil · kriz anında otomatik destek yönlendirmesi.

**Kaynak kod:** <https://github.com/eco-polarislogs/Haven>

**Flutter 3.47 · Riverpod 3 · Firebase (Auth, Firestore, Cloud Functions, FCM, Analytics) · AdMob ödüllü reklam**

- 14 günlük plan: [docs/SPRINT_PLAN.md](docs/SPRINT_PLAN.md)
- Veritabanı şeması: [docs/FIRESTORE_SCHEMA.md](docs/FIRESTORE_SCHEMA.md)

## Ödev gereksinimleri → kod karşılığı

| Gereksinim | Karşılığı | Kod | Ara kontrolde nasıl gösterilir |
|---|---|---|---|
| **Giriş: Google veya Apple** | Haven'ın kendi kayıt ekranları (karşılama → takma ad/avatar → alanlar → topluluk → rıza); Google yalnızca tek dokunuşla kimliği doğrular. iOS'ta Apple ile giriş | `data/services/auth_service.dart`, `features/auth/`, `features/onboarding/` | Uygulamayı aç → "Google ile kayıt ol / giriş yap" |
| **Mağaza yayını: teslimden ≥2 hafta önce** | Release imzalama + AAB; Play kapalı test → production | `android/app/build.gradle.kts`, `docs/SPRINT_PLAN.md` | Play Console'da kapalı test sürümü + tester linki |
| **Ara kontrol (12. hafta)** | Gün 7 demo sürümü | — | Giriş → alan seçimi → check-in → "zordu" → nefes → bildirim → reklam |
| **Veritabanı / API** | Cloud Firestore (offline destekli, sunucu güvenlik kurallı) + Cloud Functions | `data/services/haven_repository.dart`, `data/services/community_repository.dart`, `firestore.rules`, `functions/index.js` | Check-in yap / not paylaş → Firebase Console'da canlı güncellenir |
| **İstatistik (Analytics)** | Firebase Analytics: ekran görüntülemeleri + 20 özel olay (`checkin`, `note_posted`, `game_finished`, `friend_added` …; içerik asla gönderilmez) | `data/services/analytics_service.dart`, `core/navigation.dart` | `adb shell setprop debug.firebase.analytics.app com.havenapp.haven` → Console → **DebugView** |
| **Anlık bildirim** | Her gün 13.00'te değişen kısa motivasyon bildirimi (o gün kayıt yoksa günü değerlendirmeye davet) + "bir süre görünmedin" hatırlatmaları + akşam 20.00 hatırlatması (cihazda zamanlanır). FCM + **uygulama içi bildirim merkezi** (zil): arkadaş ekleme, cesaret notu, destek, yanıt, seri. Cloud Functions: bildirim kutusu → push | `features/notifications/`, `data/services/notification_service.dart`, `functions/` | Zile dokun; arkadaşından cesaret notu gönder; Console → Messaging kampanyası |
| **Reklam (+20)** | Google **AdMob**: alt çubuğun üstünde ince **banner** (320×50) + kilitli **tema düğmelerinde ödüllü reklam** ("Kısa bir reklam izle ve şimdi aç") + Hediyelerim'de ödüllü reklam. Sakinleş (kriz) sekmesinde reklam yok | `features/ads/`, `features/rewards/gifts_screen.dart`, `data/services/ad_service.dart` | Profil → "Filtreli reklamlar" açık → alt çubukta banner; Temalar → kilitli tema → reklam izle |
| **(Ek) Sosyal özellikler** | X tarzı topluluk: "Senin için" (çember akışı, konu filtreleri), "Arkadaşlar" akışı, "Kişiler"; gönderi kartı (avatar, takma ad, seri, zaman), yanıt dizisi, destek, bildir, kişi profili, arkadaş ekle, hazır cesaret notları. **Her gönderide "İsmimle / Anonim" seçimi**; gönderide alan (hastalık grubu) belirtilir. Gönderi ve yanıtlar hem cihazda hem sunucuda denetlenir; ayrıca okuyanın kendi alanları için tetikleyici olabilecek ifadeler okurken "•••" ile gizlenir | `features/community/`, `core/moderation/content_moderator.dart`, `firestore.rules` | Topluluk → "+" ile paylaş → gönderiye dokun → yanıt yaz → avatara dokun → Arkadaş ekle |
| **Bireysel X Ortak** | A (arayüz) / B (altyapı) rol ayrımı | `docs/SPRINT_PLAN.md` | — |

> **Reklam notu (rapora yaz):** Google AdSense web siteleri içindir; mobil uygulamalar için Google'ın karşılığı **AdMob**'dur (aynı Google reklam ağı, `google_mobile_ads` paketi). Gereksinimdeki "AdSense" ifadesi mobilde AdMob ile karşılanır. Hocana bunu önceden teyit ettirmen puan kaybı riskini sıfırlar.

> **Hocayı tester olarak ekle:** Uygulama kapalı testteyken Play Store'da herkese görünmez. Hocanın uygulamayı Play'den kurabilmesi için Gmail adresini kapalı test listesine (Google Grubu'na) eklemelisin.

## Klasör yapısı

```
lib/
├── main.dart                     Firebase + offline önbellek + yerel bildirimler + ProviderScope
├── app.dart                      MaterialApp + AuthGate (durumdan türetilen yönlendirme)
├── providers.dart                Tüm Riverpod sağlayıcıları
├── l10n/                         5 dil (tr, en, es, zh, hi) ARB dosyaları
├── core/
│   ├── constants/
│   │   ├── struggle_catalog.dart 11 kategori / 28 alan, kategoriye özel metinler ve tetikleyici kelimeler
│   │   └── app_constants.dart    Destek hatları, 30 avatar + varsayılan adlar, cesaret notları
│   ├── moderation/               Türkçe duyarlı içerik denetimi (kriz, kişisel bilgi, küfür, tetikleyici)
│   ├── quotes/quote_engine.dart  Saate, güne, mevsime ve seriye göre değişen günün sözü
│   ├── theme/                    8 tema (kırmızı, turuncu, yeşil, mavi, okyanus, pembe + 2 hediye)
│   ├── utils/streak.dart         Seri, geçmiş seriler, rekor yarışı (saf fonksiyonlar, testli)
│   └── widgets/                  HavenLogo (kalkan), avatar ve seri rozetleri
├── data/
│   ├── models/                   AppUser, Struggle, MonthLog, JournalEntry, Community (gönderi, yanıt, bildirim)
│   └── services/                 Auth, Firestore depoları, FCM, yerel bildirimler, Analytics, AdMob
└── features/
    ├── auth/ onboarding/         Kendi kayıt ekranlarımız (anonimlik, avatar, alanlar, rıza)
    ├── home/                     Sade ana sayfa: seri, rekor, günün sözü, ilerleme, notlar
    ├── community/                X tarzı akış, gönderi kartı, yanıtlar, kişi profili, arkadaşlar
    ├── safe_space/ relax/        Sakinleş: nefes, 5-4-3-2-1, oyunlar, acil arama
    ├── support/                  Zor gün paneli, kriz paneli, profesyonel destek rehberi
    ├── notifications/            Bildirim merkezi (zil)
    ├── rewards/                  Hediyeler: tema ve avatarlar (seri ya da isteğe bağlı reklam)
    └── profile/ journal/         Profil, tema, dil, avatar ve takma ad; notlarım
functions/                        inboxPush (bildirim → push), şefkatli hatırlatmalar, testler
firestore.rules                   Kendi verine erişim; topluluk yazmaları sıkı kurallı
site/                             Gizlilik politikası + hesap silme sayfası (Firebase Hosting)
```

## Görünüm

- **Simge:** yumuşak köşeli bir kalkan, içinde ışığı yanan bir kapı ("güvenli liman": korunaklı, sıcak, her zaman açık). Deniz teması yok; bildirim simgesi de aynı kalkan.
- **Temalar (Profil → Tema):** Okyanus, Mavi, Yeşil, Turuncu, Kırmızı, Pembe tonları ücretsiz; Mor tonları (3 gün) ve Gece karanlığı (7 gün) hediye.
- **Avatarlar:** 18 ücretsiz + 12 hediye hayvan/simge. Her avatarın varsayılan bir adı var ("Sevimli Kurbağa", "Bilge Baykuş"…); kullanıcı istediği zaman değiştirebilir.

## Kurulum (sırayla)

### 1. Konum

Proje `C:\dev\haven` klasöründe. OneDrive veya Türkçe karakter (ö, ş…) içeren yollara taşıma: `flutter analyze` çöker ve Android derlemesi ASCII olmayan yolları reddeder.

### 2. Araçlar

```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

### 3. Firebase projesi

1. [console.firebase.google.com](https://console.firebase.google.com) → Proje oluştur (Google Analytics: **açık**).
2. Firestore Database → Oluştur → konum **europe-west3**, production modu. *(Bu projede (`ecren-7050e`) veritabanı otomatik olarak **nam5 (ABD)** konumunda oluştu; gizlilik metni buna göre yazıldı.)*
3. Authentication → Sign-in method → **Google**'ı etkinleştir.
4. SHA parmak izlerini ekle (Proje ayarları → Android uygulaması):
   ```powershell
   cd android; .\gradlew signingReport; cd ..
   ```
   Çıktıdaki `SHA1` ve `SHA-256` değerlerini ekle. **Play'e yükledikten sonra** Play Console → Test ve yayın → Uygulama bütünlüğü → *App signing key* SHA'larını da ekle. Yoksa Google girişi mağaza sürümünde çalışmaz (en sık yapılan hata).
5. Proje kökünde:
   ```powershell
   flutterfire configure --platforms=android
   ```
   `lib/firebase_options.dart` ve `android/app/google-services.json` oluşur. SHA ekledikten sonra bu komutu **tekrar** çalıştır.
6. Kuralları ve gizlilik sayfalarını yükle: `firebase use --add` (projeni seç) → `firebase deploy --only firestore:rules,hosting`
7. `site/gizlilik.html` ve `site/hesap-silme.html` içindeki `[GELİŞTİRİCİ ADI]`, `[E-POSTA]`, `[TARİH]` alanlarını doldurup tekrar deploy et. Linkler: `https://<proje-id>.web.app/gizlilik` ve `/hesap-silme`. İlkini `lib/core/constants/app_constants.dart`'a, ikisini de Play Console'a yaz.

### 4. Çalıştır

```powershell
flutter run
flutter test
```

### 5. Cloud Functions (şefkatli bildirimler)

Blaze planı gerekir (Cloud Scheduler). Bu ölçekte ücretsiz kotada kalır; Google Cloud Console → Faturalandırma → Bütçeler → **1 $ uyarısı** kur.

```powershell
cd functions
npm install
npm test
cd ..
firebase deploy --only functions
```

**Canlı demo (24 saat beklemeden):** Firestore Console'da kendi `users/{uid}` dokümanında `lastActiveAt`'i 2 gün öncesine çek. Ardından [Cloud Scheduler](https://console.cloud.google.com/cloudscheduler) → `firebase-schedule-gentleNudges-...` → **Force run**. Bildirim birkaç saniyede gelir; yerel saat 10:00-21:00 dışındaysa pencere gereği gönderilmez.

### 6. AdMob (Gün 8)

1. AdMob → Uygulamalar → Ekle (Android) → **App ID**'yi `android/app/src/main/AndroidManifest.xml`'deki test kimliğinin yerine yaz.
2. Reklam birimi → **Ödüllü** → kimliği `lib/core/constants/ad_ids.dart`'a yaz.
3. Privacy & messaging → GDPR mesajı oluştur (AB kullanıcıları için zorunlu).
4. Geliştirmede her zaman test reklamı görürsün; gerçek kimlikler sadece release derlemede devreye girer.
5. **AdMob onayına kadar `ad_ids.dart`'taki yer tutucuları DEĞİŞTİRME.** Yeni AdMob uygulamaları, mağaza sayfasına bağlanıp incelenene kadar gerçek reklamı sınırlı ya da hiç göstermez ("No fill"). Yer tutucular duruyorsa kod release derlemede de otomatik olarak test reklamı kullanır; böylece kapalı testte hoca reklamı kesin görür. AdMob uygulamayı onayladıktan sonra gerçek kimlikleri yaz.

### 7. Release imzalama

```powershell
keytool -genkey -v -keystore C:\dev\keys\haven-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`android/key.properties` oluştur (git'e eklenmez):

```properties
storePassword=<şifre>
keyPassword=<şifre>
keyAlias=upload
storeFile=C:/dev/keys/haven-upload.jks
```

```powershell
flutter build appbundle --release
```

Çıktı: `build/app/outputs/bundle/release/app-release.aab`. Keystore'u ve şifreyi **yedekle**; kaybedersen güncelleme yükleyemezsin.

## Telefon bildirimleri (üst çubuk)

- **Şefkatli hatırlatmalar cihazda zamanlanır** (`lib/data/services/local_notifier.dart`), sunucu gerektirmez. Uygulama her açıldığında merdiven yeniden kurulur: ~1. gün "Bugün buralarda görünmüyorsun…", ~2. gün "Zor bir gün müydü?…", ~3. gün "Sadece nasıl olduğunu sormak istedik…", ~7. gün "Gözlerimiz seni aradı…"; o gün kayıt yoksa 20:00'de "Bugünlük sayfamızı boş bıraktık…". Ayrıca **her gün 13.00'te** kısa, her gün değişen bir motivasyon mesajı gelir (o gün henüz kayıt yoksa günü değerlendirmeye nazik bir davet). Yalnızca 10:00–20:59 arası, kilit ekranında içerik gizli, dokununca uygulama açılır. Profil → Hatırlatmalar ile tamamen kapatılabilir.
- Her bildirim kısa ve sıcak bir başlıkla gelir ("Merhaba 👋", "Kendine bir mola ☁️", "Yarın da buradayız ✨"), genişletilebilir metin, kalkan simgesi ve tema rengiyle gösterilir.
- **Topluluk olayları** (arkadaş ekledi, cesaret notu, destek, yanıt, seri) uygulama açık ya da arka plandayken üst çubukta gösterilir; dokununca bildirim merkezi açılır. Uygulama **tamamen kapalıyken** de gelmesi için `firebase deploy --only functions` (Blaze planı) gerekir → `inboxPush`.
- Sunucudaki zamanlanmış hatırlatma (`gentleNudges`) çift bildirim olmasın diye varsayılan kapalıdır (`SERVER_NUDGES=true` ile açılır).

## Reklam güvenliği (AdMob'da ZORUNLU ayarlar)

Kod tarafında: alt çubuğun üstünde ince bir banner (Sakinleş sekmesinde gizli), kilitli tema düğmelerinde ve Hediyelerim'de isteğe bağlı ödüllü reklam; kriz, nefes ve oyun ekranlarında reklam yok; kişiselleştirilmemiş; `maxAdContentRating: G`; **yeme, kendine zarar, madde ve davranışsal bağımlılık seçen kullanıcılarda varsayılan KAPALI** (kullanıcı isterse açar). Tüm hediyeler seriyle de açılabilir.

AdMob konsolunda (Uygulamalar → Haven → **Engelleme kontrolleri**):
1. **İçerik derecelendirmesi:** maksimum **G** (Genel izleyici).
2. **Hassas kategoriler:** tetikleyici olabilecek her şeyi engelle. Özellikle kilo verme / diyet, kumar ve bahis, alkol, uyuşturucu ve takviye ürünleri, estetik işlemler ve beden değişikliği, flört, cinsellik, "hızlı zengin ol" ve tıbbi tedavi vaadi içeren kategoriler.
3. **Reklamveren URL'leri:** fark edilen tetikleyici reklamveren alan adlarını engelle listesine ekle.

## Dil desteği

Arayüz 5 dilde: Türkçe, İngilizce, İspanyolca, Çince (Mandarin), Hintçe (`lib/l10n/*.arb`, `flutter gen-l10n`). Profil → Dil'den seçilir; seçilmezse Türkçe açılır. **Psikolojik içerik metinleri (kategori bilgileri, günün sözleri, ipuçları) şimdilik yalnızca Türkçe**; bu metinlerin çevirisi anadili konuşan biri ve tercihen bir ruh sağlığı uzmanı tarafından gözden geçirilmelidir.

## Güvenlik ve etik notları

- Bildirimler sorunun adını asla söylemez (kilit ekranı gizliliği), seviye 3'ten sonra susar, 10:00-21:00 dışında gönderilmez. `npm test` ve `flutter test` bunu denetler.
- Analytics'e tanı adı ya da serbest metin gönderilmez; reklam kişiselleştirme sinyalleri kapalı; reklamlar kişiselleştirilmemiş.
- Kriz, zor gün ve nefes ekranlarında reklam yoktur.
- Destek hatları (112, 115 YEDAM) yayından önce resmi kaynaklardan tekrar doğrulanmalı.
- Haven bir tedavi aracı değildir. Bu ifade onboarding'de ve destek ekranında yer alır.
