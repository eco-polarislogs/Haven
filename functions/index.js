"use strict";

/**
 * Haven — Cloud Functions v2 (Node 22).
 *
 *  gentleNudges  (saatlik)  : bir süredir görünmeyen kullanıcılara şefkatli hatırlatma.
 *  inboxPush     (tetikleyici): bildirim kutusuna düşen olayı (arkadaş ekledi,
 *                               cesaret notu, destek, seri…) telefona push olarak iletir.
 *
 * Gereksinim: Firebase Blaze planı (Cloud Scheduler / Eventarc). Bu ölçekte ücretsiz
 * kotanın içinde kalır; yine de 1$'lık bütçe uyarısı kur. Blaze yokken uygulama içi
 * bildirim merkezi yine çalışır (gerçek zamanlı Firestore), sadece push gitmez.
 *
 * Bölge: us-central1 — Firestore veritabanı nam5 (ABD) konumunda; Firestore
 * tetikleyicileri veritabanıyla uyumlu bölgede olmalı.
 */

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

const nudges = require("./nudges");
const { inboxText } = require("./inbox_messages");

initializeApp();
const db = getFirestore();

const REGION = "us-central1";
const HOUR_MS = 60 * 60 * 1000;
const MAX_INACTIVE_HOURS = nudges.LEVEL_HOURS[3] + 24;
const DEAD_TARGET_CODES = new Set([
  "messaging/installation-id-not-registered",
  "messaging/registration-token-not-registered",
  "messaging/invalid-argument",
]);

function buildMessage(fid, body, data, tag) {
  return {
    fid,
    notification: { title: nudges.TITLE, body },
    data,
    android: {
      priority: "normal",
      // Kilit ekranında içerik gizlenir; aynı türden yeni bildirim eskisinin üstüne yazılır.
      notification: { visibility: "private", tag },
    },
    apns: { payload: { aps: { "thread-id": tag } } },
  };
}

/** Mesajları gönderir, geçersiz FID'leri kullanıcı dokümanından temizler. */
async function sendAll(messages, targets) {
  const deadByUser = new Map();
  for (let i = 0; i < messages.length; i += 500) {
    const res = await getMessaging().sendEach(messages.slice(i, i + 500));
    res.responses.forEach((r, j) => {
      if (r.success || !r.error || !DEAD_TARGET_CODES.has(r.error.code)) return;
      const { uid, fid } = targets[i + j];
      deadByUser.set(uid, [...(deadByUser.get(uid) || []), fid]);
    });
  }
  if (deadByUser.size) {
    const writer = db.bulkWriter();
    for (const [uid, fids] of deadByUser) {
      writer.update(db.doc(`users/${uid}`), { fcmFids: FieldValue.arrayRemove(...fids) });
    }
    await writer.close();
  }
  return [...deadByUser.values()].reduce((n, a) => n + a.length, 0);
}

exports.gentleNudges = onSchedule(
  { schedule: "every 1 hours", timeZone: "Europe/Istanbul", region: REGION, memory: "256MiB", retryCount: 0 },
  async () => {
    // Uygulama hatırlatmaları artık CİHAZDA zamanlıyor (lib/data/services/local_notifier.dart).
    // Çift bildirim olmasın diye sunucu hatırlatması varsayılan KAPALI; açmak için
    // functions/.env dosyasına SERVER_NUDGES=true yaz.
    if (process.env.SERVER_NUDGES !== "true") return;
    const now = new Date();
    const snap = await db
      .collection("users")
      .where("lastActiveAt", "<=", Timestamp.fromMillis(now.getTime() - nudges.LEVEL_HOURS[1] * HOUR_MS))
      .where("lastActiveAt", ">=", Timestamp.fromMillis(now.getTime() - MAX_INACTIVE_HOURS * HOUR_MS))
      .get();

    const messages = [];
    const targets = [];
    const nudged = [];

    for (const doc of snap.docs) {
      const u = doc.data();
      const fids = Array.isArray(u.fcmFids) ? u.fcmFids : [];
      if (u.notificationsEnabled === false || fids.length === 0) continue;
      if (nudges.isOutsideSendWindow(now, u.utcOffsetMinutes)) continue;

      const lastActive = u.lastActiveAt.toDate();
      const lastSent = u.nudge && u.nudge.lastSentAt ? u.nudge.lastSentAt.toDate() : null;
      if (lastSent && now - lastSent < nudges.MIN_HOURS_BETWEEN * HOUR_MS) continue;

      const level = nudges.levelToSend({
        hoursInactive: (now - lastActive) / HOUR_MS,
        lastLevel: u.nudge ? u.nudge.level : 0,
        lastSentAfterActivity: !!lastSent && lastSent > lastActive,
      });
      if (level === 0) continue;

      const { body } = nudges.pickMessage(u.categoryIds, level, nudges.seedFor(doc.id, now));
      for (const fid of fids) {
        messages.push(buildMessage(fid, body, { type: "gentle_nudge", level: String(level) }, "gentle_nudge"));
        targets.push({ uid: doc.id, fid });
      }
      nudged.push({ ref: doc.ref, level });
    }

    const removed = await sendAll(messages, targets);
    const writer = db.bulkWriter();
    for (const { ref, level } of nudged) {
      writer.update(ref, { nudge: { level, lastSentAt: FieldValue.serverTimestamp() } });
    }
    await writer.close();

    logger.info("gentleNudges", { candidates: snap.size, usersNudged: nudged.length, deadTargetsRemoved: removed });
  },
);

exports.inboxPush = onDocumentCreated(
  { document: "users/{uid}/inbox/{itemId}", region: REGION, memory: "256MiB", retry: false },
  async (event) => {
    const item = event.data && event.data.data();
    if (!item) return;
    const body = inboxText(item);
    if (!body) return;

    const uid = event.params.uid;
    const user = await db.doc(`users/${uid}`).get();
    const u = user.data() || {};
    const fids = Array.isArray(u.fcmFids) ? u.fcmFids : [];
    if (u.notificationsEnabled === false || fids.length === 0) return;

    const messages = fids.map((fid) => buildMessage(fid, body, { type: "inbox", inboxType: String(item.type) }, "inbox"));
    const removed = await sendAll(messages, fids.map((fid) => ({ uid, fid })));
    logger.info("inboxPush", { type: item.type, devices: fids.length, deadTargetsRemoved: removed });
  },
);
