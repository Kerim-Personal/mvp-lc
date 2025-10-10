/* eslint-disable no-console */
const { functions, admin, db } = require('../shared');

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

