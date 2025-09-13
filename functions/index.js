/* eslint-disable no-console */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
const db = admin.firestore();

/**
 * Kullanıcı adı kontrolü (Cloud Function)
 * Yeni bir kullanıcı kaydı sırasında, kullanıcı adının kullanılabilir olup
 * olmadığını kontrol eder.
 * Güvenlik sıkılaştırmaları:
 *  - Karakter seti kısıtlaması (^[a-z0-9_]{3,29}$)
 *  - Rezerve isim listesi
 *  - Tek seferde tek istek (basit sunucu tarafı doğrulama)
 */
exports.checkUsernameAvailable = functions
    .region("us-central1")
    .https.onCall(async (data, context) => {
      try {
        const raw = (data && data.username) ? String(data.username) : "";
        const username = raw.trim().toLowerCase();
        const ipOrUid = context.auth ? context.auth.uid : "anon";
        if (!allowUsernameCheck(ipOrUid)) {
          return {available: false, reason: "rate_limited"};
        }
        const RESERVED = new Set([
          "admin", "administrator", "root", "support", "moderator", "mod",
          "system", "null", "undefined", "owner", "staff", "team",
          "linguachat", "lingua", "api",
        ]);
        const VALID_RE = /^[a-z0-9_]{3,29}$/;

        if (!VALID_RE.test(username)) {
          return {available: false, reason: "invalid_format"};
        }
        if (RESERVED.has(username)) {
          return {available: false, reason: "reserved"};
        }

        // Önce usernames koleksiyonuna bak
        const unameDoc = await db.collection("usernames").doc(username).get();
        if (unameDoc.exists) return {available: false, reason: "taken"};

        // Eski kullanıcı dokümanı taraması (geçiş süreci)
        const snap = await db
            .collection("users")
            .where("username_lowercase", "==", username)
            .limit(1)
            .get();
        const reason = snap.empty ? "ok" : "taken_legacy";
        return {available: snap.empty, reason: reason};
      } catch (e) {
        console.error("checkUsernameAvailable error:", e);
        throw new functions.https.HttpsError("internal", "check failed");
      }
    });
/** Kullanıcı adı rezerve etme (benzersizlik) */
exports.reserveUsername = functions
    .region("us-central1")
    .https.onCall(async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Giriş gerekli");
      }
      const raw = data && data.username ? String(data.username) : "";
      const username = raw.trim().toLowerCase();
      const RESERVED = new Set([
        "admin", "administrator", "root", "support", "moderator", "mod",
        "system", "null", "undefined", "owner", "staff", "team",
        "linguachat", "lingua", "api",
      ]);
      const VALID_RE = /^[a-z0-9_]{3,29}$/;
      if (!VALID_RE.test(username)) {
        throw new functions.https.HttpsError("invalid-argument",
            "Geçersiz format");
      }
      if (RESERVED.has(username)) {
        throw new functions.https.HttpsError("already-exists", "Rezerve isim");
      }
      const ref = db.collection("usernames").doc(username);
      try {
        await db.runTransaction(async (tx) => {
          const snap = await tx.get(ref);
          if (snap.exists) {
            throw new functions.https.HttpsError("already-exists", "Alınmış");
          }
          tx.set(ref, {
            uid: context.auth.uid,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });
        return {reserved: true};
      } catch (e) {
        if (e instanceof functions.https.HttpsError) throw e;
        console.error("reserveUsername error", e);
        throw new functions.https.HttpsError("internal", "Rezervasyon hatası");
      }
    });

/**
 * Basit process içi rate limit (geçici, cold start resetlenir)
 * @param {string} identifier Benzersiz bir kullanıcı veya IP tanımlayıcısı.
 * @return {boolean} İsteğe izin verilip verilmediğini döndürür.
 */
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

// Basit process içi rate limit (geçici, cold start resetlenir)
const usernameCheckHits = {};


