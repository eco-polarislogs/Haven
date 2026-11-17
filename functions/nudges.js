"use strict";

/**
 * Şefkatli bildirim mantığı — SAF fonksiyonlar (Firebase bağımlılığı yok),
 * bu yüzden `npm test` ile internetsiz test edilir.
 *
 * DİL KURALLARI (nudges.test.js bunları otomatik denetler):
 *  1. Hiçbir mesaj sorunun adını söylemez. Bildirim kilit ekranında görünür;
 *     yanındaki biri "anoreksiya", "kaygı" ya da "kendine zarar" görmemeli.
 *  2. "Serin bozuldu", "kaybettin", "başarısız", "sıfırlandı" gibi ifadeler YOK.
 *  3. Yemek, kalori, kilo, "ağır" kelimeleri YOK (yeme bozukluğu tetikleyicisi).
 */

// Kullanıcı birden fazla alan seçtiyse EN HASSAS kategorinin tonu kullanılır.
// Sıralama lib/core/constants/struggle_catalog.dart'taki careLevel ile aynı.
const CARE_ORDER = [
  "selfHarm", "eating", "mood", "trauma", "substance", "anger",
  "ocd", "anxiety", "behavioral", "bfrb", "sleep",
];

// Seviye 1: ~24 saat, Seviye 2: ~48 saat, Seviye 3: ~7 gün. Sonra SESSİZLİK.
const LEVEL_HOURS = { 1: 24, 2: 48, 3: 168 };
const MIN_HOURS_BETWEEN = 20;
const SEND_WINDOW = { startHour: 10, endHour: 21 };

const TITLE = "Haven";

const MESSAGES = {
  bfrb: {
    1: ["Bugün buralarda görünmüyorsun, umarım günün güzel geçiyordur.",
      "Kısa bir mola vermeye ne dersin? Birkaç derin nefes bile iyi gelebilir."],
    2: ["Zor bir gün müydü? Bazen sadece dinlenmek gerekir, yarın yeniden deneyebiliriz.",
      "Kendine biraz yumuşaklık göstermeyi unutma. Hazır olduğunda buradayız."],
    3: ["Gözlerimiz seni aradı. Ne zaman hazır hissedersen burada bekliyoruz.",
      "Bugünlük sayfamızı boş bıraktık ama yarın o alanı senin için saklıyoruz."],
  },
  ocd: {
    1: ["Bugün buralarda görünmüyorsun, umarım günün iyi geçiyordur.",
      "Zihnine küçük bir mola vermeye ne dersin?"],
    2: ["Yorulduysan bu çok normal. Kendine sabırlı olmayı unutma."],
    3: ["Kapımız hep açık. Ne zaman istersen kaldığımız yerden devam ederiz."],
  },
  anxiety: {
    1: ["Bugün buralarda görünmüyorsun. Umarım kendine biraz yavaşlama izni verebilmişsindir.",
      "Bir nefes molası ister misin? Liman hep burada."],
    2: ["Zor bir gün müydü? Her şeyi bugün çözmek zorunda değilsin."],
    3: ["Seni düşündük. Ne zaman hazır olursan, kendi hızında devam ederiz."],
  },
  mood: {
    1: ["Sadece nasıl olduğunu merak ettik. Bugün küçük bir adım bile yeterli.",
      "Bugün buralarda görünmüyorsun; umarım kendine nazik davranabildiğin bir gündür."],
    2: ["Bazı günler diğerlerinden daha zordur ve bu çok insani. Hazır olduğunda buradayız."],
    3: ["Yalnız değilsin. Konuşmak istersen uygulamadaki Destek al bölümü bir dokunuş uzağında."],
  },
  eating: {
    1: ["Bugün buralarda görünmüyorsun. Umarım kendine yumuşak davranabildiğin bir gündür.",
      "Sadece nasıl olduğunu sormak istedik. Kendine iyi bakmayı unutma."],
    2: ["Bazı günler diğerlerinden daha zordur ve bu çok insani. Hazır olduğunda buradayız.",
      "Kendine, en sevdiğin arkadaşına davrandığın kadar nazik davranmayı dene."],
    3: ["Seni düşündük. Ne zaman istersen kaldığımız yerden, kendi hızında devam ederiz."],
  },
  behavioral: {
    1: ["Bugün buralarda görünmüyorsun, umarım günün güzel geçiyordur.",
      "Zihnin de dinlenmeyi hak ediyor. Birkaç derin nefese ne dersin?"],
    2: ["Yorgun hissediyorsan bu çok normal. Tökezlemek yolun bir parçası, yol hâlâ senin."],
    3: ["Kapımız hep açık. Ne zaman istersen kaldığımız yerden devam ederiz."],
  },
  substance: {
    1: ["Bugün nasılsın? Bir bardak su ve birkaç derin nefes iyi gelebilir.",
      "Bugün buralarda görünmüyorsun, umarım günün güzel geçiyordur."],
    2: ["Zor bir gün müydü? Bazen sadece dinlenmek gerekir, yarın yeniden deneyebiliriz."],
    3: ["Seni düşündük. Hazır hissettiğinde buradayız; yargı yok, sadece destek var."],
  },
  selfHarm: {
    1: ["Sadece nasıl olduğunu merak ettik. Bugün kendine iyi davranmayı hak ediyorsun."],
    2: ["Zor bir gün geçiriyorsan yalnız değilsin. Uygulamadaki sakinleşme köşesi seni bekliyor."],
    3: ["Seni önemsiyoruz. Konuşmaya ihtiyacın olursa uygulamadaki destek hatlarına tek dokunuşla ulaşabilirsin."],
  },
  anger: {
    1: ["Bugün buralarda görünmüyorsun, umarım günün iyi geçiyordur.",
      "Kısa bir nefes molası her şeyi biraz hafifletebilir."],
    2: ["Zor bir gün müydü? Hata yapmak seni kötü biri yapmaz; yarın yeniden deneyebiliriz."],
    3: ["Kapımız hep açık. Ne zaman istersen buradayız."],
  },
  trauma: {
    1: ["Sadece hal hatır sormak istedik. Kendine güvenli bir alan yaratabildiğini umuyoruz."],
    2: ["Zor bir dönemse, kendi hızında olmak tamamen yerinde. Buradayız."],
    3: ["Seni önemsiyoruz. Destek istersen uygulamada sana yol gösterecek kaynaklar var."],
  },
  sleep: {
    1: ["Bugün buralarda görünmüyorsun. Umarım biraz dinlenebilmişsindir.",
      "Kendine bir dinlenme anı ayırmaya ne dersin?"],
    2: ["Yorgunsan bu çok anlaşılır. Kendine yumuşak davran."],
    3: ["Seni düşündük. Hazır olduğunda buradayız."],
  },
};

