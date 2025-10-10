/* eslint-disable no-console */
const { functions, admin, db } = require('../shared');

// Basit process içi rate limit (geçici, cold start resetlenir)
const usernameCheckHits = {};

function allowUsernameCheck(identifier) {
  const now = Date.now();
  const windowMs = 60 * 1000; // 1 dk
  const limit = 30; // dk başına 30
  if (!usernameCheckHits[identifier]) usernameCheckHits[identifier] = [];
  const arr = usernameCheckHits[identifier];
  while (arr.length && now - arr[0] > windowMs) arr.shift();
  if (arr.length >= limit) return false;
  arr.push(now);
  return true;
}

exports.checkUsernameAvailable = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    try {
      const raw = (data && data.username) ? String(data.username) : '';
      const username = raw.trim().toLowerCase();
      const ipOrUid = context.auth ? context.auth.uid : 'anon';
      if (!allowUsernameCheck(ipOrUid)) {
        return { available: false, reason: 'rate_limited' };
      }
      const RESERVED = new Set([
        'admin','root','support','moderator','mod','system','null','undefined','owner','staff','team','vocachat','voca','api'
      ]);
      const VALID_RE = /^[a-z0-9_]{3,29}$/;
      if (!VALID_RE.test(username)) return { available: false, reason: 'invalid_format' };
      if (RESERVED.has(username)) return { available: false, reason: 'reserved' };

      const unameDoc = await db.collection('usernames').doc(username).get();
      if (unameDoc.exists) return { available: false, reason: 'taken' };

      const snap = await db.collection('users').where('username_lowercase','==', username).limit(1).get();
      const reason = snap.empty ? 'ok' : 'taken_legacy';
      return { available: snap.empty, reason };
    } catch (e) {
      console.error('checkUsernameAvailable error:', e);
      throw new functions.https.HttpsError('internal','check failed');
    }
  });

exports.reserveUsername = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated','Giriş gerekli');
    }
    const raw = data && data.username ? String(data.username) : '';
    const username = raw.trim().toLowerCase();
    const RESERVED = new Set([
      'admin','root','support','moderator','mod','system','null','undefined','owner','staff','team','vocachat','voca','api'
    ]);
    const VALID_RE = /^[a-z0-9_]{3,29}$/;
    if (!VALID_RE.test(username)) {
      throw new functions.https.HttpsError('invalid-argument','Geçersiz format');
    }
    if (RESERVED.has(username)) {
      throw new functions.https.HttpsError('already-exists','Rezerve isim');
    }
    const ref = db.collection('usernames').doc(username);
    try {
      await db.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        if (snap.exists) {
          throw new functions.https.HttpsError('already-exists','Alınmış');
        }
        tx.set(ref, { uid: context.auth.uid, createdAt: admin.firestore.FieldValue.serverTimestamp() });
      });
      return { reserved: true };
    } catch (e) {
      if (e instanceof functions.https.HttpsError) throw e;
      console.error('reserveUsername error', e);
      throw new functions.https.HttpsError('internal','Rezervasyon hatası');
    }
  });

exports.changeUsername = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Giriş gerekli');
    }
    const raw = data && data.username ? String(data.username) : '';
    let originalUsername = raw.trim();
    originalUsername = originalUsername.replace(/\s+/g, '');
    const usernameLower = originalUsername.toLowerCase();

    const RESERVED = new Set([
      'admin','root','support','moderator','mod','system','null','undefined','owner','staff','team','vocachat','voca','api'
    ]);
    const VALID_RE = /^[A-Za-z0-9_]{3,29}$/;
    if (!VALID_RE.test(originalUsername)) {
      throw new functions.https.HttpsError('invalid-argument','Geçersiz format');
    }
    if (RESERVED.has(usernameLower)) {
      throw new functions.https.HttpsError('already-exists','Rezerve isim');
    }

    const uid = context.auth.uid;
    const userRef = db.collection('users').doc(uid);
    const newRef = db.collection('usernames').doc(usernameLower);
    const prevSnap = await db.collection('usernames').where('uid','==', uid).get();

    try {
      await db.runTransaction(async (tx) => {
        const taken = await tx.get(newRef);
        if (taken.exists) {
          const owner = (taken.data() && taken.data().uid) || null;
          if (owner !== uid) {
            throw new functions.https.HttpsError('already-exists','Alınmış');
          }
        }
        tx.set(newRef, { uid, createdAt: admin.firestore.FieldValue.serverTimestamp() });
        prevSnap.forEach((doc) => { if (doc.id !== usernameLower) tx.delete(doc.ref); });
        tx.set(userRef, {
          displayName: originalUsername,
          username_lowercase: usernameLower,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      });
      return { success: true };
    } catch (e) {
      if (e instanceof functions.https.HttpsError) throw e;
      console.error('changeUsername error', e);
      throw new functions.https.HttpsError('internal','Kullanıcı adı değiştirilemedi');
    }
  });