/**
 * Kullanıcı kaydı sonrası doğrulama kodu gönderimi
 * Yeni bir kullanıcı kaydı oluşturulduğunda, kullanıcının e-posta adresine
 * doğrulama kodu gönderir.
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
    auth: {user: gmailEmail, pass: gmailPassword},
  });

  const mailOptions = {
    from: `"LinguaChat Team" <${gmailEmail}>`,
    to: userEmail,
    subject: "Welcome to LinguaChat!",
    html: `<h1>Welcome, ${displayName}!</h1><p>Your account is ready. ` +
          `Please verify your email to start your language learning adventure.</p>`,
  };

  return mailTransport.sendMail(mailOptions);
});

/**
 * Kullanıcı hesabı silme
 * Kullanıcı, hesabını sildiğinde bu fonksiyon tetiklenir.
 * Hesap silindikten sonra, kullanıcıya ait veriler "Silinmiş Kullanıcı"
 * olarak güncellenir.
 */
exports.deleteUserAccount = functions
    .region("us-central1")
    .https.onCall(async (_data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Bu işlemi gerçekleştirmek için kimlik doğrulaması gereklidir.",
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
        return {success: true};
      } catch (error) {
        throw new functions.https.HttpsError(
            "internal",
            "Hesap silinirken bir sunucu hatası oluştu.",
        );
      }
    });

/**
 * Gönderi oluşturulduğunda tetiklenen fonksiyon
 * Yeni bir gönderi oluşturulduğunda, gönderinin ait olduğu kullanıcı
 * belgesine gönderi kimliğini ekler.
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
 * Bir gönderi silindiğinde, gönderinin ait olduğu kullanıcı belgesinden
 * gönderi kimliğini kaldırır.
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
 * Oda üyesi eklendiğinde: memberCount artır, avatarsPreview güncelle
 * (ilk 3 avatar)
 */
