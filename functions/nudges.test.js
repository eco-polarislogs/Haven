"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const n = require("./nudges");
const { KUDOS, inboxText } = require("./inbox_messages");

test("seviye eşikleri: 24 saat, 48 saat, 7 gün", () => {
  assert.equal(n.targetLevel(23), 0);
  assert.equal(n.targetLevel(24), 1);
  assert.equal(n.targetLevel(50), 2);
  assert.equal(n.targetLevel(170), 3);
});

test("aynı seviye iki kez gönderilmez, seviye 3'ten sonra sessizlik", () => {
  assert.equal(n.levelToSend({ hoursInactive: 30, lastLevel: 1, lastSentAfterActivity: true }), 0);
  assert.equal(n.levelToSend({ hoursInactive: 50, lastLevel: 1, lastSentAfterActivity: true }), 2);
  assert.equal(n.levelToSend({ hoursInactive: 190, lastLevel: 3, lastSentAfterActivity: true }), 0);
});

test("kullanıcı geri dönünce sayaç sıfırlanır", () => {
  assert.equal(n.levelToSend({ hoursInactive: 26, lastLevel: 3, lastSentAfterActivity: false }), 1);
});

test("gönderim penceresi kullanıcının yerel saatine göre (TR = UTC+3)", () => {
  assert.equal(n.isOutsideSendWindow(new Date("2026-11-17T06:00:00Z"), 180), true); // 09:00
  assert.equal(n.isOutsideSendWindow(new Date("2026-11-17T08:00:00Z"), 180), false); // 11:00
  assert.equal(n.isOutsideSendWindow(new Date("2026-11-17T18:30:00Z"), 180), true); // 21:30
});

test("birden fazla alan seçildiyse en hassas kategorinin tonu kullanılır", () => {
  assert.equal(n.pickCategory(["bfrb", "selfHarm"]), "selfHarm");
  assert.equal(n.pickCategory(["anxiety", "mood"]), "mood");
  assert.equal(n.pickCategory(["sleep", "behavioral"]), "behavioral");
  assert.equal(n.pickCategory(undefined), "bfrb");
});

test("11 kategorinin hepsinde 3 seviye için mesaj var", () => {
  assert.equal(n.CARE_ORDER.length, 11);
  for (const c of n.CARE_ORDER) {
    for (const level of [1, 2, 3]) {
      assert.ok(n.MESSAGES[c] && n.MESSAGES[c][level].length > 0, `${c}/${level} boş`);
    }
  }
});

test("DİL DENETİMİ: tetikleyici, yargılayıcı veya ifşa edici kelime yok", () => {
  const forbidden = [
    // yargılayıcı / kayıp dili
    "bozul", "kaybet", "kaybol", "başarısız", "sıfırla", "hayal kırıklığı",
    // yeme bozukluğu tetikleyicileri ("ağır" kiloyu çağrıştırır)
    "kalori", "kilo", "yemek", "diyet", "zayıf", "şişman", "ağır",
    // kilit ekranında sorunu ifşa eden kelimeler
    "saç", "tırnak", "anoreks", "bulim", "kumar", "bahis", "alkol", "sigara", "vape",
    "zarar", "kesme", "bağımlı", "depres", "kaygı", "panik", "travma", "uyku", "öfke", "takıntı",
  ];
  const all = [];
  for (const c of n.CARE_ORDER) for (const level of [1, 2, 3]) all.push(...n.MESSAGES[c][level]);
  all.push(...KUDOS);
  for (const msg of all) {
    const lower = msg.toLocaleLowerCase("tr-TR");
    for (const word of forbidden) {
      assert.ok(!lower.includes(word), `"${word}" bulundu → ${msg}`);
    }
  }
});

test("bildirim kutusu push metinleri: hazır mesajlar, takma ad kırpılır", () => {
  assert.equal(inboxText({ type: "kudos", fromNickname: "Sakin Liman 42", messageId: 0 }),
    "Sakin Liman 42: " + KUDOS[0]);
  assert.equal(inboxText({ type: "kudos", messageId: 99 }), "Bir arkadaşın: Seni düşünüyor.");
  assert.equal(inboxText({ type: "welcome" }), null);
  assert.equal(inboxText({ type: "logout" }), null);
  const long = inboxText({ type: "friend_added", fromNickname: "x".repeat(100) });
  assert.ok(long.length < 60);
});

test("cesaret mesajı listesi istemciyle aynı uzunlukta (8)", () => {
  assert.equal(KUDOS.length, 8);
});

test("bildirim kutusu push metinleri 5 dilde ve hazır mesaj listeleri eşit uzunlukta", () => {
  const { KUDOS_I18N } = require("./inbox_messages");
  for (const lang of ["tr", "en", "es", "zh", "hi"]) {
    assert.equal(KUDOS_I18N[lang].length, KUDOS.length, lang);
  }
  assert.equal(inboxText({ type: "note_reply", fromNickname: "Ada" }, "en"),
    "Ada replied to your post. You can read it in the Community tab.");
  assert.equal(inboxText({ type: "kudos", messageId: 1 }, "es"), "Una amistad: " + KUDOS_I18N.es[1]);
  assert.equal(inboxText({ type: "login" }, "xx"), inboxText({ type: "login" }, "tr"));
});
