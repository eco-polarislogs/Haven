"use strict";

/**
 * Uygulama içi bildirim kutusuna düşen olayların push metinleri.
 * KUDOS listesi lib/core/constants/app_constants.dart → kKudosMessages ile
 * AYNI sırada olmalı (istemci yalnızca index yazar; serbest metin yok).
 */
const KUDOS = [
  "Seni düşünüyorum, yanındayım. 🤝",
  "Bugün de buradasın, bu çok değerli. 💙",
  "Küçük adımlar da sayılır. Devam!",
  "Zor bir günse, yalnız değilsin.",
  "Serin harika gidiyor, gurur duyuyorum. 🔥",
  "Nefes al, ben buradayım.",
  "Kendine nazik olmayı unutma.",
  "Seninle aynı yolda yürüdüğüm için mutluyum.",
];

function nick(item) {
  const n = typeof item.fromNickname === "string" ? item.fromNickname.trim().slice(0, 24) : "";
  return n || "Bir arkadaşın";
}

/** null → bu tür için push gönderilmez (ör. hoş geldin, çıkış). */
function inboxText(item) {
  switch (item.type) {
    case "friend_added":
      return `${nick(item)} seni arkadaş olarak ekledi.`;
    case "kudos":
      return `${nick(item)}: ${KUDOS[item.messageId] || "Seni düşünüyor."}`;
    case "note_support":
      return `${nick(item)} paylaşımına destek verdi. 💙`;
    case "note_reply":
      return `${nick(item)} paylaşımına yanıt verdi. Topluluk sekmesinden okuyabilirsin.`;
    case "friend_streak":
      return `${nick(item)} ${item.value || ""} günlük seriye ulaştı. Ona bir cesaret notu göndermeye ne dersin?`;
    case "streak_milestone":
      return `${item.value || ""} günlük seri! Kendine her gün geri döndün.`;
    case "login":
      return "Hesabına yeni bir giriş yapıldı. Bu sen değilsen Profil → Çıkış yap.";
    case "support_suggestion":
      return "Seni düşünüyoruz. Destek al bölümü her zaman bir dokunuş uzağında.";
    default:
      return null;
  }
}

module.exports = { KUDOS, inboxText };