exports.onGroupMemberAdded = functions.firestore
    .document("group_chats/{roomId}/members/{memberId}")
    .onCreate(async (snap, context) => {
      const roomId = context.params.roomId;
      const memberData = snap.data() || {};
      const avatarUrl = memberData.avatarUrl || null;
      const roomRef = db.collection("group_chats").doc(roomId);

      await db.runTransaction(async (tx) => {
        const roomDoc = await tx.get(roomRef);
        const current = roomDoc.exists ? roomDoc.data() : {};
        const currentCount = current.memberCount || 0;
        const avPreview = Array.isArray(current.avatarsPreview) ?
          current.avatarsPreview.slice(0, 3) : [];
        if (avatarUrl && !avPreview.includes(avatarUrl) &&
            avPreview.length < 3) {
          avPreview.push(avatarUrl);
        }
        tx.set(roomRef, {
          memberCount: currentCount + 1,
          avatarsPreview: avPreview,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
      });
      return null;
    });

/**
 * Oda üyesi silindiğinde: memberCount azalt, gerekirse avatarsPreview
 * yeniden oluştur
 */
exports.onGroupMemberRemoved = functions.firestore
    .document("group_chats/{roomId}/members/{memberId}")
    .onDelete(async (snap, context) => {
      const roomId = context.params.roomId;
      const removedData = snap.data() || {};
      const removedAvatar = removedData.avatarUrl || null;
      const roomRef = db.collection("group_chats").doc(roomId);

      await db.runTransaction(async (tx) => {
        const roomDoc = await tx.get(roomRef);
        const current = roomDoc.exists ? roomDoc.data() : {};
        const currentCount = current.memberCount || 0;
        let avPreview = Array.isArray(current.avatarsPreview) ?
          current.avatarsPreview.slice(0, 3) : [];

        const needsRebuild = removedAvatar &&
          avPreview.includes(removedAvatar);
        if (needsRebuild) {
        // İlk 3 üyeyi tekrar oku (en az okuma için limit 3)
          const membersSnap = await db.collection("group_chats").doc(roomId)
              .collection("members").limit(3).get();
          avPreview = [];
          membersSnap.forEach((d) => {
            const data = d.data();
            if (data.avatarUrl) avPreview.push(data.avatarUrl);
          });
        }
        tx.set(roomRef, {
          memberCount: Math.max(0, currentCount - 1),
          avatarsPreview: avPreview,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
      });
      return null;
    });
/**
 * Yeni sohbet odası oluşturulduğunda partnerCount artırma PASİF
 * (artık ilk mesajda sayıyoruz)
 */
exports.onChatCreated = functions.firestore
    .document("chats/{chatId}")
    .onCreate(async (_snap, _context) => {
      return null; // partnerCount artışı ilk mesajda yapılacak
    });
/**
 * Bir sohbette ilk mesaj atıldığında her iki kullanıcının
 * partnerCount değerini +1 artır
 */
exports.onChatMessageCreated = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onCreate(async (_msgSnap, context) => {
      const chatId = context.params.chatId;
      const chatRef = db.collection("chats").doc(chatId);
      try {
        await db.runTransaction(async (tx) => {
          const chatDoc = await tx.get(chatRef);
          if (!chatDoc.exists) return;
          const chat = chatDoc.data() || {};
          if (chat.counted === true) return; // zaten sayılmış
          const users = Array.isArray(chat.users) ? chat.users : [];
          if (users.length !== 2) return;
          users.forEach((uid) => {
            const uref = db.collection("users").doc(uid);
            tx.update(uref, {
              partnerCount: admin.firestore.FieldValue.increment(1),
            });
          });
          tx.set(chatRef, {counted: true}, {merge: true});
        });
      } catch (e) {
        console.error("onChatMessageCreated partnerCount increment error:", e);
      }
      return null;
    });
/** Rapor oluşturulduğunda içerik bazlı rapor sayacını artır */
exports.onReportCreated = functions.firestore
    .document("reports/{reportId}")
    .onCreate(async (snap, context) => {
      try {
        const data = snap.data() || {};
        const contentId = data.reportedContentId;
        if (!contentId) return null; // içerik id yoksa sayma
        const contentType = data.reportedContentType || null;
        const parentId = data.reportedContentParentId || null;
        const reportedUserId = data.reportedUserId || null;
        const aggRef = db.collection("content_reports").doc(contentId);
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
        await snap.ref.set({aggregateCount: newCount}, {merge: true});
      } catch (e) {
        console.error("onReportCreated aggregation error:", e);
      }
      return null;
    });
/** Rapor oluşturma (rate limit + doğrulama) */
exports.createReport = functions
    .region("us-central1")
    .https.onCall( async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Giriş gerekli");
      }
      const uid = context.auth.uid;
      const now = Date.now();
      const MIN_INTERVAL_MS = 15 * 1000; // iki rapor arası min 15 sn
      const WINDOW_MS = 60 * 60 * 1000; // 1 saat
      const WINDOW_LIMIT = 20; // saatlik max 20 rapor

      /**
       * Gelen veriden güvenli bir şekilde string alır.
       * @param {string} key - Veri nesnesindeki anahtar.
       * @param {number} maxLen - İzin verilen maksimum uzunluk.
       * @param {boolean} [required=true] - Alanın zorunlu olup olmadığı.
       * @return {string} Temizlenmiş string.
       */
      function takeString(key, maxLen, required=true) {
        const v = data[key];
        if ((v == null || v === "") && !required) return "";
        if (typeof v !== "string") {
          throw new functions.https.HttpsError("invalid-argument",
              key + " string değil");
        }
        if (v.length > maxLen) {
          throw new functions.https.HttpsError("invalid-argument",
              key + " çok uzun");
        }
        return v.trim();
      }
      const reportedUserId = takeString("reportedUserId", 128);
      const reason = takeString("reason", 120);
      const details = takeString("details", 2000, false);
      const reportedContent = takeString("reportedContent", 4000, false);
      const reportedContentId = takeString("reportedContentId", 256, false);
      const reportedContentType = takeString("reportedContentType", 64, false);
      const reportedContentParentId =
        takeString("reportedContentParentId", 256, false);

      const rlRef = db.collection("rate_limits").doc("reports_" + uid);
      try {
        await db.runTransaction(async (tx) => {
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
              throw new functions.https.HttpsError("resource-exhausted",
                  "Çok hızlı raporlama (bekleyin)");
            }
            if (count >= WINDOW_LIMIT) {
              throw new functions.https.HttpsError("resource-exhausted",
                  "Saatlik rapor limiti aşıldı");
            }
          }
          count += 1;
          tx.set(rlRef, {lastAt: now, windowStart, count}, {merge: true});
        });

        let docId = undefined;
        if (reportedContentId) docId = uid + "_" + reportedContentId;
        const reportsCol = db.collection("reports");
        if (docId) {
          const exist = await reportsCol.doc(docId).get();
          if (exist.exists) {
            throw new functions.https.HttpsError("already-exists",
                "Bu içeriği zaten raporladınız");
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
          status: "pending",
          serverAuth: true,
        };
        if (docId) {
          await reportsCol.doc(docId).set(baseData, {merge: false});
        } else {
          await reportsCol.add(baseData);
        }
        return {success: true};
      } catch (e) {
        if (e instanceof functions.https.HttpsError) throw e;
        console.error("createReport error:", e);
        throw new functions.https.HttpsError("internal", "Rapor hatası");
      }
    });
/**
 * Admin bildirim gönderimi
 * Admin panelinden belirli kullanıcılara veya tüm kullanıcılara bildirim
 * gönderir.
 */
exports.sendAdminNotification = functions
    .region("us-central1")
    .https.onCall(async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Auth gerekli");
      }
      const uid = context.auth.uid;
      try {
        const userDoc = await db.collection("users").doc(uid).get();
        const role = (userDoc.data() && userDoc.data().role) ||
          userDoc.get("role") || "user";
        if (role !== "admin") {
          throw new functions.https.HttpsError("permission-denied",
              "Sadece admin");
        }
      } catch (e) {
        if (e instanceof functions.https.HttpsError) throw e;
        throw new functions.https.HttpsError("internal", "Rol doğrulanamadı");
      }

      /**
       * Gelen veriden güvenli bir şekilde string alır.
       * @param {string} key - Veri nesnesindeki anahtar.
       * @param {number} maxLen - İzin verilen maksimum uzunluk.
       * @return {string} Temizlenmiş string.
       */
      function take(key, maxLen) {
        const v = data && data[key];
        if (!v || typeof v !== "string") return "";
        const trimmed = v.trim();
        if (trimmed.length > maxLen) return trimmed.slice(0, maxLen);
        return trimmed;
      }
      const title = take("title", 100);
      const body = take("body", 500);
      const segment = take("segment", 40) || "all";
      const targetUid = take("targetUid", 200); // segment == 'user'
      // optional in-app navigation route
      const targetRoute = take("targetRoute", 120);
      if (!title || !body) {
        throw new functions.https.HttpsError("invalid-argument",
            "Başlık ve içerik zorunlu");
      }

      let userQuery = db.collection("users").where("status", "==", "active");
      if (segment === "premium") {
        userQuery = userQuery.where("isPremium", "==", true);
      } else if (segment === "non_premium") {
        userQuery = userQuery.where("isPremium", "==", false);
      } else if (segment === "user" && targetUid) {
        userQuery = db.collection("users")
            .where(admin.firestore.FieldPath.documentId(), "==", targetUid);
      }

      const tokens = [];
      const snap = await userQuery.select("fcmTokens").get();
      snap.forEach((d) => {
        const t = d.get("fcmTokens");
        if (Array.isArray(t)) {
          t.forEach((v) => {
            if (typeof v === "string" && v.length > 20) tokens.push(v);
          });
        }
      });
      if (!tokens.length) {
        return {success: true, sent: 0, failed: 0, totalTokens: 0};
      }

      const messaging = admin.messaging();
      const BATCH = 500;
      let sentCount = 0;
      let failCount = 0;
      for (let i = 0; i < tokens.length; i += BATCH) {
        const slice = tokens.slice(i, i + BATCH);
        const res = await messaging.sendEachForMulticast({
          tokens: slice,
          notification: {title, body},
          data: {
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            segment,
            kind: "admin_broadcast",
            targetRoute: targetRoute || "",
          },
        });
        sentCount += res.successCount;
        failCount += res.failureCount;
      }

      try {
        await db.collection("admin_notifications_log").add({
          title, body, segment,
          targetUid: segment==="user"? targetUid : null,
          targetRoute: targetRoute || null,
          sent: sentCount,
          failed: failCount,
          totalTokens: tokens.length,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          createdBy: uid,
        });
      } catch (_) {
        // Non-critical error, suppress.
      }

      return {
        success: true,
        sent: sentCount,
        failed: failCount,
        totalTokens: tokens.length,
      };
    });
