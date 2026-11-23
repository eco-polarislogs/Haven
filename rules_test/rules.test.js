// firestore.rules gerçekten çalışıyor mu? Uygulamanın yazdığı verilerin AYNISI
// (lib/data/services/*_repository.dart) Firestore emülatöründe denenir.
// Uygulamadaki yazmaların çoğu "gönder ve unut" olduğu için kural bir yazmayı
// reddederse kullanıcı hata görmez, veri sessizce kaybolur; bu test onu yakalar.
//
// Çalıştır (proje kökünden; Java 11+ gerekir, ör. Android Studio'nun jbr'si):
//   firebase emulators:exec --only firestore --project demo-haven "npm --prefix rules_test test"
const { test, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc, collection, collectionGroup, setDoc, updateDoc, deleteDoc, addDoc, getDoc, getDocs,
  query, where, orderBy, limit, writeBatch, serverTimestamp, increment, arrayUnion, arrayRemove,
} = require('firebase/firestore');

const DEV = '45q7AAJ06TOi49mMyHEPdLMDPi82'; // firestore.rules → developerUids()
const merge = { merge: true };
let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-haven',
    firestore: { rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8') },
  });
});
after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

const db = (uid) => env.authenticatedContext(uid).firestore();

/** Kuralları atlayarak başlangıç verisi yazar. */
async function seed(fn) {
  await env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));
}

/** Kayıt akışını tamamlamış bir kullanıcı (+ isteğe bağlı herkese açık profil). */
async function seedUser(uid, { nickname = 'Sevimli Panda', categories = ['bfrb', 'sleep'], blocked = [], profile = true } = {}) {
  await seed(async (d) => {
    await setDoc(doc(d, 'users', uid), {
      struggleIds: ['trichotillomania'], categoryIds: categories, nickname, avatar: 1,
      communityJoined: true, blockedUids: blocked,
    });
    if (profile) {
      await setDoc(doc(d, 'profiles', uid), { nickname, avatar: 1, friendCode: `HVN-${uid.slice(0, 4).toUpperCase()}` });
    }
  });
}

const me = (uid, nickname = 'Sevimli Panda') => ({ uid, nickname, avatar: 1 });

/** CommunityRepository._fromMe */
const fromMe = (p, type, { messageId, value } = {}) => ({
  type, fromUid: p.uid, fromNickname: p.nickname, fromAvatar: p.avatar,
  ...(messageId === undefined ? {} : { messageId }),
  ...(value === undefined ? {} : { value }),
  createdAt: serverTimestamp(), read: false,
});

/** Bob'un, Alice'in isimli gönderisi (n1) üzerinde işlem yapabileceği durum. */
async function seedNote(id = 'n1', author = 'alice', extra = {}) {
  await seed((d) => setDoc(doc(d, 'notes', id), {
    circleId: 'bfrb', text: 'Bugün iyi geçti, dayandım.', supportCount: 0, reportCount: 0, replyCount: 0,
    anonymous: false, authorUid: author, nickname: 'Sevimli Panda', avatar: 1, streak: 3, lang: 'tr', ...extra,
  }));
}

// ------------------------------------------------------------------ kayıt

