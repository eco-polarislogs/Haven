# Haven'ı Google Play'de yayınlama: adım adım

Sürüm: **3.2.1 (4)** · Yüklenecek dosya: masaüstündeki `Haven-3.2.1-4.aab`
(aynısı: `build/app/outputs/bundle/release/app-release.aab`)

Kutucuk ve menü adları Play Console'da birebir aynı olmayabilir; Google arayüzü
zaman zaman değiştiriyor. Aşağıdaki **kalın** metinleri olduğu gibi kopyala.

---

## 1. Uygulamayı oluştur

Play Console → **Uygulama oluştur**

| Alan | Cevap |
|---|---|
| Uygulama adı | **Haven: Şefkatli İyileşme** |
| Varsayılan dil | **Türkçe – tr-TR** |
| Uygulama mı, oyun mu? | **Uygulama** |
| Ücretsiz mi, ücretli mi? | **Ücretsiz** |
| Beyanlar (Geliştirici Program Politikaları, ABD ihracat yasaları) | Okuyup kendin işaretle |

---

## 2. Kontrol paneli → "Uygulamanızı ayarlayın" görevleri

### Gizlilik politikası
**https://ecren-7050e.web.app/gizlilik**

### Uygulama erişimi
"Tüm işlevler veya bazı işlevler kısıtlı" → talimat ekle:

- Ad: **Google ile giriş**
- Kullanıcı adı / şifre: boş bırak (gerekmiyor)
- Talimat (inceleme ekibi İngilizce okur):

> **All features require sign-in. On the welcome screen tap "Sign up / sign in with Google"; any Google account works — no extra username, password or code is needed. After signing in, choose a nickname, pick at least one area, and accept the consent step to reach the home screen.**

### Reklamlar
**Evet, uygulamam reklam içeriyor.**

### İçerik derecelendirmesi (IARC anketi)
- E-posta: **solmazgulecren@gmail.com**
- Kategori: sosyal etkileşim / kullanıcı içeriği olan uygulama türünü seç (oyun değil).
- Şiddet, cinsellik, kumar: **Hayır**
- Küfür: **Hayır** (paylaşımlar otomatik denetleniyor)
- Uyuşturucu/alkol/tütün referansı: **Evet**, yalnızca bağımlılıktan kurtulma bağlamında; özendirme yok
- Kullanıcılar birbiriyle etkileşebilir / içerik paylaşabilir: **Evet** (denetimli; Bildir ve Engelle var)
- Konum paylaşımı: **Hayır** · Dijital satın alma: **Hayır**

### Hedef kitle ve içerik
- Hedef yaş grubu: **18 ve üzeri** (ruh sağlığı içeriği; Aile politikası dışında kalır)
- Uygulama çocukların ilgisini çekebilir mi?: **Hayır**

### Veri güvenliği

| Veri türü | Toplanıyor | Paylaşılıyor | Amaç | Zorunlu mu |
|---|---|---|---|---|
| E-posta adresi (Google girişi) | Evet | Hayır | Hesap yönetimi | Evet |
| Ad (takma ad) | Evet | Hayır | Uygulama işlevi | Evet |
| Sağlık bilgisi (seçilen alanlar, günlük kayıtlar) | Evet | Hayır | Uygulama işlevi, kişiselleştirme | Evet |
| Diğer uygulama içi mesajlar (paylaşım, yanıt, destek talebi) | Evet | Hayır | Uygulama işlevi | Hayır |
| Uygulama etkileşimleri (Analytics) | Evet | Hayır | Analiz | Hayır |
| Cihaz veya diğer kimlikler (bildirim, reklam kimliği) | Evet | Evet (Google AdMob) | Reklam, bildirim | Evet |

- Veriler aktarım sırasında şifreleniyor mu?: **Evet**
- Kullanıcı verilerinin silinmesini isteyebilir mi?: **Evet**
- Hesap silme URL'si: **https://ecren-7050e.web.app/hesap-silme**

### Reklam kimliği
**Evet**, kullanım amacı: **Reklam veya pazarlama**

