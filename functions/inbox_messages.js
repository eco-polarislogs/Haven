"use strict";

/**
 * Uygulama içi bildirim kutusuna düşen olayların push metinleri (5 dil).
 * KUDOS listeleri lib/core/constants/app_constants.dart → kKudosMessages ile
 * AYNI sırada olmalı (istemci yalnızca index yazar; serbest metin yok).
 * Dil: users/{uid}.language ("tr" | "en" | "es" | "zh" | "hi"); yoksa Türkçe.
 */
const KUDOS_I18N = {
  tr: [
    "Seni düşünüyorum, yanındayım. 🤝",
    "Bugün de buradasın, bu çok değerli. 💙",
    "Küçük adımlar da sayılır. Devam!",
    "Zor bir günse, yalnız değilsin.",
    "Serin harika gidiyor, gurur duyuyorum. 🔥",
    "Nefes al, ben buradayım.",
    "Kendine nazik olmayı unutma.",
    "Seninle aynı yolda yürüdüğüm için mutluyum.",
  ],
  en: [
    "I'm thinking of you, I'm with you. 🤝",
    "You're here today too, and that means a lot. 💙",
    "Small steps count too. Keep going!",
    "If it's a hard day, you're not alone.",
    "Your streak is going great, I'm proud of you. 🔥",
    "Breathe, I'm here.",
    "Don't forget to be kind to yourself.",
    "I'm glad to walk the same path as you.",
  ],
  es: [
    "Pienso en ti, estoy contigo. 🤝",
    "Hoy también estás aquí, y eso vale mucho. 💙",
    "Los pasos pequeños también cuentan. ¡Sigue!",
    "Si es un día difícil, no estás solo.",
    "Tu racha va genial, estoy orgulloso de ti. 🔥",
    "Respira, estoy aquí.",
    "No olvides ser amable contigo.",
    "Me alegra recorrer el mismo camino que tú.",
  ],
  zh: [
    "我在想你，我陪着你。🤝",
    "今天你也在这里，这非常珍贵。💙",
    "小步也算数。继续加油！",
    "如果今天很难，你并不孤单。",
    "你的连续天数很棒，我为你骄傲。🔥",
    "深呼吸，我在这里。",
    "别忘了善待自己。",
    "很高兴和你走在同一条路上。",
  ],
  hi: [
    "मैं आपके बारे में सोच रहा/रही हूँ, मैं आपके साथ हूँ। 🤝",
    "आज भी आप यहाँ हैं, यह बहुत मायने रखता है। 💙",
    "छोटे कदम भी गिने जाते हैं। चलते रहें!",
    "अगर दिन मुश्किल है, तो आप अकेले नहीं हैं।",
    "आपकी स्ट्रीक शानदार चल रही है, मुझे आप पर गर्व है। 🔥",
    "साँस लीजिए, मैं यहाँ हूँ।",
    "ख़ुद के साथ नरमी बरतना न भूलें।",
    "मुझे ख़ुशी है कि मैं आपके साथ एक ही राह पर हूँ।",
  ],
};

/** Geriye uyumluluk: Türkçe liste. */
const KUDOS = KUDOS_I18N.tr;

