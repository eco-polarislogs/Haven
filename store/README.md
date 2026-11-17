# Google Play mağaza malzemeleri

Play Console → **Büyüme → Mağazada bulunma → Ana mağaza girişi** sayfasında hangi dosyanın nereye gittiği:

| Play Console alanı | Dosya | Şart |
|---|---|---|
| Uygulama adı | `listing-tr.md` → "Uygulama adı" | en fazla 30 karakter (24) |
| Kısa açıklama | `listing-tr.md` → "Kısa açıklama" | en fazla 80 karakter (79) |
| Tam açıklama | `listing-tr.md` → "Tam açıklama" | en fazla 4000 karakter (~2700) |
| Uygulama simgesi | `icon-512.png` | 512×512, 32 bit PNG |
| Öne çıkan grafik | `feature-graphic-tr.png` | 1024×500, alfasız PNG |
| Telefon ekran görüntüleri | `screenshots/tr/1-bugun.png` … `5-destek.png` | 2–8 adet, 1080×1920 (9:16) |

İngilizce mağaza sayfası için Play Console'da **Çeviri ekle → İngilizce (ABD)** seç ve `listing-en.md`, `feature-graphic-en.png`, `screenshots/en/` dosyalarını aynı yerlere koy.

## Ekran görüntüleri hakkında

Görüntüler uygulamanın **gerçek ekranlarıdır** (Bugün, Topluluk, Sakinleş, Bildirimler, Destek ve öneriler). Kişiler ve paylaşımlar örnek veridir; uygulamadaki gibi takma ad ve hayvan avatarı kullanılır, gerçek bir kullanıcıya ait değildir. Emojiler Windows'un emoji yazı tipiyle çizildi; telefonda kendi cihazının emoji stiliyle görünür.

## Yeniden üretmek

```powershell
python -I store/make_graphics.py                  # simge + öne çıkan grafik (Microsoft Edge ile)
flutter test tool/store_screenshots_test.dart      # ekran görüntüleri (store/screenshots/)
```

Ekranlar değişince ekran görüntülerini yeniden üretip Play Console'daki görselleri güncelle.