function targetLevel(hoursInactive) {
  if (hoursInactive >= LEVEL_HOURS[3]) return 3;
  if (hoursInactive >= LEVEL_HOURS[2]) return 2;
  if (hoursInactive >= LEVEL_HOURS[1]) return 1;
  return 0;
}

/** Gönderilecek seviye; 0 = gönderme. Kullanıcı döndüyse sayaç sıfırlanır. */
function levelToSend({ hoursInactive, lastLevel, lastSentAfterActivity }) {
  const alreadySent = lastSentAfterActivity ? lastLevel || 0 : 0;
  const target = targetLevel(hoursInactive);
  return target > alreadySent ? target : 0;
}

function isOutsideSendWindow(nowUtc, utcOffsetMinutes) {
  const offset = Number.isFinite(utcOffsetMinutes) ? utcOffsetMinutes : 180;
  const minutes = (((nowUtc.getUTCHours() * 60 + nowUtc.getUTCMinutes() + offset) % 1440) + 1440) % 1440;
  const hour = Math.floor(minutes / 60);
  return hour < SEND_WINDOW.startHour || hour >= SEND_WINDOW.endHour;
}

function pickCategory(categoryIds) {
  const ids = Array.isArray(categoryIds) ? categoryIds : [];
  return CARE_ORDER.find((c) => ids.includes(c)) || "bfrb";
}

function pickMessage(categoryIds, level, seed) {
  const category = pickCategory(categoryIds);
  const pool = MESSAGES[category][level];
  return { category, body: pool[Math.abs(seed) % pool.length] };
}

function seedFor(uid, date) {
  let h = date.getUTCFullYear() * 400 + date.getUTCMonth() * 31 + date.getUTCDate();
  for (const ch of uid) h = (h * 31 + ch.charCodeAt(0)) | 0;
  return h;
}

module.exports = {
  CARE_ORDER, LEVEL_HOURS, MIN_HOURS_BETWEEN, MESSAGES, TITLE,
  targetLevel, levelToSend, isOutsideSendWindow, pickCategory, pickMessage, seedFor,
};
