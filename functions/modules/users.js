/* eslint-disable no-console */
const { functions, admin, db } = require('../shared');

// --- Public projection helper ---
function toPublicUser(data) {
  if (!data) return null;
  return {
    // Kimlik
    displayName: data.displayName || null,
    username_lowercase: data.username_lowercase || null,
    avatarUrl: data.avatarUrl || null,
    // Rol ve durum (hassas değil)
    role: data.role || 'user',
    status: data.status || 'active',
    // Öğrenim bilgileri (hassas olmayan)
    nativeLanguage: data.nativeLanguage || null,
    learningLanguage: data.learningLanguage || null,
    learningLanguageLevel: data.learningLanguageLevel || null,
    level: data.level || null,
    // Gamification/istatistikler (hassas token/email vs yok)
    streak: typeof data.streak === 'number' ? data.streak : 0,
    highestStreak: typeof data.highestStreak === 'number' ? data.highestStreak : 0,
    totalRoomTime: typeof data.totalRoomTime === 'number' ? data.totalRoomTime : 0,
    // Premium rozeti herkese açık olabilir; istemiyorsanız kaldırabilirsiniz
    isPremium: data.isPremium === true,
    // Oluşturulma tarihi (opsiyonel)
    createdAt: data.createdAt || null,
    // Güvenlik: email, fcmTokens, birthDate, emailVerified, lastActivityDate dahil edilmez
  };
}

// users -> publicUsers senkronizasyonu
exports.onUserWritePublicProjection = functions
  .region('us-central1')
  .firestore.document('users/{userId}')
  .onWrite(async (change, context) => {
    const { userId } = context.params;
    const publicRef = db.collection('publicUsers').doc(userId);

    if (!change.after.exists) {
      // Silinmiş: publicUsers da sil
      await publicRef.delete().catch((e) => console.error('publicUsers delete error:', e));
      return null;
    }

    const afterData = change.after.data();
    const pub = toPublicUser(afterData);
    try {
      await publicRef.set(pub, { merge: true });
    } catch (e) {
      console.error('publicUsers set error:', e);
    }
    return null;
  });

exports.deleteUserAccount = functions
  .region('us-central1')
  .https.onCall(async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Bu işlemi gerçekleştirmek için kimlik doğrulaması gereklidir.',
      );
    }
    const uid = context.auth.uid;
    const userRef = db.collection('users').doc(uid);
    try {
      // 1) Rezerve kullanıcı adlarını serbest bırak
      try {
        const usernamesSnap = await db.collection('usernames').where('uid', '==', uid).get();
        if (!usernamesSnap.empty) {
          const batchArray = [];
          let batch = db.batch();
          let opCount = 0;
          usernamesSnap.forEach((doc) => {
            batch.delete(doc.ref);
            opCount++;
            if (opCount === 450) {
              batchArray.push(batch.commit());
              batch = db.batch();
              opCount = 0;
            }
          });
          if (opCount > 0) batchArray.push(batch.commit());
          await Promise.all(batchArray);
        }
      } catch (cleanupErr) {
        console.error('username cleanup failed:', cleanupErr);
      }

      // 2) Kullanıcı alt koleksiyonlarını temizle
      try {
        const subCollections = await userRef.listCollections();
        for (const col of subCollections) {
          const colSnap = await col.get();
          if (colSnap.empty) continue;
          const deletions = [];
          let batch = db.batch();
          let count = 0;
          for (const doc of colSnap.docs) {
            batch.delete(doc.ref);
            count++;
            if (count === 450) {
              deletions.push(batch.commit());
              batch = db.batch();
              count = 0;
            }
          }
          if (count > 0) deletions.push(batch.commit());
          if (deletions.length) await Promise.all(deletions);
        }
      } catch (subErr) {
        console.error('subcollection cleanup failed:', subErr);
      }

      // 3) Kullanıcı dokümanını sil
      try {
        await userRef.delete();
      } catch (docDelErr) {
        console.error('user doc delete failed:', docDelErr);
      }

      // 3b) publicUsers dokümanını sil
      try {
        await db.collection('publicUsers').doc(uid).delete();
      } catch (pubErr) {
        console.error('public user doc delete failed:', pubErr);
      }

      // 4) Auth kullanıcısını sil
      try {
        await admin.auth().deleteUser(uid);
      } catch (authErr) {
        console.error('auth user delete failed:', authErr);
        throw new functions.https.HttpsError('internal', 'Auth kullanıcı silinemedi.');
      }

      return { success: true, hardDeleted: true };
    } catch (error) {
      console.error('deleteUserAccount hard delete error:', error);
      throw new functions.https.HttpsError('internal', 'Hesap silinirken bir sunucu hatası oluştu.');
    }
  });

exports.backfillPublicUsers = functions
  .region('us-central1')
  .https.onCall(async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Kimlik doğrulaması gerekli');
    }
    const callerUid = context.auth.uid;
    // Sadece admin/moderator
    try {
      const callerSnap = await db.collection('users').doc(callerUid).get();
      const role = (callerSnap.exists && callerSnap.get('role')) || 'user';
      if (role !== 'admin' && role !== 'moderator') {
        throw new functions.https.HttpsError('permission-denied', 'Yetki yok');
      }
    } catch (e) {
      if (e instanceof functions.https.HttpsError) throw e;
      console.error('role check failed', e);
      throw new functions.https.HttpsError('internal', 'Rol doğrulanamadı');
    }

    let lastDoc = null;
    let total = 0;
    while (true) {
      let q = db.collection('users').orderBy(admin.firestore.FieldPath.documentId()).limit(500);
      if (lastDoc) q = q.startAfter(lastDoc.id);
      const snap = await q.get();
      if (snap.empty) break;
      const batch = db.batch();
      for (const doc of snap.docs) {
        const pub = toPublicUser(doc.data());
        batch.set(db.collection('publicUsers').doc(doc.id), pub, { merge: true });
        total++;
      }
      await batch.commit();
      lastDoc = snap.docs[snap.docs.length - 1];
      if (snap.size < 500) break;
    }
    return { success: true, count: total };
  });