const T = {
  tr: {
    friend: "Bir arkadaşın",
    thinking: "Seni düşünüyor.",
    friend_added: (n) => `${n} seni arkadaş olarak ekledi.`,
    note_support: (n) => `${n} paylaşımına destek verdi. 💙`,
    note_reply: (n) => `${n} paylaşımına yanıt verdi. Topluluk sekmesinden okuyabilirsin.`,
    friend_streak: (n, v) => `${n} ${v} günlük seriye ulaştı. Ona bir cesaret notu göndermeye ne dersin?`,
    streak_milestone: (v) => `${v} günlük seri! Kendine her gün geri döndün.`,
    login: "Hesabına yeni bir giriş yapıldı. Bu sen değilsen Profil → Çıkış yap.",
    support_suggestion: "Seni düşünüyoruz. Destek al bölümü her zaman bir dokunuş uzağında.",
    kinds: ["Öneri", "Hata bildirimi", "Yardım", "Diğer", "Şikâyet"],
    feedback_new: (k, n) => `Yeni destek talebi (${k}) · ${n}. Profil → Geliştirici paneli.`,
    anon: "İsimsiz",
    feedback_reply: ["Geliştirici talebini yanıtladı. Profil → Destek ve öneriler.", "Talebin planlandı. Ayrıntılar Profil → Destek ve öneriler'de.", "Talebin tamamlandı, teşekkürler! Ayrıntılar Profil → Destek ve öneriler'de."],
  },
  en: {
    friend: "A friend",
    thinking: "Thinking of you.",
    friend_added: (n) => `${n} added you as a friend.`,
    note_support: (n) => `${n} supported your post. 💙`,
    note_reply: (n) => `${n} replied to your post. You can read it in the Community tab.`,
    friend_streak: (n, v) => `${n} reached a ${v}-day streak. How about sending them an encouragement note?`,
    streak_milestone: (v) => `${v}-day streak! You came back to yourself every day.`,
    login: "There was a new sign-in to your account. If this wasn't you, go to Profile → Sign out.",
    support_suggestion: "We're thinking of you. The Get support section is always one tap away.",
    kinds: ["Idea", "Bug report", "Help", "Other", "Report"],
    feedback_new: (k, n) => `New support request (${k}) · ${n}. Profile → Developer panel.`,
    anon: "No name",
    feedback_reply: ["The developer replied to your request. Profile → Support & feedback.", "Your request is planned. Details in Profile → Support & feedback.", "Your request is done, thank you! Details in Profile → Support & feedback."],
  },
  es: {
    friend: "Una amistad",
    thinking: "Piensa en ti.",
    friend_added: (n) => `${n} te añadió como amistad.`,
    note_support: (n) => `${n} apoyó tu publicación. 💙`,
    note_reply: (n) => `${n} respondió a tu publicación. Puedes leerla en la pestaña Comunidad.`,
    friend_streak: (n, v) => `${n} alcanzó una racha de ${v} días. ¿Qué tal si le envías una nota de ánimo?`,
    streak_milestone: (v) => `¡Racha de ${v} días! Volviste a ti cada día.`,
    login: "Se inició sesión en tu cuenta. Si no fuiste tú, ve a Perfil → Cerrar sesión.",
    support_suggestion: "Pensamos en ti. La sección Buscar apoyo está siempre a un toque.",
    kinds: ["Sugerencia", "Error", "Ayuda", "Otro", "Denuncia"],
    feedback_new: (k, n) => `Nueva solicitud de soporte (${k}) · ${n}. Perfil → Panel de desarrollo.`,
    anon: "Sin nombre",
    feedback_reply: ["El equipo de desarrollo respondió a tu solicitud. Perfil → Soporte y sugerencias.", "Tu solicitud está planificada. Detalles en Perfil → Soporte y sugerencias.", "¡Tu solicitud está completada, gracias! Detalles en Perfil → Soporte y sugerencias."],
  },
  zh: {
    friend: "一位好友",
    thinking: "在想着你。",
    friend_added: (n) => `${n} 添加你为好友。`,
    note_support: (n) => `${n} 支持了你的动态。💙`,
    note_reply: (n) => `${n} 回复了你的动态。可以在“社区”标签页查看。`,
    friend_streak: (n, v) => `${n} 达成了连续 ${v} 天。要不要给对方发一条鼓励留言？`,
    streak_milestone: (v) => `连续 ${v} 天！你每天都回到了自己身边。`,
    login: "你的账户有新的登录。如果不是你本人，请前往“个人资料 → 退出登录”。",
    support_suggestion: "我们在想你。“获取支持”板块永远只需轻点一下。",
    kinds: ["建议", "问题反馈", "帮助", "其他", "举报"],
    feedback_new: (k, n) => `新的支持请求（${k}）· ${n}。个人资料 → 开发者面板。`,
    anon: "匿名",
    feedback_reply: ["开发者已回复你的请求。个人资料 → 支持与建议。", "你的请求已列入计划。详情见“个人资料 → 支持与建议”。", "你的请求已完成，谢谢！详情见“个人资料 → 支持与建议”。"],
  },
  hi: {
    friend: "एक दोस्त",
    thinking: "आपके बारे में सोच रहे हैं।",
    friend_added: (n) => `${n} ने आपको दोस्त के रूप में जोड़ा।`,
    note_support: (n) => `${n} ने आपकी पोस्ट को सपोर्ट किया। 💙`,
    note_reply: (n) => `${n} ने आपकी पोस्ट का जवाब दिया। आप इसे समुदाय टैब में पढ़ सकते हैं।`,
    friend_streak: (n, v) => `${n} ने ${v} दिन की स्ट्रीक पूरी की। क्या आप उन्हें एक हौसला नोट भेजना चाहेंगे?`,
    streak_milestone: (v) => `${v} दिन की स्ट्रीक! आप हर दिन ख़ुद के पास लौटे।`,
    login: "आपके खाते में नया साइन इन हुआ। अगर यह आप नहीं थे, तो प्रोफ़ाइल → साइन आउट पर जाएँ।",
    support_suggestion: "हम आपके बारे में सोच रहे हैं। सहायता लें सेक्शन हमेशा एक टैप दूर है।",
    kinds: ["सुझाव", "गड़बड़ी की रिपोर्ट", "मदद", "अन्य", "शिकायत"],
    feedback_new: (k, n) => `नया सहायता अनुरोध (${k}) · ${n}। प्रोफ़ाइल → डेवलपर पैनल।`,
    anon: "बिना नाम",
    feedback_reply: ["डेवलपर ने आपके अनुरोध का जवाब दिया। प्रोफ़ाइल → सहायता और सुझाव।", "आपका अनुरोध योजना में शामिल हो गया। विवरण प्रोफ़ाइल → सहायता और सुझाव में।", "आपका अनुरोध पूरा हो गया, धन्यवाद! विवरण प्रोफ़ाइल → सहायता और सुझाव में।"],
  },
};

