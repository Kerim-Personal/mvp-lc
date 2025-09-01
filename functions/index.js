/* eslint-disable no-console */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
const db = admin.firestore();

/**
 * Kullanıcı adı kontrolü (Cloud Function)
 * Yeni bir kullanıcı kaydı sırasında, kullanıcı adının kullanılabilir olup olmadığını kontrol eder.
 * Güvenlik sıkılaştırmaları:
 *  - Karakter seti kısıtlaması (^[a-z0-9_]{3,29}$)
 *  - Rezerve isim listesi
 *  - Tek seferde tek istek (sunucu tarafında ek rate limit yok fakat basit sunucu tarafı doğrulama)
 */
exports.checkUsernameAvailable = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    try {
      const raw = (data && data.username) ? String(data.username) : "";
      const username = raw.trim().toLowerCase();
      const ipOrUid = context.auth ? context.auth.uid : 'anon';
      if (!allowUsernameCheck(ipOrUid)) {
        return { available: false, reason: 'rate_limited' };
      }
      const RESERVED = new Set([
        'admin','administrator','root','support','moderator','mod','system','null','undefined','owner','staff','team','linguachat','lingua','api'
      ]);
      const VALID_RE = /^[a-z0-9_]{3,29}$/;

      if (!VALID_RE.test(username)) {
        return { available: false, reason: 'invalid_format' };
      }
      if (RESERVED.has(username)) {
        return { available: false, reason: 'reserved' };
      }

      // Önce usernames koleksiyonuna bak
      const unameDoc = await db.collection('usernames').doc(username).get();
      if (unameDoc.exists) return { available: false, reason: 'taken' };

      // Eski kullanıcı dokümanı taraması (geçiş süreci)
      const snap = await db
        .collection("users")
        .where("username_lowercase", "==", username)
        .limit(1)
        .get();
      return { available: snap.empty, reason: snap.empty ? 'ok' : 'taken_legacy' };
    } catch (e) {
      console.error("checkUsernameAvailable error:", e);
      throw new functions.https.HttpsError("internal", "check failed");
    }
  });