// Helper to get level group
const getLevelGroup = (level) => {
  if (!level) return "Beginner";
  if (["A1", "A2"].includes(level)) return "Beginner";
  if (["B1", "B2"].includes(level)) return "Intermediate";
  return "Advanced";
};

/**
 * Eşleştirme Fonksiyonu (Transactional, Yeniden Yazılmış ve Düzeltilmiş)
 * Kullanıcıları bekleme havuzundan eşleştirir veya havuza ekler.
 * Bu fonksiyon, Firestore işlemlerinin doğru kullanımını takip eder:
 * 1. Sorgu, işlem DIŞINDA yapılır.
 * 2. İşlem İÇİNDE, potansiyel eşleşmelerin hala uygun olduğu doğrulanır.
 * 3. Eşleşme, oluşturma ve silme işlemleri atomik olarak gerçekleştirilir.
 */
exports.findMatch = functions
    .region("us-central1")
    .https.onCall(async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated", "Authentication required.",
        );
      }

      const myId = context.auth.uid;

      // --- Rate Limiting (İşlem Dışında) ---
      const now = Date.now();
      const rlRef = db.collection("rate_limits").doc(`matchmaking_${myId}`);
      try {
        await db.runTransaction(async (tx) => {
          const rlSnap = await tx.get(rlRef);
          const MIN_INTERVAL_MS = 2000;
          const WINDOW_MS = 60000;
          const WINDOW_LIMIT = 15;
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
              throw new functions.https.HttpsError("resource-exhausted",
                  "Too many requests. Please wait a moment.");
            }
            if (count >= WINDOW_LIMIT) {
              throw new functions.https.HttpsError("resource-exhausted",
                  "Matchmaking limit exceeded for this minute.");
            }
          }
          count += 1;
          tx.set(rlRef, {lastAt: now, windowStart, count}, {merge: true});
        });
      } catch (e) {
        if (e instanceof functions.https.HttpsError) throw e;
        console.error("Rate limit transaction error:", e);
        throw new functions.https.HttpsError("internal", "Rate limit check failed.");
      }

      // --- Veri Hazırlığı (İşlem Dışında) ---
      const {selectedGenderFilter, selectedLevelGroupFilter} = data;

      const myUserDoc = await db.collection("users").doc(myId).get();
      if (!myUserDoc.exists) {
        throw new functions.https.HttpsError("not-found", "User profile not found.");
      }
      const myData = myUserDoc.data();
      const myPublicData = {
        uid: myId,
        displayName: myData.displayName,
        avatarUrl: myData.avatarUrl,
        level: myData.level,
        levelGroup: getLevelGroup(myData.level),
        gender: myData.gender,
      };
      const myBlockedUsersSnapshot = await db.collection("users").doc(myId).collection("blockedUsers").get();
      const myBlockedSet = new Set(myBlockedUsersSnapshot.docs.map((d) => d.id));

      // --- Adım 1: Sorgu (İşlem Dışında) ---
      let query = db.collection("waiting_pool");
      if (selectedGenderFilter) {
        query = query.where("gender", "==", selectedGenderFilter);
      }
      if (selectedLevelGroupFilter) {
        query = query.where("levelGroup", "==", selectedLevelGroupFilter);
      }
      query = query.orderBy("waitingSince").limit(20);
      const potentialMatchesSnapshot = await query.get();
      const potentialPartnerDocs = potentialMatchesSnapshot.docs.filter(
          (doc) => doc.id !== myId,
      );

      // --- Adım 2: Eşleştirme Mantığı (İşlem İçinde) ---
      try {
        const result = await db.runTransaction(async (tx) => {
          let finalStatus = {status: "ADDED_TO_POOL"};

          // Adım 2a: Potansiyel eşleşmeleri doğrula
          for (const partnerDoc of potentialPartnerDocs) {
            const partnerId = partnerDoc.id;
            const partnerRef = db.collection("waiting_pool").doc(partnerId);
            const partnerDocInTx = await tx.get(partnerRef);

            if (!partnerDocInTx.exists) {
              continue; // Başkası tarafından eşleştirilmiş, atla
            }

            const partnerData = partnerDocInTx.data();
            const partnerFilterGender = partnerData.filter_gender;
            const partnerFilterLevelGroup = partnerData.filter_level_group;

            // Karşılıklı filtre ve engelleme kontrolü
            if (myBlockedSet.has(partnerId)) {
              continue;
            }
            const otherBlockedMeRef = db.collection("users").doc(partnerId).collection("blockedUsers").doc(myId);
            const otherBlockedMeDoc = await tx.get(otherBlockedMeRef);
            if (otherBlockedMeDoc.exists) {
              continue;
            }

            const isMyGenderOk = !partnerFilterGender || partnerFilterGender === myPublicData.gender;
            const isMyLevelGroupOk = !partnerFilterLevelGroup || partnerFilterLevelGroup === myPublicData.levelGroup;

            if (isMyGenderOk && isMyLevelGroupOk) {
              // Adım 2b: Eşleşme bulundu! Atomik olarak işlemleri yap.
              const chatRoomRef = db.collection("chats").doc();
              tx.set(chatRoomRef, {
                users: [myId, partnerId].sort(),
                userDetails: {[myId]: myPublicData, [partnerId]: partnerData},
                status: "active",
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
              });

              const matchData = {
                chatId: chatRoomRef.id,
                matchedAt: admin.firestore.FieldValue.serverTimestamp(),
              };
              tx.set(db.collection("matches").doc(myId), {...matchData, partner: partnerData});
              tx.set(db.collection("matches").doc(partnerId), {...matchData, partner: myPublicData});

              // Her iki kullanıcıyı da havuzdan sil
              tx.delete(partnerRef);
              const myWaitingRef = db.collection("waiting_pool").doc(myId);
              tx.delete(myWaitingRef); // Kendimi de havuzdan sil (varsa)

              // Eşleşme yapıldı, durumu güncelle ve döngüden çık.
              finalStatus = {status: "MATCH_PROCESSED"};
              break;
            }
          }

          // Döngüden sonra, eğer eşleşme bulunmadıysa, kullanıcıyı havuza ekle.
          if (finalStatus.status === "ADDED_TO_POOL") {
            const waitingPoolRef = db.collection("waiting_pool").doc(myId);
            tx.set(waitingPoolRef, {
              ...myPublicData,
              waitingSince: admin.firestore.FieldValue.serverTimestamp(),
              filter_gender: selectedGenderFilter || null,
              filter_level_group: selectedLevelGroupFilter || null,
            });
          }

          return finalStatus;
        });
        return result;
      } catch (error) {
        console.error("Matchmaking transaction failed:", error);
        throw new functions.https.HttpsError("internal", "Matchmaking failed, please try again.");
      }
    });

/**
 * Sets a custom user claim to identify an admin.
 * Can only be called by an already authenticated admin.
 */
exports.setAdminClaim = functions
    .region("us-central1")
    .https.onCall(async (data, context) => {
    // Check if the caller is an admin.
    // Note: The first admin must be set manually via the gcloud CLI.
      if (context.auth.token.admin !== true) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "Only admins can set other admins.",
        );
      }

      const targetUid = data.uid;
      if (!targetUid || typeof targetUid !== "string") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with a 'uid' argument.",
        );
      }

      try {
      // Set custom user claims on the target user.
        await admin.auth().setCustomUserClaims(targetUid, {admin: true});

        // Update the user's role in Firestore for client-side UI checks.
        await db.collection("users").doc(targetUid).set({
          role: "admin",
        }, {merge: true});

        return {
          message: `Success! ${targetUid} has been made an admin.`,
        };
      } catch (error) {
        console.error("Error setting admin claim:", error);
        throw new functions.https.HttpsError(
            "internal",
            "An error occurred while setting the admin claim.",
        );
      }
    });