function pick(lang) {
  return T[lang] ? lang : "tr";
}

function nick(item, lang) {
  const n = typeof item.fromNickname === "string" ? item.fromNickname.trim().slice(0, 24) : "";
  return n || T[lang].friend;
}

/** null → bu tür için push gönderilmez (ör. hoş geldin, çıkış). */
function inboxText(item, language) {
  const lang = pick(language);
  const t = T[lang];
  const v = item.value || "";
  switch (item.type) {
    case "friend_added":
      return t.friend_added(nick(item, lang));
    case "kudos":
      return `${nick(item, lang)}: ${KUDOS_I18N[lang][item.messageId] || t.thinking}`;
    case "note_support":
      return t.note_support(nick(item, lang));
    case "note_reply":
      return t.note_reply(nick(item, lang));
    case "friend_streak":
      return t.friend_streak(nick(item, lang), v);
    case "streak_milestone":
      return t.streak_milestone(v);
    case "login":
      return t.login;
    case "support_suggestion":
      return t.support_suggestion;
    case "feedback_new": {
      // value = talep türü (0 öneri, 1 hata, 2 yardım, 3 diğer, 4 şikâyet)
      const n = typeof item.fromNickname === "string" && item.fromNickname.trim() ? item.fromNickname.trim().slice(0, 24) : t.anon;
      return t.feedback_new(t.kinds[item.value] || t.kinds[3], n);
    }
    case "feedback_reply":
      // value = yeni durum (2 planlandı, 3 tamamlandı, diğerleri: yanıt)
      return item.value === 2 ? t.feedback_reply[1] : item.value === 3 ? t.feedback_reply[2] : t.feedback_reply[0];
    default:
      return null;
  }
}

module.exports = { KUDOS, KUDOS_I18N, inboxText };
