# Haven — 14 Günlük Plan ve Mimari Kurulum

> Durum (17 Kasım 2026): Uygulamanın kodu büyük ölçüde hazır ve emülatörde çalışıyor. Bu plan
> kalan işleri (hesaplar, mağaza, test, içerik gözden geçirme) ve ekip iş bölümünü kapsar.

## ⚠️ Kritik yol: Google Play kapalı testi

13 Kasım 2023'ten sonra açılmış **kişisel** Play geliştirici hesaplarında, uygulama herkese açık
yayına çıkmadan önce **en az 12 test kullanıcısıyla kesintisiz 14 gün kapalı test** zorunlu.
Bu yüzden: **Play Console hesabı 1. gün açılır, kapalı test en geç 3. gün başlar.** Hocana
"kapalı test bağlantısı yükleme şartını karşılıyor mu?" diye bugün sor. Ekipte 2023 öncesi
açılmış bir hesap varsa kural uygulanmaz.

## Mimari kurulum

| Katman | Seçim | Neden |
|---|---|---|
| Durum yönetimi | **flutter_riverpod 3** (kod üretimi yok) | Auth ve Firestore akışları doğrudan `StreamProvider`'a oturur; `BuildContext` gerekmez |
| Kimlik | firebase_auth + **google_sign_in 7** (+ iOS'ta Apple) | Google tek dokunuşla doğrular; kayıt Haven'ın kendi ekranlarında |
| Veri | **cloud_firestore** (offline önbellek sınırsız) | Kriz anında internetsiz açılır; yazmalar kuyruğa alınır |
| İstatistik | firebase_analytics | Ekran görüntülemeleri + 20 olay; içerik asla gönderilmez |
| Bildirim | **flutter_local_notifications + timezone** (cihazda) + firebase_messaging (sunucu) | Şefkatli hatırlatmalar sunucusuz; topluluk olayları üst çubukta |
| Gelir | google_mobile_ads (ödüllü, G sınırlı, kişiselleştirilmemiş) | Hassas kategorilerde varsayılan kapalı |
| Acil arama | url_launcher | `tel:112`, `tel:115` |
| Dil | flutter_localizations + intl (gen-l10n, ARB) | TR, EN, ES, ZH, HI |
| Animasyon | Flutter'ın yerleşik araçları (AnimationController, CustomPainter, AnimatedContainer) | Ek paket gerekmez: nefes dairesi, baloncuklar, deniz feneri logosu |
| Sunucu | Cloud Functions v2 (Node 22): `inboxPush`, opsiyonel `gentleNudges` | Blaze planı gerekir; olmadan da uygulama çalışır |

Klasör yapısı **özellik odaklı**: `lib/features/{auth, onboarding, home, journal, community,
notifications, safe_space, relax/games, support, rewards, profile, session, shell}`; ortak kod
`lib/core` (tema, katalog, denetleyici, söz motoru, seri mantığı) ve `lib/data` (modeller, servisler).

## Özellik durumu

| Özellik | Durum |
|---|---|
| Haven kimliği: deniz feneri logosu, nötr palet, 4 tema (Okyanus, Orman, Gün Batımı, Gece) | ✅ |
| Kendi kayıt ekranları: hayvan avatarları, anonimlik seçimi, avatara göre takma ad | ✅ |
| 11 kategori / 28 alan, DSM-5-TR & ICD-11, WHO/NIMH verileri, kategoriye özel tetikleyici kelimeler | ✅ |
| Günlük seri + alan serileri, şefkat payı, **biten serilerin geçmişi, rekorla yarış (I Am Sober)** | ✅ |
| Dinamik günün sözü (saat, mevsim, gün, seri durumu) | ✅ |
| Ana ekran panosu: seri, rekor, %30 gün, rekor yarışı, notlarım, ay ışıkları | ✅ |
| Sakinleş: acil arama, al-tut-ver nefes, 5-4-3-2-1, baloncuk, renk eşleştirme, hafıza | ✅ |
| Topluluk: denetimli notlar, destek, bildir, arkadaş kodu, seri görünürlüğü, hazır cesaret notları | ✅ |
| Bildirim merkezi (zil) + telefonun üst çubuğu (yerel) | ✅ |
| Hediyelerim: seriyle açılan tema ve avatarlar, isteğe bağlı reklam | ✅ |
| 5 dil (arayüz) | ✅ · psikolojik içerik metinleri yalnızca TR (çeviri + uzman kontrolü gerekli) |
| Sunucu push (uygulama kapalıyken topluluk bildirimi) | ⏳ Blaze planı gerekli |

## Roller ("Bireysel X Ortak")

**A: İçerik & arayüz** (metinler, çeviri kontrolü, ekran görüntüleri, test senaryoları) ·
**B: Altyapı & mağaza** (Play Console, AdMob, Firebase, imzalama, Functions). Tek kişiysen: sabah A, akşam B.

## Gün gün

| Gün | Sabah | Akşam | Bitti sayılır |
|---|---|---|---|
| 1 | Uygulamayı uçtan uca dene (giriş → kayıt → kayıt → topluluk → sakinleş) | **Play Console hesabı aç** (25 $), **AdMob hesabı aç** | Hesap başvuruları yapıldı |
| 2 | Bulunan hataları listele | Play'de uygulama oluştur, **dahili teste AAB yükle**, Play App Signing SHA'larını Firebase'e ekle | Play'den kurulan sürümde Google girişi çalışıyor |
| 3 | Mağaza metinleri (kısa/uzun açıklama) | Uygulama içeriği formları (gizlilik URL'si, reklam: evet, hedef kitle 18+, veri güvenliği, sağlık beyanı, hesap silme URL'si). **Kapalı test + 12 tester (hoca dahil)** | 14 günlük sayaç başladı |
| 4 | Topluluk denetimini gerçek cümlelerle dene; yanlış pozitif/negatifleri listeye ekle | AdMob: uygulama + ödüllü birim, **hassas kategori engelleri** (README) | Denetim testleri yeşil |
| 5 | İçerik metinlerini hedef kitleden 2-3 kişiye okut | Analytics DebugView ile olayları doğrula | Geri bildirim notları alındı |
| 6 | Erişilebilirlik: büyük yazı tipi, TalkBack | (Opsiyonel) Blaze + 1 $ bütçe uyarısı + `firebase deploy --only functions` | Taşma yok |
| 7 | **Ara kontrol demosu** provası | Kapalı teste v1.1 | 3 dk demo akıyor |
| 8 | İçerik çevirisi planı (EN öncelikli) | Ekran görüntüleri (5 dil için en az TR/EN) | Mağaza görselleri hazır |
| 9 | Tester geri bildirimleri | Hata düzeltmeleri | — |
| 10 | Offline senaryolar, gece yarısı, çoklu alan, hesap silme | Sürüm v1.2 | Kritik hata yok |
| 11 | Gizlilik politikasını kodla karşılaştır | Firestore kurallarını Rules Playground'da dene | Uyumlu |
| 12 | Rapor: mimari, şema, güvenlik | Demo videosu | — |
| 13 | Sürüm adayı (`--obfuscate`) | Kapalı teste yükle | RC hazır |
| 14 | Teslim paketi | 14 gün dolunca (~17. gün) **production başvurusu** | Teslim edilebilir |

## Kapsam dışı (rapora "gelecek çalışmalar")

İçerik metinlerinin 4 dile çevirisi ve klinik gözden geçirmesi, sunucu tarafı yapay zekâ ile içerik
denetimi (Perspective API vb.), AdMob sunucu tarafı ödül doğrulama (SSV), App Check, iOS sürümü.