/** Kullanıcı adı rezerve etme (benzersizlik) */
exports.reserveUsername = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Giriş gerekli');
    }
    const raw = data && data.username ? String(data.username) : '';
    const username = raw.trim().toLowerCase();
    const RESERVED = new Set(['admin','administrator','root','support','moderator','mod','system','null','undefined','owner','staff','team','linguachat','lingua','api']);
    const VALID_RE = /^[a-z0-9_]{3,29}$/;
    if (!VALID_RE.test(username)) {
      throw new functions.https.HttpsError('invalid-argument','Geçersiz format');
    }
    if (RESERVED.has(username)) {
      throw new functions.https.HttpsError('already-exists','Rezerve isim');
    }
    const ref = db.collection('usernames').doc(username);
    try {
      await db.runTransaction(async tx => {
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

/**
 * Kullanıcı kaydı sonrası doğrulama kodu gönderimi
 * Yeni bir kullanıcı kaydı oluşturulduğunda, kullanıcının e-posta adresine doğrulama kodu gönderir.
 */
exports.sendVerificationCode = functions.auth.user().onCreate((user) => {
  const userEmail = user.email;
  const displayName = user.displayName || "User";
  if (!userEmail) return null;

  const gmailEmail = functions.config().gmail.email;
  const gmailPassword = functions.config().gmail.password;
  if (!gmailEmail || !gmailPassword) return null;

  const mailTransport = nodemailer.createTransport({
    service: "gmail",
    auth: { user: gmailEmail, pass: gmailPassword },
  });

  const mailOptions = {
    from: `"LinguaChat Team" <${gmailEmail}>`,
    to: userEmail,
    subject: "Welcome to LinguaChat!",
    html: `<h1>Welcome, ${displayName}!</h1><p>Your account is ready. Please verify your email to start your language learning adventure.</p>`,
  };

  return mailTransport.sendMail(mailOptions);
});

/**
 * Kullanıcı hesabı silme
 * Kullanıcı, hesabını sildiğinde bu fonksiyon tetiklenir.
 * Hesap silindikten sonra, kullanıcıya ait veriler "Silinmiş Kullanıcı" olarak güncellenir.
 */
exports.deleteUserAccount = functions
  .region("us-central1")
  .https.onCall(async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Bu işlemi gerçekleştirmek için kimlik doğrulaması gereklidir."
      );
    }
    const uid = context.auth.uid;
    try {
      const userRef = db.collection("users").doc(uid);
      await userRef.update({
        displayName: "Silinmiş Kullanıcı",
        email: `${uid}@deleted.lingua.chat`,
        avatarUrl: "",
        status: "deleted",
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      await admin.auth().deleteUser(uid);
      return { success: true };
    } catch (error) {
      throw new functions.https.HttpsError(
        "internal",
        "Hesap silinirken bir sunucu hatası oluştu."
      );
    }
  });

/**
 * Gönderi oluşturulduğunda tetiklenen fonksiyon
 * Yeni bir gönderi oluşturulduğunda, gönderinin ait olduğu kullanıcı belgesine gönderi kimliğini ekler.
 */
exports.onPostCreated = functions.firestore
  .document("posts/{postId}")
  .onCreate(async (snap, context) => {
    const postData = snap.data();
    const userId = postData.userId;
    const postId = context.params.postId;
    if (!userId) return null;
    const userRef = db.collection("users").doc(userId);
    try {
      await userRef.update({
        posts: admin.firestore.FieldValue.arrayUnion(postId),
      });
      return null;
    } catch (_e) {
      return null;
    }
  });

/**
 * Gönderi silindiğinde tetiklenen fonksiyon
 * Bir gönderi silindiğinde, gönderinin ait olduğu kullanıcı belgesinden gönderi kimliğini kaldırır.
 */
exports.onPostDeleted = functions.firestore
  .document("posts/{postId}")
  .onDelete(async (snap, context) => {
    const postData = snap.data();
    const userId = postData.userId;
    const postId = context.params.postId;
    if (!userId) return null;
    const userRef = db.collection("users").doc(userId);
    try {
      await userRef.update({
        posts: admin.firestore.FieldValue.arrayRemove(postId),
      });
      return null;
    } catch (_e) {
      return null;
    }
  });
/**
 * Oda üyesi eklendiğinde: memberCount artır, avatarsPreview güncelle (ilk 3 avatar)
 */
exports.onGroupMemberAdded = functions.firestore
  .document('group_chats/{roomId}/members/{memberId}')
  .onCreate(async (snap, context) => {
    const roomId = context.params.roomId;
    const memberData = snap.data() || {};
    const avatarUrl = memberData.avatarUrl || null;
    const roomRef = db.collection('group_chats').doc(roomId);

    await db.runTransaction(async (tx) => {
      const roomDoc = await tx.get(roomRef);
      const current = roomDoc.exists ? roomDoc.data() : {};
      const currentCount = current.memberCount || 0;
      const avatarsPreview = Array.isArray(current.avatarsPreview) ? current.avatarsPreview.slice(0, 3) : [];
      if (avatarUrl && !avatarsPreview.includes(avatarUrl) && avatarsPreview.length < 3) {
        avatarsPreview.push(avatarUrl);
      }
      tx.set(roomRef, {
        memberCount: currentCount + 1,
        avatarsPreview,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });
    return null;
  });

/**
 * Oda üyesi silindiğinde: memberCount azalt, gerekirse avatarsPreview yeniden oluştur
 */
exports.onGroupMemberRemoved = functions.firestore
  .document('group_chats/{roomId}/members/{memberId}')
  .onDelete(async (snap, context) => {
    const roomId = context.params.roomId;
    const removedData = snap.data() || {};
    const removedAvatar = removedData.avatarUrl || null;
    const roomRef = db.collection('group_chats').doc(roomId);

    await db.runTransaction(async (tx) => {
      const roomDoc = await tx.get(roomRef);
      const current = roomDoc.exists ? roomDoc.data() : {};
      const currentCount = current.memberCount || 0;
      let avatarsPreview = Array.isArray(current.avatarsPreview) ? current.avatarsPreview.slice(0, 3) : [];

      const needsRebuild = removedAvatar && avatarsPreview.includes(removedAvatar);
      if (needsRebuild) {
        // İlk 3 üyeyi tekrar oku (en az okuma için limit 3)
        const membersSnap = await db.collection('group_chats').doc(roomId).collection('members').limit(3).get();
        avatarsPreview = [];
        membersSnap.forEach(d => {
          const data = d.data();
            if (data.avatarUrl) avatarsPreview.push(data.avatarUrl);
        });
      }
      tx.set(roomRef, {
        memberCount: Math.max(0, currentCount - 1),
        avatarsPreview,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });
    return null;
  });
/** Yeni sohbet odası oluşturulduğunda partnerCount artırma PASİF (artık ilk mesajda sayıyoruz) */
exports.onChatCreated = functions.firestore
  .document('chats/{chatId}')
  .onCreate(async (_snap, _context) => {
    return null; // partnerCount artışı ilk mesajda yapılacak
  });
/** Bir sohbette ilk mesaj atıldığında her iki kullanıcının partnerCount değerini +1 artır */
exports.onChatMessageCreated = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (_msgSnap, context) => {
    const chatId = context.params.chatId;
    const chatRef = db.collection('chats').doc(chatId);
    try {
      await db.runTransaction(async (tx) => {
        const chatDoc = await tx.get(chatRef);
        if (!chatDoc.exists) return;
        const chat = chatDoc.data() || {};
        if (chat.counted === true) return; // zaten sayılmış
        const users = Array.isArray(chat.users) ? chat.users : [];
        if (users.length !== 2) return;
        users.forEach((uid) => {
          const uref = db.collection('users').doc(uid);
          tx.update(uref, { partnerCount: admin.firestore.FieldValue.increment(1) });
        });
        tx.set(chatRef, { counted: true }, { merge: true });
      });
    } catch (e) {
      console.error('onChatMessageCreated partnerCount increment error:', e);
    }
    return null;
  });
/** Rapor oluşturulduğunda içerik bazlı rapor sayacını artır */
exports.onReportCreated = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snap, context) => {
    try {
      const data = snap.data() || {};
      const contentId = data.reportedContentId;
      if (!contentId) return null; // içerik id yoksa sayma
      const contentType = data.reportedContentType || null;
      const parentId = data.reportedContentParentId || null;
      const reportedUserId = data.reportedUserId || null;
      const aggRef = db.collection('content_reports').doc(contentId);
      let newCount = 1;
      await db.runTransaction(async (tx) => {
        const doc = await tx.get(aggRef);
        if (!doc.exists) {
          tx.set(aggRef, {
            count: 1,
            contentType,
            parentId,
            reportedUserId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            lastReportAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          newCount = 1;
        } else {
          const current = doc.data() || {};
            const updated = (current.count || 0) + 1;
          newCount = updated;
          tx.update(aggRef, {
            count: updated,
            contentType: contentType || current.contentType || null,
            parentId: parentId || current.parentId || null,
            reportedUserId: reportedUserId || current.reportedUserId || null,
            lastReportAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      });
      // Rapor dokümanına aggregateCount alanını ekle
      await snap.ref.set({ aggregateCount: newCount }, { merge: true });
    } catch (e) {
      console.error('onReportCreated aggregation error:', e);
    }
    return null;
  });
/** Rapor oluşturma (rate limit + doğrulama) */
exports.createReport = functions
  .region('us-central1')
  .https.onCall( async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated','Giriş gerekli');
    const uid = context.auth.uid;
    const now = Date.now();
    const MIN_INTERVAL_MS = 15 * 1000; // iki rapor arası min 15 sn
    const WINDOW_MS = 60 * 60 * 1000; // 1 saat
    const WINDOW_LIMIT = 20; // saatlik max 20 rapor

    function takeString(key, maxLen, required=true) {
      const v = data[key];
      if ((v == null || v === '') && !required) return '';
      if (typeof v !== 'string') throw new functions.https.HttpsError('invalid-argument', key + ' string değil');
      if (v.length > maxLen) throw new functions.https.HttpsError('invalid-argument', key + ' çok uzun');
      return v.trim();
    }
    const reportedUserId = takeString('reportedUserId', 128);
    const reason = takeString('reason', 120);
    const details = takeString('details', 2000, false);
    const reportedContent = takeString('reportedContent', 4000, false);
    const reportedContentId = takeString('reportedContentId', 256, false);
    const reportedContentType = takeString('reportedContentType', 64, false);
    const reportedContentParentId = takeString('reportedContentParentId', 256, false);

    const rlRef = db.collection('rate_limits').doc('reports_' + uid);
    try {
      await db.runTransaction(async tx => {
        const rlSnap = await tx.get(rlRef);
        let lastAt = 0;
        let windowStart = now;
        let count = 0;
        if (rlSnap.exists) {
          const d = rlSnap.data() || {};
          lastAt = d.lastAt || 0;
          windowStart = d.windowStart || now;
          count = d.count || 0;
          if (now - windowStart > WINDOW_MS) {
            windowStart = now;
            count = 0;
          }
          if (now - lastAt < MIN_INTERVAL_MS) {
            throw new functions.https.HttpsError('resource-exhausted','Çok hızlı raporlama (bekleyin)');
          }
          if (count >= WINDOW_LIMIT) {
            throw new functions.https.HttpsError('resource-exhausted','Saatlik rapor limiti aşıldı');
          }
        }
        count += 1;
        tx.set(rlRef, { lastAt: now, windowStart, count }, { merge: true });
      });

      let docId = undefined;
      if (reportedContentId) docId = uid + '_' + reportedContentId;
      const reportsCol = db.collection('reports');
      if (docId) {
        const exist = await reportsCol.doc(docId).get();
        if (exist.exists) {
          throw new functions.https.HttpsError('already-exists','Bu içeriği zaten raporladınız');
        }
      }
      const baseData = {
        reporterId: uid,
        reportedUserId,
        reason,
        details: details || null,
        reportedContent: reportedContent || null,
        reportedContentId: reportedContentId || null,
        reportedContentType: reportedContentType || null,
        reportedContentParentId: reportedContentParentId || null,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        status: 'pending',
        serverAuth: true
      };
      if (docId) {
        await reportsCol.doc(docId).set(baseData, { merge: false });
      } else {
        await reportsCol.add(baseData);
      }
      return { success: true };
    } catch (e) {
      if (e instanceof functions.https.HttpsError) throw e;
      console.error('createReport error', e);
      throw new functions.https.HttpsError('internal','Rapor hatası');
    }
  });
