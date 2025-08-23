/* eslint-disable no-console */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
const db = admin.firestore();

/**
 * Kullanıcı adı kontrolü (Cloud Function)
 * Yeni bir kullanıcı kaydı sırasında, kullanıcı adının kullanılabilir olup olmadığını kontrol eder.
 * @param {Object} data - İstemciden gelen veri
 * @param {string} data.username - Kontrol edilecek kullanıcı adı
 * @param {Object} _context - Cloud Functions bağlamı (kullanılmıyor)
 * @returns {Object} - Sonuç nesnesi { available: boolean, reason?: string }
 */
exports.checkUsernameAvailable = functions
  .region("us-central1")
  .https.onCall(async (data, _context) => {
    try {
      const raw = (data && data.username) ? String(data.username) : "";
      const username = raw.trim().toLowerCase();
      if (!username || username.length < 3 || username.length > 29) {
        return { available: false, reason: "invalid" };
      }
      const snap = await db
        .collection("users")
        .where("username_lowercase", "==", username)
        .limit(1)
        .get();
      return { available: snap.empty };
    } catch (e) {
      console.error("checkUsernameAvailable error:", e);
      throw new functions.https.HttpsError("internal", "check failed");
    }
  });

/* ----------------- DİĞER FONKSİYONLAR (değişmeden/ufak temizlikle) ----------------- */

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
