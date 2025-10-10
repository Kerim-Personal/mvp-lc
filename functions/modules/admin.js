/* eslint-disable no-console */
const { functions, admin, db } = require('../shared');

exports.sendAdminNotification = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Auth gerekli');
    }
    const uid = context.auth.uid;
    try {
      const userDoc = await db.collection('users').doc(uid).get();
      const role = (userDoc.data() && userDoc.data().role) || userDoc.get('role') || 'user';
      if (role !== 'admin') {
        throw new functions.https.HttpsError('permission-denied', 'Sadece admin');
      }
    } catch (e) {
      if (e instanceof functions.https.HttpsError) throw e;
      throw new functions.https.HttpsError('internal', 'Rol doğrulanamadı');
    }

    function take(key, maxLen) {
      const v = data && data[key];
      if (!v || typeof v !== 'string') return '';
      const trimmed = v.trim();
      if (trimmed.length > maxLen) return trimmed.slice(0, maxLen);
      return trimmed;
    }

    const title = take('title', 100);
    const body = take('body', 500);
    const segment = take('segment', 40) || 'all';
    const targetUid = take('targetUid', 200);
    const targetRoute = take('targetRoute', 120);
    if (!title || !body) {
      throw new functions.https.HttpsError('invalid-argument', 'Başlık ve içerik zorunlu');
    }

    let userQuery = db.collection('users').where('status', '==', 'active');
    if (segment === 'premium') {
      userQuery = userQuery.where('isPremium', '==', true);
    } else if (segment === 'non_premium') {
      userQuery = userQuery.where('isPremium', '==', false);
    } else if (segment === 'user' && targetUid) {
      userQuery = db.collection('users').where(admin.firestore.FieldPath.documentId(), '==', targetUid);
    }

    const tokens = [];
    const snap = await userQuery.select('fcmTokens').get();
    const tokenUserMap = {};
    const userTokensMap = {};

    snap.forEach((d) => {
      const t = d.get('fcmTokens');
      if (Array.isArray(t)) {
        const validList = [];
        t.forEach((v) => {
          if (typeof v === 'string' && v.length > 20) {
            tokens.push(v);
            if (!tokenUserMap[v]) tokenUserMap[v] = d.id;
            validList.push(v);
          }
        });
        userTokensMap[d.id] = validList;
      } else {
        userTokensMap[d.id] = [];
      }
    });

    if (!tokens.length) {
      return { success: true, sent: 0, failed: 0, totalTokens: 0, removedInvalid: 0 };
    }

    const messaging = admin.messaging();
    const BATCH = 500;
    let sentCount = 0;
    let failCount = 0;
    const invalidCodes = new Set([
      'messaging/registration-token-not-registered',
      'messaging/invalid-registration-token',
      'messaging/invalid-argument',
    ]);
    const invalidByUser = {};

    for (let i = 0; i < tokens.length; i += BATCH) {
      const slice = tokens.slice(i, i + BATCH);
      const res = await messaging.sendEachForMulticast({
        tokens: slice,
        notification: { title, body },
        data: {
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          segment,
          kind: 'admin_broadcast',
          targetRoute: targetRoute || '',
        },
      });
      sentCount += res.successCount;
      failCount += res.failureCount;

      if (Array.isArray(res.responses)) {
        res.responses.forEach((r, idx) => {
          if (!r.success && r.error && invalidCodes.has(r.error.code)) {
            const badToken = slice[idx];
            const owner = tokenUserMap[badToken];
            if (owner) {
              if (!invalidByUser[owner]) invalidByUser[owner] = new Set();
              invalidByUser[owner].add(badToken);
            }
          }
        });
      }
    }

    let removedInvalidCount = 0;
    const invalidUserIds = Object.keys(invalidByUser);
    if (invalidUserIds.length) {
      const batch = db.batch();
      invalidUserIds.forEach((uid2) => {
        const toRemoveSet = invalidByUser[uid2];
        const original = userTokensMap[uid2] || [];
        const filtered = original.filter((t) => !toRemoveSet.has(t));
        removedInvalidCount += original.length - filtered.length;
        batch.update(db.collection('users').doc(uid2), { fcmTokens: filtered });
      });
      try { await batch.commit(); } catch (_) { /* noop */ }
    }

    try {
      await db.collection('admin_notifications_log').add({
        title, body, segment,
        targetUid: segment === 'user' ? targetUid : null,
        targetRoute: targetRoute || null,
        sent: sentCount,
        failed: failCount,
        totalTokens: tokens.length,
        removedInvalid: removedInvalidCount,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: uid,
      });
    } catch (_) { /* Non-critical */ }

    return {
      success: true,
      sent: sentCount,
      failed: failCount,
      totalTokens: tokens.length,
      removedInvalid: removedInvalidCount,
    };
  });

exports.setAdminClaim = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    if (context.auth.token.admin !== true) {
      throw new functions.https.HttpsError('permission-denied', 'Only admins can set other admins.');
    }
    const targetUid = data.uid;
    if (!targetUid || typeof targetUid !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', "The function must be called with a 'uid' argument.");
    }
    try {
      await admin.auth().setCustomUserClaims(targetUid, { admin: true });
      await db.collection('users').doc(targetUid).set({ role: 'admin' }, { merge: true });
      return { message: `Success! ${targetUid} has been made an admin.` };
    } catch (error) {
      console.error('Error setting admin claim:', error);
      throw new functions.https.HttpsError('internal', 'An error occurred while setting the admin claim.');
    }
  });

