/* eslint-disable no-console */
const functions = require("firebase-functions");
const functionsV1 = require("firebase-functions/v1");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2/options");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
// Google Generative AI ESM; dinamik import ile kullanılacak
// const {GoogleGenerativeAI, HarmCategory, HarmBlockThreshold} = require('@google/generative-ai');

// 2. Nesil genel seçenekler: bölge + Eventarc konumu (Firestore varsayılan çok bölge: eur3)
setGlobalOptions({ region: 'us-central1', eventarc: { location: 'eur3' } });

admin.initializeApp();
const db = admin.firestore();
const premium = require('./premium'); // Premium satın alma doğrulama fonksiyonlarını yükle

// Cloud Functions exports
exports.setPremiumStatus = premium.setPremiumStatus;

/**
 * Kullanıcı adı kontrolü (Cloud Function)
 * Yeni bir kullanıcı kaydı sırasında, kullanıcı adının kullanılabilir olup
 * olmadığını kontrol eder.
 * Güvenlik sıkılaştırmaları:
 *  - Karakter seti kısıtlaması (^[a-z0-9_]{3,29}$)
 *  - Rezerve isim listesi
 *  - Tek seferde tek istek (basit sunucu tarafı doğrulama)
 */
exports.checkUsernameAvailable = onCall({ region: "us-central1" }, async (request) => {
  try {
    const data = request.data || {};
    const raw = (data && data.username) ? String(data.username) : "";
    const username = raw.trim().toLowerCase();
    const ipOrUid = request.auth ? request.auth.uid : "anon";
    if (!allowUsernameCheck(ipOrUid)) {
      return {available: false, reason: "rate_limited"};
    }
    // Reserved list hizalı ve sadeleştirildi; 'administrator' artık serbest
    const RESERVED = new Set([
      "admin", "root", "support", "moderator", "mod",
      "system", "null", "undefined", "owner", "staff", "team",
      "vocachat", "voca", "api"
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
    throw new HttpsError("internal", "check failed");
  }
});
/** Kullanıcı adı rezerve etme (benzersizlik) */
exports.reserveUsername = onCall({ region: "us-central1" }, async (request) => {
  const data = request.data || {};
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Giriş gerekli");
  }
  const raw = data && data.username ? String(data.username) : "";
  const username = raw.trim().toLowerCase();
  // Aynı RESERVED seti burada da kullanılıyor
  const RESERVED = new Set([
    "admin", "root", "support", "moderator", "mod",
    "system", "null", "undefined", "owner", "staff", "team",
    "vocachat", "voca", "api"
  ]);
  const VALID_RE = /^[a-z0-9_]{3,29}$/;
  if (!VALID_RE.test(username)) {
    throw new HttpsError("invalid-argument",
        "Geçersiz format");
  }
  if (RESERVED.has(username)) {
    throw new HttpsError("already-exists", "Rezerve isim");
  }
  const ref = db.collection("usernames").doc(username);
  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (snap.exists) {
        const err = new HttpsError("already-exists", "Alınmış");
        throw err;
      }
      tx.set(ref, {
        uid: request.auth.uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    return {reserved: true};
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    console.error("reserveUsername error", e);
    throw new HttpsError("internal", "Rezervasyon hatası");
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
exports.sendVerificationCode = functionsV1.auth.user().onCreate((user) => {
  const userEmail = user.email;
  const displayName = user.displayName || "User";
  if (!userEmail) return null;

  const gmailEmail = functions.config().gmail && functions.config().gmail.email;
  const gmailPassword = functions.config().gmail && functions.config().gmail.password;
  if (!gmailEmail || !gmailPassword) return null;

  const mailTransport = nodemailer.createTransport({
    service: "gmail",
    auth: {user: gmailEmail, pass: gmailPassword},
  });

  const mailOptions = {
    from: `"VocaChat Team" <${gmailEmail}>`,
    to: userEmail,
    subject: "Welcome to VocaChat!",
    html: `<h1>Welcome, ${displayName}!</h1><p>Your account is ready. ` +
          `Please verify your email to start your language learning adventure.</p>`,
  };

  return mailTransport.sendMail(mailOptions);
});

/**
 * Kullanıcı hesabı silme (HARD DELETE)
 * - Rezerve kullanıcı adları serbest bırakılır
 * - Kullanıcı dokümanının alt koleksiyonları silinir
 * - Kullanıcı dokümanı tamamen silinir
 * - Auth kullanıcısı silinir
 */
exports.deleteUserAccount = onCall({ region: "us-central1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "Bu işlemi gerçekleştirmek için kimlik doğrulaması gereklidir.",
    );
  }
  const uid = request.auth.uid;
  const userRef = db.collection("users").doc(uid);
  try {
    // 1) Rezerve kullanıcı adlarını serbest bırak
    try {
      const usernamesSnap = await db.collection("usernames").where("uid", "==", uid).get();
      if (!usernamesSnap.empty) {
        const batchArray = [];
        let batch = db.batch();
        let opCount = 0;
        usernamesSnap.forEach((doc) => {
          batch.delete(doc.ref);
          opCount++;
          if (opCount === 450) { // güvenli sınır
            batchArray.push(batch.commit());
            batch = db.batch();
            opCount = 0;
          }
        });
        if (opCount > 0) batchArray.push(batch.commit());
        await Promise.all(batchArray);
      }
    } catch (cleanupErr) {
      console.error("username cleanup failed:", cleanupErr);
    }

    // 2) Kullanıcı dokümanının alt koleksiyonlarını temizle (küçük ölçek varsayımı)
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
      console.error("subcollection cleanup failed:", subErr);
    }

    // 3) Kullanıcı dokümanını sil (soft delete yerine tam silme)
    try {
      await userRef.delete();
    } catch (docDelErr) {
      console.error("user doc delete failed:", docDelErr);
    }

    // 4) Auth kullanıcısını sil
    try {
      await admin.auth().deleteUser(uid);
    } catch (authErr) {
      console.error("auth user delete failed:", authErr);
      throw new HttpsError("internal", "Auth kullanıcı silinemedi.");
    }

    return {success: true, hardDeleted: true};
  } catch (error) {
    console.error("deleteUserAccount hard delete error:", error);
    throw new HttpsError(
        "internal",
        "Hesap silinirken bir sunucu hatası oluştu.",
    );
  }
});
/** Rapor oluşturulduğunda içerik bazlı rapor sayacını artır */
exports.onReportCreated = onDocumentCreated({ region: 'us-central1' }, "reports/{reportId}", async (event) => {
  try {
    const snap = event.data; // QueryDocumentSnapshot
    if (!snap) return null;
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
exports.createReport = onCall({ region: "us-central1" }, async (request) => {
  const data = request.data || {};
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Giriş gerekli");
  }
  const uid = request.auth.uid;
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
      throw new HttpsError("invalid-argument",
          key + " string değil");
    }
    if (v.length > maxLen) {
      throw new HttpsError("invalid-argument",
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
          throw new HttpsError("resource-exhausted",
              "Çok hızlı raporlama (bekleyin)");
        }
        if (count >= WINDOW_LIMIT) {
          throw new HttpsError("resource-exhausted",
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
        throw new HttpsError("already-exists",
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
    if (e instanceof HttpsError) throw e;
    console.error("createReport error:", e);
    throw new HttpsError("internal", "Rapor hatası");
  }
});
/**
 * Admin bildirim gönderimi
 * Admin panelinden belirli kullanıcılara veya tüm kullanıcılara bildirim
 * gönderir.
 */
exports.sendAdminNotification = onCall({ region: "us-central1" }, async (request) => {
  const data = request.data || {};
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Auth gerekli");
  }
  const uid = request.auth.uid;
  try {
    const userDoc = await db.collection("users").doc(uid).get();
    const role = (userDoc.data() && userDoc.data().role) ||
      userDoc.get("role") || "user";
    if (role !== "admin") {
      throw new HttpsError("permission-denied",
          "Sadece admin");
    }
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    throw new HttpsError("internal", "Rol doğrulanamadı");
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
    throw new HttpsError("invalid-argument",
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

  // Token -> userId eşlemesi ve kullanıcı bazlı orijinal liste saklama
  const tokenUserMap = {}; // token -> userId
  const userTokensMap = {}; // userId -> orijinal token listesi (kopya)

  snap.forEach((d) => {
    const t = d.get("fcmTokens");
    if (Array.isArray(t)) {
      const validList = [];
        t.forEach((v) => {
          if (typeof v === "string" && v.length > 20) {
            tokens.push(v);
            if (!tokenUserMap[v]) tokenUserMap[v] = d.id; // ilk sahibini kaydet
            validList.push(v);
          }
        });
      userTokensMap[d.id] = validList; // sadece geçerli uzunluk filtresinden geçenler
    } else {
      userTokensMap[d.id] = [];
    }
  });
  if (!tokens.length) {
    return {success: true, sent: 0, failed: 0, totalTokens: 0, removedInvalid: 0};
  }

  const messaging = admin.messaging();
  const BATCH = 500;
  let sentCount = 0;
  let failCount = 0;

  // Geçersiz sayılan hata kodları
  const invalidCodes = new Set([
    'messaging/registration-token-not-registered',
    'messaging/invalid-registration-token',
    'messaging/invalid-argument',
  ]);
  // userId -> Set(invalidTokens)
  const invalidByUser = {};

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

  // Geçersiz token temizliği
  let removedInvalidCount = 0;
  const invalidUserIds = Object.keys(invalidByUser);
  if (invalidUserIds.length) {
    const batch = db.batch();
    invalidUserIds.forEach((uid2) => {
      const toRemoveSet = invalidByUser[uid2];
      const original = userTokensMap[uid2] || [];
      const filtered = original.filter(t => !toRemoveSet.has(t));
      removedInvalidCount += (original.length - filtered.length);
      batch.update(db.collection('users').doc(uid2), { fcmTokens: filtered });
    });
    try { await batch.commit(); } catch (_) { /* yut */ }
  }

  try {
    await db.collection("admin_notifications_log").add({
      title, body, segment,
      targetUid: segment==="user"? targetUid : null,
      targetRoute: targetRoute || null,
      sent: sentCount,
        failed: failCount,
      totalTokens: tokens.length,
      removedInvalid: removedInvalidCount,
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
    removedInvalid: removedInvalidCount,
  };
});


/**
 * Sets a custom user claim to identify an admin.
 * Can only be called by an already authenticated admin.
 */
exports.setAdminClaim = onCall({ region: "us-central1" }, async (request) => {
  const data = request.data || {};
  // Check if the caller is an admin.
  // Note: The first admin must be set manually via the gcloud CLI.
  if (!request.auth || request.auth.token?.admin !== true) {
    throw new HttpsError(
        "permission-denied",
        "Only admins can set other admins.",
    );
  }

  const targetUid = data.uid;
  if (!targetUid || typeof targetUid !== "string") {
    throw new HttpsError(
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
    throw new HttpsError(
        "internal",
        "An error occurred while setting the admin claim.",
    );
  }
});
/** Kullanıcı adını güvenli şekilde değiştirme (atomik) */
exports.changeUsername = onCall({ region: "us-central1" }, async (request) => {
  const data = request.data || {};
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Giriş gerekli");
  }
  const raw = data && data.username ? String(data.username) : "";
  // Orijinal girilen (trim + boşlukları kaldır)
  let originalUsername = raw.trim();
  // İç boşlukları tamamen kaldır (UI zaten engelliyor ama ekstra güvenlik)
  originalUsername = originalUsername.replace(/\s+/g, "");

  const usernameLower = originalUsername.toLowerCase();

  const RESERVED = new Set([
    "admin", "root", "support", "moderator", "mod",
    "system", "null", "undefined", "owner", "staff", "team",
    "vocachat", "voca", "api"
  ]);
  const VALID_RE = /^[A-Za-z0-9_]{3,29}$/; // Büyük/küçük harf serbest
  if (!VALID_RE.test(originalUsername)) {
    throw new HttpsError("invalid-argument", "Geçersiz format");
  }
  if (RESERVED.has(usernameLower)) {
    throw new HttpsError("already-exists", "Rezerve isim");
  }

  const uid = request.auth.uid;
  const userRef = db.collection("users").doc(uid);
  const newRef = db.collection("usernames").doc(usernameLower); // benzersizlik lowercase

  // Kullanıcının mevcut tüm rezervasyonlarını önceden oku (silmek için)
  const prevSnap = await db.collection("usernames").where("uid", "==", uid).get();

  try {
    await db.runTransaction(async (tx) => {
      const taken = await tx.get(newRef);
      if (taken.exists) {
        const owner = (taken.data() && taken.data().uid) || null;
        if (owner !== uid) {
          throw new HttpsError("already-exists", "Alınmış");
        }
        // Aynı kullanıcıya aitse idempotent kabul
      }
      // Yeni kullanıcı adını rezerve et (lowercase key)
      tx.set(newRef, {
        uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      // Eski tüm kayıtları sil (yeni olan hariç)
      prevSnap.forEach((doc) => {
        if (doc.id !== usernameLower) tx.delete(doc.ref);
      });
      // Kullanıcı profilini güncelle (displayName orijinal case korunur)
      tx.set(userRef, {
        displayName: originalUsername,
        username_lowercase: usernameLower,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
    });
    return {success: true};
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    console.error("changeUsername error", e);
    throw new HttpsError("internal", "Kullanıcı adı değiştirilemedi");
  }
});

/**
 * Gemini API key config helper (dinamik import)
 */
async function getGeminiClient() {
  const key = (functions.config().gemini && functions.config().gemini.key) || process.env.GEMINI_API_KEY;
  if (!key) {
    throw new HttpsError('failed-precondition', 'Gemini API anahtarı eksik (functions:config:set gemini.key=...)');
  }
  const { GoogleGenerativeAI } = await import('@google/generative-ai');
  return new GoogleGenerativeAI(key);
}

function sanitizeReply(text) {
  if (!text) return '';
  let t = text.trim();
  if (t.startsWith('```')) {
    t = t.replace(/^```[a-zA-Z0-9]*\n?/, '').replace(/```$/,'').trim();
  }
  // Çoklu boşlukları sadeleştir
  t = t.replace(/\n{3,}/g, '\n\n');
  return t;
}

// Basit intent sınıflandırıcı (istemciyle benzer)
function classifyIntent(msg) {
  const m = (msg||'').toLowerCase().trim();
  if (/^(hi|hey|hello)(\b|!|\?|\.)/.test(m)) return 'greeting';
  if (/correct|grammar|mistake|error|fix|wrong/.test(m)) return 'correction';
  if (/explain|why|difference|mean|meaning/.test(m)) return 'explanation';
  if (/synonym|another way|rephrase|paraphrase/.test(m)) return 'rephrase';
  if (/test me|quiz|question|practice/.test(m)) return 'practice';
  if (/(^| )end($| )|bye|goodbye|see you/.test(m)) return 'closing';
  return 'chat';
}

function buildSystemPrompt(targetLang, nativeLang, level) {
  const isEnglish = (targetLang||'').toLowerCase()==='english' || (targetLang||'').toLowerCase()==='en';
  const targetName = targetLang || 'English';
  const nativeName = nativeLang || 'English';
  const lvl = (level||'medium');
  // Basit CEFR/ton eşlemesi
  const guideByLevel = {
    none: {
      cefr: 'A0-A1',
      style: '- Use ultra-simple words and very short sentences (<=8 words).\n- Prefer everyday phrases.\n- If user seems lost, add a short hint in ' + nativeName + ' in parentheses once in a while.'
    },
    low: {
      cefr: 'A1-A2',
      style: '- Use simple vocabulary and short sentences (<=12 words).\n- Avoid idioms and complex tenses.\n- Offer tiny hints/examples when needed.'
    },
    medium: {
      cefr: 'B1',
      style: '- Moderate difficulty; clear, practical sentences.\n- Mild corrections when asked or mistakes block understanding.'
    },
    high: {
      cefr: 'B2-C1',
      style: '- Richer vocabulary, natural pace.\n- Encourage nuanced expressions; still concise.'
    },
    very_high: {
      cefr: 'C1-C2',
      style: '- Native-like fluency; natural idioms allowed.\n- Precise, concise, challenging but friendly.'
    }
  };
  const g = guideByLevel[lvl] || guideByLevel.medium;
  const base = isEnglish
    ? `You are VocaBot: natural, concise, upbeat human-like ${targetName} practice partner.`
    : `You are VocaBot: a concise, encouraging tutor helping the user practice ${targetName}. PRIMARY OUTPUT LANGUAGE: ${targetName}. Unless the user explicitly writes in ${nativeName} asking for a translation/explanation, respond fully in ${targetName}.`;
  const lvlNote = `LEARNER LEVEL: ${g.cefr} (${lvl}).\nLEVEL GUIDELINES:\n${g.style}`;
  return `${base}\n${lvlNote}\nPRINCIPLES:\n- Keep answers SHORT and focused. Avoid lists unless user explicitly asks.\n- Warm, human tone.\n- Correct only clear mistakes when user asks OR error is severe.\n- MAX emojis: 1 optional, never at the start.\n- Never say you are an AI model.\n- Plain text only.`;
}

function resolveDailyLimit(key) {
  const defaults = { vocabotSend: 200, vocabotAnalyzeGrammar: 50, aiTranslate: 150 };
  try {
    if (functions.config().ai) {
      const cfg = functions.config().ai;
      if (cfg[key]) {
        const n = Number(cfg[key]);
        if (!isNaN(n) && n > 0) return n;
      }
    }
  } catch (_) {}
  return defaults[key] || 100;
}

async function checkDailyQuota(request, key) {
  if (!request.auth) throw new HttpsError('unauthenticated','Giriş gerekli');
  const uid = request.auth.uid;
  const today = new Date();
  const ymd = today.toISOString().slice(0,10).replace(/-/g,''); // YYYYMMDD
  const docId = uid + '_' + ymd;
  const ref = db.collection('ai_usage').doc(docId);
  const limit = resolveDailyLimit(key);
  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const base = snap.exists ? (snap.data() || {}) : { uid, date: ymd, counts: {} };
      const counts = base.counts || {};
      const current = counts[key] || 0;
      if (current >= limit) {
        throw new HttpsError('resource-exhausted', `Günlük ${key} limiti aşıldı (${limit})`);
      }
      counts[key] = current + 1;
      base.counts = counts;
      base.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      if (!snap.exists) base.createdAt = admin.firestore.FieldValue.serverTimestamp();
      tx.set(ref, base, { merge: true });
    });
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    console.error('checkDailyQuota error', e);
    throw new HttpsError('internal','Kota kontrolü başarısız');
  }
}

async function requirePremium(uid) {
  try {
    const snap = await db.collection('users').doc(uid).get();
    if (!snap.exists) {
      throw new HttpsError('permission-denied','Premium gerekli (profil yok)');
    }
    const premium = snap.get('isPremium') === true;
    if (!premium) {
      throw new HttpsError('permission-denied','Bu özellik için premium gerekli');
    }
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    console.error('requirePremium error', e);
    throw new HttpsError('internal','Premium doğrulanamadı');
  }
}

exports.vocabotSend = onCall({ region: 'us-central1' }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated','Giriş gerekli');
  await requirePremium(request.auth.uid);
  await checkDailyQuota(request, 'vocabotSend');
  const data = request.data || {};
  const message = (data && data.message)||'';
  const targetLanguage = (data && data.targetLanguage)||'en';
  const nativeLanguage = (data && data.nativeLanguage)||'en';
  const learningLevel = (data && data.learningLevel)||'medium';
  const scenario = (data && data.scenario) ? String(data.scenario).trim() : '';
  if (!message.trim()) throw new HttpsError('invalid-argument','Boş mesaj');
  if (message.length > 1200) throw new HttpsError('invalid-argument','Mesaj çok uzun');
  try {
    const genAI = await getGeminiClient();
    const { HarmCategory, HarmBlockThreshold } = await import('@google/generative-ai');
    const systemInstruction = buildSystemPrompt(targetLanguage, nativeLanguage, learningLevel);
    const intent = classifyIntent(message);
    const model = genAI.getGenerativeModel({
      model: 'gemini-2.0-flash-lite',
      systemInstruction,
      safetySettings: [
        {category: HarmCategory.HARM_CATEGORY_HARASSMENT, threshold: HarmBlockThreshold.BLOCK_NONE},
        {category: HarmCategory.HARM_CATEGORY_HATE_SPEECH, threshold: HarmBlockThreshold.BLOCK_NONE},
        {category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT, threshold: HarmBlockThreshold.BLOCK_NONE},
        {category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT, threshold: HarmBlockThreshold.BLOCK_NONE},
      ],
    });
    const scenarioBlock = scenario ? `\nSCENARIO: ${scenario}\nROLE: Act within this scenario. Keep responses contextual and realistic. Use short, natural dialogue lines.` : '';
    const augmented = `USER_MESSAGE: "${message}"\nINTENT: ${intent}${scenarioBlock}\nGUIDELINES: Keep it short (<=2 sentences) unless explanation asked. Natural tone.`;
    const result = await model.generateContent([{text: augmented}]);
    const reply = sanitizeReply(result.response.text());
    return {reply};
  } catch (e) {
    console.error('vocabotSend error', e);
    throw new HttpsError('internal','VocaBot yanıt üretilemedi');
  }
});

function heuristicGrammar(userMessage) {
  const words = userMessage.trim().split(/\s+/).filter(Boolean);
  const complexity = Math.min(1, words.length/20);
  const corrections = {};
  const lower = userMessage.toLowerCase();
  if (lower.includes(' i ')) corrections[' i '] = ' I ';
  const grammarScore = Math.max(0.1, 1 - Object.keys(corrections).length * 0.15) * (0.5 + complexity/2);
  return {
    grammarScore: Number(grammarScore.toFixed(2)),
    formality: 'neutral',
    sentiment: 0,
    complexity: Number(complexity.toFixed(2)),
    corrections,
    cefr: grammarScore>0.9? 'C2': grammarScore>0.75? 'C1': grammarScore>0.6? 'B2': grammarScore>0.45? 'B1': grammarScore>0.25? 'A2':'A1',
    suggestions: ['Great! Try a slightly longer sentence next time.'],
    errors: Object.entries(corrections).map(([k,v])=>({type:'basic', original:k.trim(), correction:v.trim(), severity:'low', explanation:'Basic form correction'}))
  };
}

exports.vocabotAnalyzeGrammar = onCall({ region: 'us-central1' }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated','Giriş gerekli');
  await requirePremium(request.auth.uid);
  await checkDailyQuota(request, 'vocabotAnalyzeGrammar');
  const data = request.data || {};
  const userMessage = (data && data.userMessage)||'';
  const targetLanguage = (data && data.targetLanguage)||'en';
  const learningLevel = (data && data.learningLevel)||'medium';
  if (!userMessage.trim()) throw new HttpsError('invalid-argument','Boş mesaj');
  try {
    const genAI = await getGeminiClient();
    const model = genAI.getGenerativeModel({model:'gemini-2.0-flash-lite'});
    const maxErrors = (learningLevel==='none'||learningLevel==='low') ? 3 : 5;
    const explainLen = (learningLevel==='none'||learningLevel==='low') ? 6 : 8;
    const prompt = [
      `You are a concise grammar feedback engine for learners of ${targetLanguage}. Level: ${learningLevel}.`,
      'Return ONLY raw JSON (no markdown). Schema:',
      '{',
      '  "grammarScore": float (0..1),',
      '  "formality": "informal|neutral|formal",',
      '  "sentiment": float (-1..1),',
      '  "complexity": float (0..1),',
      '  "errors": [ { "original":"...", "correction":"...", "explanation":"short" } ],',
      '  "suggestions": ["short tip", ...]',
      '}',
      'Rules:',
      `- Max ${maxErrors} errors; only real mistakes.`,
      `- Keep explanations <= ${explainLen} words.`,
      '- If perfect: grammarScore=1, errors=[], give 1 improvement suggestion.',
      '- No extra fields.',
      `User message: "${userMessage}"`
    ].join('\n');
    const result = await model.generateContent([{text: prompt}]);
    const raw = (result.response.text()||'').trim();
    const start = raw.indexOf('{');
    const end = raw.lastIndexOf('}');
    let parsed = null;
    if (start !== -1 && end !== -1 && end>start) {
      try { parsed = JSON.parse(raw.substring(start, end+1)); } catch(_) { parsed = null; }
    }
    if (!parsed) parsed = heuristicGrammar(userMessage);
    return {analysis: parsed};
  } catch (e) {
    console.error('vocabotAnalyzeGrammar error', e);
    return {analysis: heuristicGrammar(userMessage)}; // fallback
  }
});

exports.aiTranslate = onCall({ region: 'us-central1' }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated','Giriş gerekli');
  await requirePremium(request.auth.uid);
  await checkDailyQuota(request, 'aiTranslate');
  const data = request.data || {};
  const text = (data && data.text)||'';
  const targetCode = (data && data.targetCode)||'en';
  const sourceCode = data && data.sourceCode;
  if (!text.trim()) return {translation: ''};
  try {
    const genAI = await getGeminiClient();
    const model = genAI.getGenerativeModel({model:'gemini-2.0-flash-lite'});
    const prompt = [
      sourceCode ? `Source language: ${sourceCode}` : 'Detect the source language automatically',
      `Target language: ${targetCode}`,
      'RULES:',
      '- Output ONLY the translated sentence(s).',
      '- No quotes, no explanations, no language labels.',
      '- If already in target language, return original unchanged.',
      'TEXT:',
      text
    ].join('\n');
    const result = await model.generateContent([{text: prompt}]);
    let out = sanitizeReply(result.response.text());
    if ((out.startsWith('"') && out.endsWith('"')) || (out.startsWith("'") && out.endsWith("'"))) {
      out = out.slice(1,-1).trim();
    }
    return {translation: out};
  } catch (e) {
    console.error('aiTranslate error', e);
    return {translation: text};
  }
});

function takeString(data, key, maxLen, required=true) {
  const v = data && data[key];
  if ((v == null || v === '') && !required) return '';
  if (typeof v !== 'string') throw new HttpsError('invalid-argument', key + ' must be string');
  if (v.length > maxLen) throw new HttpsError('invalid-argument', key + ' too long');
  return String(v).trim();
}

function extractJson(text) {
  if (!text) return null;
  // Try fenced code block
  const fence = text.match(/```json\s*([\s\S]*?)\s*```/i);
  const raw = fence ? fence[1] : text;
  const first = raw.indexOf('{');
  const last = raw.lastIndexOf('}');
  if (first >= 0 && last > first) {
    const slice = raw.slice(first, last + 1);
    try { return JSON.parse(slice); } catch (_) {}
  }
  try { return JSON.parse(raw); } catch (_) { return null; }
}

function fallbackQuiz(topicPath, topicTitle, targetLanguage, nativeLanguage) {
  // Basit, güvenli bir varsayılan quiz
  return {
    quiz: {
      topicPath,
      topicTitle,
      question: `(${targetLanguage}) ${topicTitle}: Doğru seçeneği işaretle.`,
      options: ['A', 'B', 'C'],
      correctIndex: 0,
      onCorrectNative: 'Doğru! Kısa kural özeti.',
      onWrongNative: 'Yanlış. Kuralın kısa açıklaması.',
    }
  };
}

exports.vocabotGrammarQuiz = onCall({ region: 'us-central1' }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Auth required');
  }
  const data = request.data || {};
  const uid = request.auth.uid;

  // Güvenli kısaltma yardımcı fonksiyonu
  function clampStr(v, max, def = '') {
    if (v == null) return def;
    const s = typeof v === 'string' ? v : String(v);
    return s.length > max ? s.slice(0, max).trim() : s.trim();
  }

  // Parametreleri güvenle al; doğrulama hatasında fallback ver
  let topicPath, topicTitle, targetLanguage, nativeLanguage, learningLevel;
  try {
    topicPath = takeString(data, 'topicPath', 64);
    topicTitle = takeString(data, 'topicTitle', 120);
    targetLanguage = takeString(data, 'targetLanguage', 8);
    nativeLanguage = takeString(data, 'nativeLanguage', 8);
    learningLevel = takeString(data, 'learningLevel', 16, false) || 'medium';
  } catch (argErr) {
    console.warn('vocabotGrammarQuiz invalid args, serving fallback', { uid, err: String(argErr) });
    topicPath = clampStr(data && data.topicPath, 64, 'general');
    topicTitle = clampStr(data && data.topicTitle, 120, 'General grammar');
    targetLanguage = clampStr(data && data.targetLanguage, 8, 'en');
    nativeLanguage = clampStr(data && data.nativeLanguage, 8, 'en');
    learningLevel = clampStr(data && data.learningLevel, 16, 'medium') || 'medium';
    return fallbackQuiz(topicPath, topicTitle, targetLanguage, nativeLanguage);
  }

  // Gemini yapılandırması yoksa hemen fallback
  if (!GENAI_API_KEY) {
    console.warn('vocabotGrammarQuiz: GENAI_API_KEY missing, serving fallback', { uid, topicPath });
    return fallbackQuiz(topicPath, topicTitle, targetLanguage, nativeLanguage);
  }

  try {
    const gen = await getGeminiClient();
    const model = gen.getGenerativeModel({ model: 'gemini-2.0-flash-lite' });

    const sys = `You are a concise language tutor. Create ONE multiple-choice question (3 options, exactly one correct) in the learner's target language about the given grammar topic.
- Keep the question short and clear.
- Make distractors plausible.
- Difficulty should align with level: ${learningLevel}.
- Return STRICT JSON only with fields: topicPath, topicTitle, question, options (array of 3 strings), correctIndex (0..2), onCorrectNative (string), onWrongNative (string).
- onCorrectNative: congratulate and give a VERY brief summary of the rule in ${nativeLanguage}.
- onWrongNative: explain the correct rule briefly in ${nativeLanguage}, optionally give one short example.
- Do NOT include any extra commentary or markdown.
- Ensure options length is exactly 3 and only one correct.
- The question must be written in the target language (${targetLanguage}).`;

    const user = `Topic: ${topicTitle} (${topicPath})\nTarget language: ${targetLanguage}\nNative language: ${nativeLanguage}`;

    const resp = await model.generateContent({ contents: [
      { role: 'user', parts: [{ text: sys + '\n\n' + user }] },
    ]});
    const text = resp?.response?.text?.();
    const parsed = extractJson(text);
    if (!parsed || !parsed.question || !Array.isArray(parsed.options) || parsed.options.length !== 3 || typeof parsed.correctIndex !== 'number') {
      console.warn('Invalid quiz JSON, serving fallback', { uid, topicPath });
      return fallbackQuiz(topicPath, topicTitle, targetLanguage, nativeLanguage);
    }
    const quiz = {
      topicPath,
      topicTitle,
      question: String(parsed.question).trim(),
      options: parsed.options.map((o) => String(o).trim()).slice(0,3),
      correctIndex: Math.max(0, Math.min(2, parseInt(parsed.correctIndex, 10))),
      onCorrectNative: String(parsed.onCorrectNative || '').trim() || 'Doğru!',
      onWrongNative: String(parsed.onWrongNative || '').trim() || 'Yanlış.',
    };
    return { quiz };
  } catch (e) {
    console.error('vocabotGrammarQuiz error, serving fallback', e);
    return fallbackQuiz(topicPath, topicTitle, targetLanguage, nativeLanguage);
  }
});

