# Haven — Firestore Şeması

Tasarım hedefleri, öncelik sırasıyla:

1. **Gizlilik:** Her şey `users/{uid}` altında; kurallar herkesi yalnızca kendi ağacına kilitler.
2. **Offline:** Her ekran önbellekten açılır, her check-in internetsiz kaydedilir.
3. **Az okuma:** Ana ekran ve takvim, geçmişi taramadan çizilir.
4. **Bildirim sorgusu tek alanla:** Cloud Function tek bir aralık sorgusuyla aday bulur, ek indeks gerekmez.

## Ağaç

```jsonc
{
  "users": {
    "{uid}": {
      // --- kimlik ve oturum ---
      "createdAt": "Timestamp",
      "lastActiveAt": "Timestamp",          // ★ bildirim tetikleyicisinin TEK sorgu alanı
      "utcOffsetMinutes": 180,              // gönderim penceresi için (TR = +180)
      "locale": "tr",

      // --- seçimler (denormalize) ---
      "struggleIds": ["trichotillomania", "anorexia"],
      "categoryIds": ["bfrb", "eating"],    // Function alt koleksiyon okumadan ton seçsin diye

      // --- bildirim ---
      "notificationsEnabled": true,
      "fcmFids": ["<cihaz-1-FID>", "<cihaz-2-FID>"],  // çoklu cihaz, FCM 17+ (token değil FID)
      "nudge": { "level": 2, "lastSentAt": "Timestamp" }, // SADECE sunucu yazar (rules)

      // --- tercih ve ödüller ---
      "analyticsEnabled": true,
      "themeId": "pastel",                  // "pastel" | "night"
      "unlocks": { "night": "Timestamp" },  // ödüllü reklamla açılanlar
      "quoteUnlockedDay": "2026-11-17",
      "lastCheckInDay": "2026-11-17",
      "consent": { "version": 1, "at": "Timestamp" },  // KVKK açık rıza kaydı

      // ===== alt koleksiyon: alan başına 1 doküman, ID = katalog ID'si =====
      "struggles": {
        "trichotillomania": {
          "typeId": "trichotillomania",
          "categoryId": "bfrb",
          "active": true,                   // bırakılırsa false: geçmiş korunur
          "startedAt": "Timestamp",
          "currentStreak": 4,
          "longestStreak": 9,
          "totalKindDays": 23,              // ★ asla azalmaz, arayüzdeki ana sayı
          "lastKindDay": "2026-11-17",
          "lastCheckInDay": "2026-11-17",
          "lastResult": "kind",             // "kind" | "hard"
          "updatedAt": "Timestamp"
        },
        "anorexia": { "...": "aynı yapı" }
      },

      // ===== alt koleksiyon: AY başına 1 doküman, ID = "yyyy-MM" =====
      "checkins": {
        "2026-11": {
          "days": {
            "16": { "trichotillomania": "kind", "anorexia": "hard" },
            "17": { "trichotillomania": "kind" }
          },
          "updatedAt": "Timestamp"
        }
      }
    }
  }
}
```

## Neden böyle?