test('kayıt: kullanıcı belgesi, kayıt akışı, herkese açık profil (HavenRepository / CommunityRepository)', async () => {
  const a = db('alice');
  // ensureUserDoc
  await assertSucceeds(setDoc(doc(a, 'users', 'alice'), {
    createdAt: serverTimestamp(), lastActiveAt: serverTimestamp(), utcOffsetMinutes: 180, locale: 'tr', language: 'tr',
    struggleIds: [], categoryIds: [], notificationsEnabled: true, analyticsEnabled: true, communityJoined: false,
    themeId: 'light', fcmFids: [],
  }));
  // completeOnboarding (+ _writeStruggleChanges)
  const b = writeBatch(a);
  b.set(doc(a, 'users', 'alice', 'struggles', 'trichotillomania'), {
    typeId: 'trichotillomania', categoryId: 'bfrb', active: true, startedAt: serverTimestamp(), updatedAt: serverTimestamp(),
  }, merge);
  b.set(doc(a, 'users', 'alice'), {
    nickname: 'Sevimli Panda', avatar: 1, anonymous: false, communityJoined: true,
    struggleIds: ['trichotillomania'], categoryIds: ['bfrb'], consent: { version: 2, at: serverTimestamp() },
  }, merge);
  await assertSucceeds(b.commit());
  // ensureProfile (ilk kez) ve sonra güncelleme
  await assertSucceeds(setDoc(doc(a, 'profiles', 'alice'), {
    nickname: 'Sevimli Panda', avatar: 1, friendCode: 'HVN-AB12', dailyStreak: 0, longestDailyStreak: 0,
    lastActivityDay: null, createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(setDoc(doc(a, 'profiles', 'alice'), {
    nickname: 'Cesur Panda', avatar: 2, friendCode: 'HVN-AB12', updatedAt: serverTimestamp(),
  }, merge));
  // syncStreak
  await assertSucceeds(setDoc(doc(a, 'profiles', 'alice'), {
    nickname: 'Cesur Panda', friendCode: 'HVN-AB12', dailyStreak: 4, longestDailyStreak: 9,
    lastActivityDay: '2026-11-17', updatedAt: serverTimestamp(),
  }, merge));
  // Ayarlar, dil, tema, reklam, bildirim kimliği, etkinlik
  for (const data of [
    { language: 'en' }, { country: 'TR' }, { notificationsEnabled: false }, { analyticsEnabled: false },
    { adsOptIn: false }, { themeId: 'ocean' }, { unlocks: { forest: serverTimestamp() }, themeId: 'forest' },
    { fcmFids: arrayUnion('fid-1') }, { lastActiveAt: serverTimestamp(), utcOffsetMinutes: 180 },
    { lastSupportSuggestionDay: '2026-11-17' }, { quoteUnlockedDay: '2026-11-17' },
  ]) {
    await assertSucceeds(setDoc(doc(a, 'users', 'alice'), data, merge));
  }
  await assertSucceeds(updateDoc(doc(a, 'users', 'alice'), { fcmFids: arrayRemove('fid-1') }));
  await assertSucceeds(getDoc(doc(a, 'users', 'alice')));
});

test('kayıt: başkası kişisel verimi okuyamaz; sunucu alanı (nudge) yazılamaz; arkadaş kodu değişmez', async () => {
  await seedUser('alice');
  await assertFails(getDoc(doc(db('bob'), 'users', 'alice')));
  await assertFails(setDoc(doc(db('alice'), 'users', 'alice'), { nudge: { level: 1 } }, merge));
  await assertFails(setDoc(doc(db('alice'), 'profiles', 'alice'), { nickname: 'Sevimli Panda', friendCode: 'HVN-XXXX' }, merge));
  await assertFails(setDoc(doc(db('bob'), 'profiles', 'alice'), { nickname: 'Hacker', avatar: 1, friendCode: 'X' }));
});

// ------------------------------------------------------------------ günlük kullanım

test('günlük değerlendirme: ay belgesi + alan serisi + günlük seri tek batch (HavenRepository.checkIn)', async () => {
  await seedUser('alice');
  const a = db('alice');
  const b = writeBatch(a);
  b.set(doc(a, 'users', 'alice', 'checkins', '2026-11'), { days: { 17: { trichotillomania: 'kind' } }, updatedAt: serverTimestamp() }, merge);
  b.set(doc(a, 'users', 'alice', 'struggles', 'trichotillomania'), {
    currentStreak: 4, longestStreak: 9, totalKindDays: 20, lastKindDay: '2026-11-17', lastCheckInDay: '2026-11-17',
    lastResult: 'kind', history: [{ days: 9, end: '2026-10-30' }], updatedAt: serverTimestamp(),
  }, merge);
  b.set(doc(a, 'users', 'alice'), {
    lastActiveAt: serverTimestamp(), lastCheckInDay: '2026-11-17', dailyStreak: 4, longestDailyStreak: 9, lastActivityDay: '2026-11-17',
  }, merge);
  await assertSucceeds(b.commit());
  await assertSucceeds(getDoc(doc(a, 'users', 'alice', 'checkins', '2026-11')));
  await assertFails(getDoc(doc(db('bob'), 'users', 'alice', 'checkins', '2026-11')));
});

test('özel notlar (günlük) ve kendi bildirim kutum', async () => {
  await seedUser('alice');
  const a = db('alice');
  const j = await assertSucceeds(addDoc(collection(a, 'users', 'alice', 'journal'), { text: 'Bugün nefes egzersizi iyi geldi.', createdAt: serverTimestamp() }));
  await assertSucceeds(deleteDoc(j));
  await assertFails(addDoc(collection(a, 'users', 'alice', 'journal'), { text: 'x'.repeat(1001), createdAt: serverTimestamp() }));
  // addInbox (giriş/seri olayları) + okundu işaretleme
  const i = await assertSucceeds(addDoc(collection(a, 'users', 'alice', 'inbox'), { type: 'login', createdAt: serverTimestamp(), read: false }));
  await assertSucceeds(addDoc(collection(a, 'users', 'alice', 'inbox'), { type: 'streak_milestone', createdAt: serverTimestamp(), read: false, value: 7 }));
  await assertSucceeds(updateDoc(i, { read: true }));
  await assertSucceeds(getDocs(query(collection(a, 'users', 'alice', 'inbox'), orderBy('createdAt', 'desc'), limit(100))));
});

// ------------------------------------------------------------------ topluluk

test('paylaşım: isimli ve anonim; akış okunur; link ve seçilmemiş alan reddedilir (CommunityRepository.postNote)', async () => {
  await seedUser('alice');
  const a = db('alice');
  const common = { circleId: 'bfrb', text: 'Bugün zor bir gündü ama dayandım.', createdAt: serverTimestamp(), supportCount: 0, reportCount: 0, lang: 'tr' };
  await assertSucceeds(setDoc(doc(a, 'notes', 'named1'), { ...common, anonymous: false, authorUid: 'alice', nickname: 'Sevimli Panda', avatar: 1, streak: 3 }));
  const anon = writeBatch(a);
  anon.set(doc(a, 'notes', 'anon1'), { ...common, anonymous: true, nickname: 'Anonim üye', avatar: -1, streak: 0 });
  anon.set(doc(a, 'users', 'alice', 'myNotes', 'anon1'), { at: serverTimestamp() });
  await assertSucceeds(anon.commit());
  await assertSucceeds(getDocs(query(collection(db('bob'), 'notes'), where('circleId', 'in', ['bfrb']), orderBy('createdAt', 'desc'), limit(60))));
  await assertFails(setDoc(doc(a, 'notes', 'bad1'), { ...common, text: 'bak https://ornek.com', anonymous: false, authorUid: 'alice', nickname: 'x', avatar: 1, streak: 0 }));
  await assertFails(setDoc(doc(a, 'notes', 'bad2'), { ...common, circleId: 'eating', anonymous: false, authorUid: 'alice', nickname: 'x', avatar: 1, streak: 0 }));
  // Uygulamanın yazmadığı alan (şişirilmiş yanıt sayacı), uzun/kirli ad ve istemci saati reddedilir.
  const named = { ...common, anonymous: false, authorUid: 'alice', nickname: 'Sevimli Panda', avatar: 1, streak: 3 };
  await assertFails(setDoc(doc(a, 'notes', 'bad3'), { ...named, replyCount: 999 }));
  await assertFails(setDoc(doc(a, 'notes', 'bad4'), { ...named, nickname: 'Haven Resmi Destek Ekibi Yöneticisi' }));
  await assertFails(setDoc(doc(a, 'notes', 'bad5'), { ...named, nickname: 'www.ornek.com' }));
  await assertFails(setDoc(doc(a, 'notes', 'bad6'), { ...named, createdAt: new Date('2030-01-01') }));
  // Silme: isimli (deleteNote batch'i olmayan myNotes kaydını da siler) ve anonim
  const del = writeBatch(a);
  del.delete(doc(a, 'notes', 'named1'));
  del.delete(doc(a, 'users', 'alice', 'myNotes', 'named1'));
  await assertSucceeds(del.commit());
  const delAnon = writeBatch(a);
  delAnon.delete(doc(a, 'notes', 'anon1'));
  delAnon.delete(doc(a, 'users', 'alice', 'myNotes', 'anon1'));
  await assertSucceeds(delAnon.commit());
});

test('destek, bildir, yanıt ve yanıt silme; destek kişi başı bir kez', async () => {
  await seedUser('alice');
  await seedUser('bob', { nickname: 'Cesur Kuş' });
  await seedNote();
  const bob = me('bob', 'Cesur Kuş');
  const b = db('bob');
  // supportNote
  const s = writeBatch(b);
  s.set(doc(b, 'notes', 'n1', 'supports', 'bob'), { at: serverTimestamp() });
  s.update(doc(b, 'notes', 'n1'), { supportCount: increment(1) });
  s.set(doc(b, 'users', 'bob'), { supportedNotes: arrayUnion('n1') }, merge);
  s.set(doc(collection(b, 'users', 'alice', 'inbox')), fromMe(bob, 'note_support'));
  await assertSucceeds(s.commit());
  const again = writeBatch(b);
  again.set(doc(b, 'notes', 'n1', 'supports', 'bob'), { at: serverTimestamp() });
  again.update(doc(b, 'notes', 'n1'), { supportCount: increment(1) });
  await assertFails(again.commit());
  // reportNote
  const r = writeBatch(b);
  r.set(doc(b, 'notes', 'n1', 'reports', 'bob'), { reason: 'Spam veya reklam', at: serverTimestamp() });
  r.update(doc(b, 'notes', 'n1'), { reportCount: increment(1) });
  r.set(doc(b, 'users', 'bob'), { reportedNotes: arrayUnion('n1') }, merge);
  await assertSucceeds(r.commit());
  // postReply
  const replyRef = doc(collection(b, 'notes', 'n1', 'replies'));
  const p = writeBatch(b);
  p.set(replyRef, { authorUid: 'bob', nickname: 'Cesur Kuş', avatar: 1, text: 'Çok güzel, devam!', createdAt: serverTimestamp(), lang: 'tr' });
  p.update(doc(b, 'notes', 'n1'), { replyCount: increment(1) });
  p.set(doc(collection(b, 'users', 'alice', 'inbox')), fromMe(bob, 'note_reply'));
  await assertSucceeds(p.commit());
  await assertSucceeds(getDocs(query(collection(db('alice'), 'notes', 'n1', 'replies'), orderBy('createdAt'), limit(100))));
  // Yanıt da istemci saatiyle yazılamaz.
  const late = writeBatch(b);
  late.set(doc(collection(b, 'notes', 'n1', 'replies')), { authorUid: 'bob', nickname: 'Cesur Kuş', avatar: 1, text: 'Devam!', createdAt: new Date('2030-01-01'), lang: 'tr' });
  late.update(doc(b, 'notes', 'n1'), { replyCount: increment(1) });
  await assertFails(late.commit());
  // deleteReply
  const d = writeBatch(b);
  d.delete(replyRef);
  d.update(doc(b, 'notes', 'n1'), { replyCount: increment(-1) });
  await assertSucceeds(d.commit());
  // Alice'in bildirim kutusunda iki bildirim var
  const inbox = await assertSucceeds(getDocs(collection(db('alice'), 'users', 'alice', 'inbox')));
  if (inbox.size !== 2) throw new Error(`2 bildirim bekleniyordu, ${inbox.size} var`);
});

test('arkadaşlık, cesaret notu ve seri kutlaması (15\'erli batch)', async () => {
  await seedUser('alice');
  await seedUser('bob', { nickname: 'Cesur Kuş' });
  const alice = me('alice');
  const a = db('alice');
  // addFriend
  const f = writeBatch(a);
  f.set(doc(a, 'users', 'alice', 'friends', 'bob'), { since: serverTimestamp() });
  f.set(doc(a, 'users', 'bob', 'friends', 'alice'), { since: serverTimestamp() });
  f.set(doc(collection(a, 'users', 'bob', 'inbox')), fromMe(alice, 'friend_added'));
  await assertSucceeds(f.commit());
  await assertSucceeds(getDocs(query(collection(a, 'profiles'), where('friendCode', '==', 'HVN-BOB'), limit(1))));
  // sendKudos
  await assertSucceeds(addDoc(collection(a, 'users', 'bob', 'inbox'), fromMe(alice, 'kudos', { messageId: 3 })));
  await assertFails(addDoc(collection(a, 'users', 'bob', 'inbox'), { ...fromMe(alice, 'kudos', { messageId: 3 }), text: 'serbest metin' }));
  // Başkasının kutusuna istemci saatiyle (listenin tepesine sabitlemek için) yazılamaz.
  await assertFails(addDoc(collection(a, 'users', 'bob', 'inbox'), { ...fromMe(alice, 'kudos', { messageId: 3 }), createdAt: new Date('2030-01-01') }));
  // notifyFriendsOfMilestone: her alıcı için kural bir okuma yapar; 15'lik batch sınırın içinde kalmalı
  const friends = Array.from({ length: 15 }, (_, i) => `f${i}`);
  for (const id of friends) await seedUser(id, { profile: false });
  const m = writeBatch(a);
  for (const id of friends) m.set(doc(collection(a, 'users', id, 'inbox')), fromMe(alice, 'friend_streak', { value: 30 }));
  await assertSucceeds(m.commit());
  // removeFriend
  const rm = writeBatch(a);
  rm.delete(doc(a, 'users', 'alice', 'friends', 'bob'));
  rm.delete(doc(a, 'users', 'bob', 'friends', 'alice'));
  await assertSucceeds(rm.commit());
});

test('engelleme: engellenen kişi arkadaş ekleyemez, not ve bildirim bırakamaz; engel kaldırılınca düzelir', async () => {
  await seedUser('alice');
  await seedUser('bob', { nickname: 'Cesur Kuş' });
  await seedNote();
  await seed(async (d) => {
    await setDoc(doc(d, 'users', 'alice', 'friends', 'bob'), { since: 1 });
    await setDoc(doc(d, 'users', 'bob', 'friends', 'alice'), { since: 1 });
  });
  const a = db('alice');
  // blockUser
  const blk = writeBatch(a);
  blk.set(doc(a, 'users', 'alice'), { blockedUids: arrayUnion('bob') }, merge);
  blk.delete(doc(a, 'users', 'alice', 'friends', 'bob'));
  blk.delete(doc(a, 'users', 'bob', 'friends', 'alice'));
  await assertSucceeds(blk.commit());
  // hideReply (bildirilen yanıt benim için gizlenir)
  await assertSucceeds(setDoc(doc(a, 'users', 'alice'), { reportedReplies: arrayUnion('r1') }, merge));

  const bob = me('bob', 'Cesur Kuş');
  const b = db('bob');
  const add = writeBatch(b);
  add.set(doc(b, 'users', 'bob', 'friends', 'alice'), { since: serverTimestamp() });
  add.set(doc(b, 'users', 'alice', 'friends', 'bob'), { since: serverTimestamp() });
  add.set(doc(collection(b, 'users', 'alice', 'inbox')), fromMe(bob, 'friend_added'));
  await assertFails(add.commit());
  await assertFails(addDoc(collection(b, 'users', 'alice', 'inbox'), fromMe(bob, 'kudos', { messageId: 1 })));
  const s = writeBatch(b);
  s.set(doc(b, 'notes', 'n1', 'supports', 'bob'), { at: serverTimestamp() });
  s.update(doc(b, 'notes', 'n1'), { supportCount: increment(1) });
  s.set(doc(collection(b, 'users', 'alice', 'inbox')), fromMe(bob, 'note_support'));
  await assertFails(s.commit());

  // unblockUser → yeniden mümkün
  await assertSucceeds(setDoc(doc(a, 'users', 'alice'), { blockedUids: arrayRemove('bob') }, merge));
  await assertSucceeds(addDoc(collection(b, 'users', 'alice', 'inbox'), fromMe(bob, 'kudos', { messageId: 1 })));
});

// ------------------------------------------------------------------ destek ve şikâyet

/** SupportRepository.submit (+ geliştiricinin kutusuna "yeni talep"). */
function submitBatch(d, uid, { kind = 'idea', text = 'Akşam hatırlatmasının saatini seçebilsem çok iyi olurdu.', nickname, target, value = 0 } = {}) {
  const ticket = doc(collection(d, 'feedback'));
  const b = writeBatch(d);
  b.set(ticket, {
    uid, kind, text, status: 'open',
    ...(nickname ? { nickname } : {}), ...(target ? { target } : {}),
    lang: 'tr', platform: 'android', appVersion: '3.2.0', createdAt: serverTimestamp(),
  });
  if (uid !== DEV) {
    b.set(doc(collection(d, 'users', DEV, 'inbox')), {
      type: 'feedback_new', fromUid: uid, ...(nickname ? { fromNickname: nickname } : {}), value, createdAt: serverTimestamp(), read: false,
    });
  }
  return { ticket, commit: () => b.commit() };
}

test('destek talebi: gönder, kendi taleplerimi gör; başkası göremez (SupportRepository.submit)', async () => {
  await seedUser('alice');
  await seedUser(DEV, { nickname: 'Haven', profile: false });
  const a = db('alice');
  const { ticket, commit } = submitBatch(a, 'alice', { nickname: 'Sevimli Panda' });
  await assertSucceeds(commit());
  await assertSucceeds(submitBatch(a, 'alice', { kind: 'bug', value: 1 }).commit());
  await assertSucceeds(getDocs(query(collection(a, 'feedback'), where('uid', '==', 'alice'))));
  await assertFails(getDoc(doc(db('bob'), 'feedback', ticket.id)));
  await assertFails(getDocs(query(collection(a, 'feedback'), orderBy('createdAt', 'desc'), limit(300))));
  await assertFails(updateDoc(ticket, { status: 'done' })); // durumu yalnızca geliştirici değiştirir
});

test('şikâyet: paylaşım ve yanıt için geçerli hedef; geçersiz hedef reddedilir (SupportRepository.report)', async () => {
  await seedUser('bob', { nickname: 'Cesur Kuş' });
  await seedUser(DEV, { nickname: 'Haven', profile: false });
  const b = db('bob');
  const text = 'Kırıcı veya küçümseyici — “alıntılanan içerik”';
  await assertSucceeds(submitBatch(b, 'bob', { kind: 'report', text, target: 'notes/n1', value: 4 }).commit());
  await assertSucceeds(submitBatch(b, 'bob', { kind: 'report', text, target: 'notes/n1/replies/AbC123xyz', value: 4 }).commit());
  await assertFails(submitBatch(b, 'bob', { kind: 'report', text, target: 'users/alice', value: 4 }).commit());
});

test('geliştirici: tüm talepleri görür, yanıtlar, şikâyet edilen paylaşımı ve yanıtı kaldırır', async () => {
  await seedUser('alice');
  await seedUser('bob', { nickname: 'Cesur Kuş' });
  await seedUser(DEV, { nickname: 'Haven', profile: false });
  await seedNote('n1', 'alice', { replyCount: 1 });
  await seedNote('n2', 'alice');
  await seed((d) => setDoc(doc(d, 'notes', 'n1', 'replies', 'r1'), { authorUid: 'alice', nickname: 'Sevimli Panda', avatar: 1, text: 'yanıt', lang: 'tr' }));
  const bobReport = submitBatch(db('bob'), 'bob', { kind: 'report', text: 'Spam veya reklam — “yanıt”', target: 'notes/n1/replies/r1', value: 4 });
  await bobReport.commit();
  const bobReport2 = submitBatch(db('bob'), 'bob', { kind: 'report', text: 'Spam veya reklam — “paylaşım”', target: 'notes/n2', value: 4 });
  await bobReport2.commit();

  const dv = db(DEV);
  await assertSucceeds(getDocs(query(collection(dv, 'feedback'), orderBy('createdAt', 'desc'), limit(300))));
  // markSeen
  await assertSucceeds(updateDoc(doc(dv, 'feedback', bobReport.ticket.id), { status: 'seen', updatedAt: serverTimestamp() }));
  // answer
  const ans = writeBatch(dv);
  ans.update(doc(dv, 'feedback', bobReport2.ticket.id), { status: 'planned', reply: 'İnceliyoruz, teşekkürler.', replyLang: 'tr', repliedAt: serverTimestamp(), updatedAt: serverTimestamp() });
  ans.set(doc(collection(dv, 'users', 'bob', 'inbox')), { type: 'feedback_reply', fromUid: DEV, fromNickname: 'Haven', value: 2, createdAt: serverTimestamp(), read: false });
  await assertSucceeds(ans.commit());
  // removeTarget: yanıt (+ sayaç -1) ve paylaşım
  for (const [ticket, target, isReply] of [[bobReport.ticket, 'notes/n1/replies/r1', true], [bobReport2.ticket, 'notes/n2', false]]) {
    const rm = writeBatch(dv);
    rm.delete(doc(dv, target));
    if (isReply) rm.update(doc(dv, 'notes', 'n1'), { replyCount: increment(-1) });
    rm.update(doc(dv, 'feedback', ticket.id), { status: 'done', updatedAt: serverTimestamp() });
    rm.set(doc(collection(dv, 'users', 'bob', 'inbox')), { type: 'feedback_reply', fromUid: DEV, fromNickname: 'Haven', value: 3, createdAt: serverTimestamp(), read: false });
    await assertSucceeds(rm.commit());
  }
  // Geliştirici olmayan biri başkasının paylaşımını silemez
  await seedNote('n3', 'alice');
  await assertFails(deleteDoc(doc(db('bob'), 'notes', 'n3')));
});

// ------------------------------------------------------------------ hesap silme

test('hesap silme: tüm kişisel veri ve topluluk izleri silinebilir (HavenRepository.deleteAllUserData)', async () => {
  await seedUser('alice');
  await seedUser('bob', { nickname: 'Cesur Kuş' });
  await seedNote('bobNote', 'bob', { replyCount: 1 });
  await seedNote('aliceNote', 'alice');
  await seed(async (d) => {
    await setDoc(doc(d, 'users', 'alice', 'friends', 'bob'), { since: 1 });
    await setDoc(doc(d, 'users', 'bob', 'friends', 'alice'), { since: 1 });
    await setDoc(doc(d, 'notes', 'bobNote', 'replies', 'ra'), { authorUid: 'alice', nickname: 'Sevimli Panda', avatar: 1, text: 'yanıt', lang: 'tr' });
    await setDoc(doc(d, 'notes', 'anonA'), { circleId: 'bfrb', text: 'anonim', supportCount: 0, reportCount: 0, anonymous: true, nickname: 'Anonim üye', avatar: -1, streak: 0 });
    await setDoc(doc(d, 'users', 'alice', 'myNotes', 'anonA'), { at: 1 });
    await setDoc(doc(d, 'feedback', 't1'), { uid: 'alice', kind: 'idea', text: 'bir öneri metni', status: 'open' });
    await setDoc(doc(d, 'users', 'alice', 'struggles', 'trichotillomania'), { active: true });
    await setDoc(doc(d, 'users', 'alice', 'checkins', '2026-11'), { days: {} });
    await setDoc(doc(d, 'users', 'alice', 'inbox', 'i1'), { type: 'login', read: false });
    await setDoc(doc(d, 'users', 'alice', 'journal', 'j1'), { text: 'not' });
  });
  const a = db('alice');
  await assertSucceeds(getDoc(doc(a, 'users', 'alice')));
  const friends = await assertSucceeds(getDocs(collection(a, 'users', 'alice', 'friends')));
  const unfriend = writeBatch(a);
  for (const f of friends.docs) {
    unfriend.delete(doc(a, 'users', f.id, 'friends', 'alice'));
    unfriend.delete(f.ref);
  }
  await assertSucceeds(unfriend.commit());
  const replies = await assertSucceeds(getDocs(query(collectionGroup(a, 'replies'), where('authorUid', '==', 'alice'))));
  for (const r of replies.docs) {
    const b = writeBatch(a);
    b.delete(r.ref);
    b.update(r.ref.parent.parent, { replyCount: increment(-1) });
    await assertSucceeds(b.commit());
  }
  const mine = await assertSucceeds(getDocs(collection(a, 'users', 'alice', 'myNotes')));
  for (const n of mine.docs) {
    const b = writeBatch(a);
    b.delete(doc(a, 'notes', n.id));
    b.delete(n.ref);
    await assertSucceeds(b.commit());
  }
  async function deleteAll(q) {
    const s = await assertSucceeds(getDocs(q));
    const b = writeBatch(a);
    s.docs.forEach((d) => b.delete(d.ref));
    await assertSucceeds(b.commit());
  }
  await deleteAll(query(collection(a, 'notes'), where('authorUid', '==', 'alice')));
  await deleteAll(query(collection(a, 'feedback'), where('uid', '==', 'alice')));
  for (const sub of ['struggles', 'checkins', 'inbox', 'journal']) await deleteAll(collection(a, 'users', 'alice', sub));
  await assertSucceeds(deleteDoc(doc(a, 'profiles', 'alice')));
  await assertSucceeds(deleteDoc(doc(a, 'users', 'alice')));
});