### Sağlık uygulamaları
Ruh sağlığı ve iyi oluş desteği / alışkanlık takibi seçeneklerini işaretle.
Açıklama gerekirse:

> **Haven is a wellness companion for mental-health recovery: daily check-ins, streaks, breathing exercises and a moderated peer-support community. It is not a medical device, does not diagnose or treat, and directs users in crisis to emergency and support lines.**

### Diğer beyanlar
Devlet uygulaması: **Hayır** · Finansal özellikler: **Hiçbiri** · Haber uygulaması: **Hayır**

### Kategori ve iletişim (Mağaza ayarları)
- Kategori: **Sağlık ve Fitness**
- E-posta: **solmazgulecren@gmail.com**
- Web sitesi: **https://ecren-7050e.web.app**

### Ana mağaza girişi
Masaüstündeki **Haven Mağaza** klasörü; neyin nereye gittiği `README.md`'de.
İngilizce için **Çeviri ekle → İngilizce (ABD)**.

---

## 3. İlk yükleme: Dahili test (incelemesiz, hemen yayına girer)

Test ve yayın → **Dahili test** → **Yeni sürüm oluştur**

1. Play Uygulama İmzalama sorulursa: **Google tarafından oluşturulan anahtarı kullan** (önerilen).
2. `Haven-3.2.1-4.aab` dosyasını yükle.
3. Sürüm adı: **3.2.1 (4)**
4. Sürüm notları (olduğu gibi yapıştır):

```
<tr-TR>
Haven'ın ilk sürümü: günlük değerlendirme ve seri takibi, anonim paylaşım da yapılabilen denetimli topluluk, arkadaşlar ve cesaret notları, bildirim merkezi, nefes egzersizi ve sakinleştirici oyunlar, destek hatları. 5 dil: Türkçe, İngilizce, İspanyolca, Çince, Hintçe.
</tr-TR>
<en-US>
Haven's first release: daily check-ins and streaks, a moderated community where you can also post anonymously, friends and encouragement notes, a notification center, breathing exercises and calming games, support lines. 5 languages: Turkish, English, Spanish, Chinese, Hindi.
</en-US>
```

5. Test kullanıcıları: bir e-posta listesi oluştur, kendi Gmail adresini ekle → **Kaydet → İncele → Yayınla**.

### Yüklemeden hemen sonra (Google ile giriş için ŞART)
Test ve yayın → Kurulum → **Uygulama bütünlüğü → Uygulama imzalama**:
**Uygulama imzalama anahtarı sertifikası** altındaki **SHA-1** ve **SHA-256** değerlerini kopyalayıp
Claude'a ver. Claude bunları `firebase apps:android:sha:create` ile Firebase'e ekler. Bu
yapılmazsa Play'den indirilen uygulamada "Google ile giriş" çalışmaz.

---

## 4. Kapalı test → Üretim

1. Test ve yayın → **Kapalı test** → aynı AAB'yi yükle, aynı sürüm notları.
2. Test kullanıcıları: **en az 12 Gmail adresi** (hocan dahil). Google Grubu ya da e-posta listesi.
3. Ülke: **Türkiye** (istersen tüm ülkeler).
4. İncelemeye gönder. Onaydan sonra **katılım bağlantısını** testçilere gönder; her biri bağlantıdan
   "Test kullanıcısı ol" deyip uygulamayı Play'den kurmalı.
5. **14 gün kesintisiz** test sonrası Kontrol paneli → **Üretime erişim başvurusu**.

Ödev şartı için ilk kanıt dahili test sürümüdür; teslimden en az 2 hafta önce yüklenmiş olmalı.

---

## 5. Gerçek reklam (AdMob onayından sonra)
AdMob uygulama kimliğini (`ca-app-pub-…~…`) ve üç reklam birimi kimliğini (alt banner, ana sayfa
banner'ı, ödüllü) Claude'a ver. Claude `AndroidManifest.xml` ve `lib/core/constants/ad_ids.dart`
dosyalarını güncelleyip yeni sürüm (3.2.2 (5)) derler. O zamana kadar test reklamları görünür.