| Karar | Gerekçe |
|---|---|
| **Seri sayaçları `struggles/{id}` içinde, denormalize** | Ana ekran = 1 kullanıcı + N alan dokümanı. Seriyi hesaplamak için geçmiş taranmaz. |
| **Check-in'ler ay dokümanında (`checkins/2026-11`)** | Takvimin bir ayı = **1 okuma**. Günlük doküman olsaydı 30 okuma olurdu. Bir yıllık geçmiş = 12 doküman. Boyut sınırı (1 MB) asla dolmaz. |
| **Ay içinde gün → {alan → sonuç}** | Birden fazla alan aynı gün tek yazmayla kaydedilir; aynı gün iki alan çakışmaz (`merge: true` iç içe map'leri alan alan birleştirir). |
| **Tarihler `"2026-11-17"` string, yerel saatle** | Timestamp UTC'dir; TR'de 01:30'daki check-in UTC'de önceki güne düşer. String anahtar kullanıcının yaşadığı gündür. |
| **Doküman ID'leri deterministik** (`typeId`, `yyyy-MM`) | Offline'da iki kez basılsa bile kopya oluşmaz; yazma idempotent. |
| **`categoryIds` kullanıcı dokümanında** | Function, kullanıcı başına alt koleksiyon okumadan mesaj tonunu seçer. |
| **`totalKindDays` hiç azalmaz** | Şefkat felsefesi: zor gün emeği silmez. Günlük değerlendirme 3 sonuçlu: `kind` (Başardım) ve `struggled` (Zorlandım ama dayandım) seriyi sürdürür; `currentStreak` yalnızca `hard` (Başaramadım) seçildiğinde 0 olur ve biten seri `history`ye yazılır; uygulamaya girmemek seriyi 1 gün boyunca bozmaz (`kGraceDays`). |
| **`nudge` alanı istemciye kapalı** | Bildirim sayacı istemciden değiştirilemez. |
| **Katalog (kategoriler, metinler) Firestore'da değil kodda** | Sıfır okuma, tam offline. |

## Okuma/yazma maliyeti

| İşlem | Okuma | Yazma |
|---|---|---|
| Uygulama açılışı (kullanıcı + N alan + bu ay) | 1 + N + 1 | 1 (`lastActiveAt`, 15 dk kısıtlı) |
| Check-in (bir alan) | 0 (önbellekten) | 3, **tek batch** |
| Takvimde bir ay geri gitmek | 1 | 0 |
| Saatlik bildirim taraması | aday kullanıcı sayısı | bildirim gönderilen kullanıcı sayısı |

Ücretsiz kota (günde 50 bin okuma / 20 bin yazma) bir ders projesinin çok üstünde.

## Offline için 3 altın kural (kodda uygulandı)

1. **Yazmaları `await` etme.** Firestore'da yazma Future'ı *sunucu onaylayınca* tamamlanır; internetsizken `await batch.commit()` sonsuza kadar bekler ve arayüz donar. Yerel önbellek anında güncellenir, `snapshots()` dinleyicileri yeni veriyi hemen gösterir. → `HavenRepository._fireAndForget`
2. **Transaction kullanma.** Transaction'lar offline'da hata verir. Yeni seri değeri istemcide hesaplanır (`applyCheckIn`, saf fonksiyon, testli) ve `WriteBatch` ile yazılır. Batch offline'da kuyruğa alınır.
3. **Önbellek sınırsız:** `Settings(persistenceEnabled: true, cacheSizeBytes: CACHE_SIZE_UNLIMITED)` → `main.dart`

İstisna: **hesap silme** internet ister; önce `Source.server` ile erişim doğrulanır ki işlem yarım kalmasın.

## Güvenlik kuralları

`firestore.rules`: kullanıcı yalnızca `users/{kendi uid}` ağacını okur/yazar, `nudge` alanına dokunamaz, geri kalan her şey kapalı. Deploy: `firebase deploy --only firestore:rules`. Firebase Console → Firestore → Rules → **Rules Playground** ile başka bir uid'nin verisini okumayı deneyip reddedildiğini doğrula.

## Topluluk koleksiyonları (Haven 2)

```jsonc
{
  "users/{uid}": {
    "...": "yukarıdaki kişisel alanlar",
    "nickname": "Sakin Liman 42",          // toplulukta görünen takma ad
    "avatar": 3,                           // nötr ikon avatar (fotoğraf yok)
    "communityJoined": true,               // topluluk tercihi (opt-in)
    "dailyStreak": 5, "longestDailyStreak": 9, "lastActivityDay": "2026-11-17",
    "supportedNotes": ["noteId"],          // destek verdiğim notlar (buton durumu için)
    "reportedNotes": ["noteId"],           // bildirdiğim notlar (benim için hemen gizlenir)
    "lastSupportSuggestionDay": "2026-11-17",

    "friends (alt koleksiyon)": { "{friendUid}": { "since": "Timestamp" } },  // karşılıklı
    "inbox (alt koleksiyon)": {
      "{id}": {
        "type": "kudos",                   // welcome|login|logout|friend_added|kudos|note_support|friend_streak|streak_milestone|support_suggestion
        "fromUid": "…", "fromNickname": "…", "fromAvatar": 2,
        "messageId": 1,                    // hazır cesaret mesajı (serbest metin YOK)
        "value": 7,                        // seri günü vb.
        "createdAt": "Timestamp", "read": false
      }
    }
  },

  "profiles/{uid}": {                      // HERKESE AÇIK (giriş yapmışlara): bilerek az bilgi
    "nickname": "Sakin Liman 42", "avatar": 3, "friendCode": "K7M2QX",
    "dailyStreak": 5, "longestDailyStreak": 9, "lastActivityDay": "2026-11-17"
  },

  "notes/{noteId}": {                      // bir çembere (kategoriye) paylaşılan destek notu
    "authorUid": "…", "nickname": "…", "avatar": 3, "streak": 5,
    "circleId": "anxiety", "text": "≤280 karakter, denetlenmiş",
    "createdAt": "Timestamp", "supportCount": 4, "reportCount": 0,
    "supports/{uid}": { "at": "Timestamp" },   // kişi başı 1 destek
    "reports/{uid}":  { "reason": "…" }        // kişi başı 1 şikayet; ≥3 → gizlenir
  }
}
```

| Karar | Gerekçe |
|---|---|
| Profil ayrı ve herkese açık; `users` özel kalır | Arkadaşlar seriyi görebilir ama tanılar, kayıtlar, e-posta asla görünmez. |
| Hangi alanlarla mücadele edildiği profilde YOK | Not paylaşmadıkça kimse kimin hangi çemberde olduğunu bilemez. Kurallar `users/{uid}.categoryIds`'i sunucuda okuyarak doğrular. |
| Yorum yok, sadece "Destek ol" | Tartışma ve laf sokma için alan bırakmamak. |
| Arkadaşlara serbest mesaj yok, hazır cesaret notları var | Arkadaşlık özelliği zorbalığa dönüşemez (`messageId < 20` kuralı). |
| Lider tablosu yok | Kıyas, bu kitlede yetersizlik hissi doğurabilir. |
| Denetim iki katmanlı | İstemci (`ContentModerator`, Türkçeye özel, nazik açıklamalı) + sunucu (`firestore.rules → clean()`). Kriz ifadesi içeren not paylaşılmaz; kullanıcıya destek paneli açılır. |
| Destek/şikayet sayacı + kişisel kayıt aynı batch'te | Kurallar `existsAfter` ile kişi başı tek oy zorlar. |

İndeks: `notes` → `circleId ASC, createdAt DESC` (çember akışı). `firestore.indexes.json`.

## Haven 2.1 eklemeleri

```jsonc
{
  "users/{uid}": {
    "anonymous": true,            // kimliğini gizlemeyi seçti mi (takma ad avatardan önerilir)
    "adsOptIn": null,             // null = varsayılan (hassas kategorilerde reklam kapalı), true/false = seçim
    "language": "tr",             // tr | en | es | zh | hi (null = cihaz dili)
    "themeId": "ocean",           // ocean | forest | sunset | night
    "unlocks": { "sunset": "Timestamp", "avatar_8": "Timestamp" }, // reklamla açılan hediyeler
    "journal (alt koleksiyon)": { "{id}": { "text": "≤1000", "createdAt": "Timestamp" } } // özel notlar
  },
  "users/{uid}/struggles/{typeId}": {
    "history": [ { "days": 7, "end": "2026-11-08" } ]  // biten seriler: SİLİNMEZ (en fazla 20)
  }
}
```

| Karar | Gerekçe |
|---|---|
| Biten seriler `history` dizisinde | I Am Sober mantığı: geçmiş başarı hatırlatılır, kullanıcı kendi rekoruyla yarışır. Ayrı koleksiyon yerine dizi → ana ekran ek okuma yapmaz. |
| Seriyle açılan hediyeler yazılmaz, hesaplanır | `bestStreak ≥ eşik` → açık. Sadece reklamla açılanlar `unlocks`'a yazılır; hile yapılsa bile sadece kozmetik. |
| Özel notlar (journal) sahibine özel | Kelime filtresi uygulanmaz (özel alan); kriz ifadesi varsa kullanıcıya destek paneli gösterilir. |

## X tarzı topluluk: yanıtlar (v2.2)

```
notes/{noteId}
  … (önceki alanlar)
  replyCount: int            // yanıt eklenince +1, silinince −1 (kurallar yalnızca ±1'e izin verir)

notes/{noteId}/replies/{replyId}
  authorUid: string          // == request.auth.uid
  nickname: string (≤24)
  avatar: int
  text: string (1–280, sunucuda clean() filtresi)
  createdAt: timestamp
```

- Yanıt, sayaç artışı ve gönderi sahibine `note_reply` bildirimi **tek batch**'te yazılır.
- Yanıtlar istemcide gönderinin çemberine özel tetikleyici kelimelerle de denetlenir; kriz ifadesi paylaşılmaz, destek paneli açılır.
- Hesap silmede kullanıcının tüm yanıtları `collectionGroup('replies').where('authorUid', ==, uid)` ile bulunur ve silinir (alan dışlaması `firestore.indexes.json` → `fieldOverrides`).
- Yeni bileşik dizin: `notes (authorUid ASC, createdAt DESC)` → "Arkadaşlar" akışı ve kişi profili.
- `users/{uid}/inbox` izinli türler: `friend_added`, `kudos`, `note_support`, `note_reply`, `friend_streak`.

## Anonim paylaşım (v2.3)

```
notes/{noteId}                      // anonim biçim
  anonymous: true
  nickname: "Anonim üye"
  avatar: -1
  streak: 0
  // authorUid YOK: yazarın kimliği herkese açık belgede tutulmaz
  circleId, text, createdAt, supportCount, reportCount, replyCount

users/{uid}/myNotes/{noteId}        // yalnızca sahibi okur
  at: timestamp
```

- Anonim gönderi ve `myNotes` sahiplik kaydı **aynı batch**'te yazılır. Kural: `myNotes` kaydı yalnızca gönderi henüz yokken ve aynı istekte oluşuyorsa yazılabilir (başkasının gönderisini sahiplenip silmek engellenir).
- Silme: `authorUid == ben` **veya** `users/{ben}/myNotes/{noteId}` var.
- Anonim gönderinin yazarı bilinmediği için destek/yanıt bildirimi gönderilmez.
- Okuyan tarafı koruma: `ContentModerator.maskFor` okuyanın alanları için tetikleyici ifadeleri ekranda "•••" ile gizler (veri değişmez).

## Destek ve öneriler (v3.1)

```
feedback/{id}                        // kullanıcı → geliştirici talebi; toplulukta GÖRÜNMEZ
  uid: string                        // gönderen (yanıt bildirimi için)
  kind: "idea" | "bug" | "help" | "other"
  text: string                       // 10–1500 karakter
  status: "open" | "seen" | "planned" | "done"
  nickname?: string                  // yalnızca "takma adımı ekle" seçildiyse
  lang: "tr" | "en" | "es" | "zh" | "hi"
  platform: string                   // android / iOS
  appVersion: string
  createdAt: timestamp (sunucu)
  reply?: string, replyLang?: string, repliedAt?: timestamp, updatedAt?: timestamp   // yalnızca geliştirici yazar
```

- **Okuma:** yalnızca talebin sahibi ve geliştirici (`developerUids()` kuralı = `kDeveloperUids`).
- **Oluşturma:** yalnızca kendi adına, `status == "open"`, hazır alanlarla. Mücadele alanları ve notlar EKLENMEZ.
- **Güncelleme:** yalnızca geliştirici; sadece `status`, `reply`, `replyLang`, `repliedAt`, `updatedAt`.
- **Silme:** sahibi ya da geliştirici. Hesap silinince kullanıcının tüm talepleri de silinir.
- **Bildirimler:** talep gönderilince aynı batch'te geliştiricinin kutusuna `feedback_new` (value = tür); geliştirici yeni yanıt yazınca ya da durumu planlandı/tamamlandı yapınca kullanıcının kutusuna `feedback_reply` (value = yeni durum). İkisi de `inboxPush` ile 5 dilde push olur (Blaze).
- Geliştirici eklemek: uid'yi `lib/core/constants/app_constants.dart → kDeveloperUids` ve `firestore.rules → developerUids()` listelerine ekle, `firebase deploy --only firestore:rules`.
