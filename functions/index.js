/* eslint-disable no-console */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
const db = admin.firestore();
const storage = admin.storage();

// --- Sabitler ---
const QUIZ_DOC_ID = "active_quiz";
const TOTAL_QUESTIONS = 20;
const DURATION_PER_QUESTION_S = 20; // soru başına süre (sn)
const DURATION_COUNTDOWN_S = 10;    // başlangıç geri sayımı (sn)

const QUESTION_MS = DURATION_PER_QUESTION_S * 1000;

// Küçük yardımcı
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/**
 * Yarışmayı kurar ve başlatır:
 * - GCS'den questions.json'u okur
 * - Havuzdan rastgele TOTAL_QUESTIONS seçer
 * - /quizzes/active_quiz/questions altına yazar
 * - Ana belgeye countdown ve bitiş zamanlarını yazar
 */
async function setupAndStartQuiz() {
  const quizRef = db.collection("quizzes").doc(QUIZ_DOC_ID);

  try {
    // Soruları oku
    const bucket = storage.bucket();
    const file = bucket.file("questions.json");
    const [buf] = await file.download();
    const pool = JSON.parse(buf.toString());

    if (!Array.isArray(pool) || pool.length < TOTAL_QUESTIONS) {
      const msg = `Yetersiz soru sayısı! (Havuz: ${Array.isArray(pool) ? pool.length : 0})`;
      console.error(msg);
      return msg;
    }

    // Rastgele seç
    pool.sort(() => Math.random() - 0.5);
    const selected = pool.slice(0, TOTAL_QUESTIONS);

    // Eski soruları temizle
    const oldQsSnap = await quizRef.collection("questions").get();
    const batch = db.batch();
    oldQsSnap.docs.forEach((d) => batch.delete(d.ref));
    selected.forEach((q, idx) => {
      const ref = quizRef.collection("questions").doc(String(idx));
      batch.set(ref, { index: idx, ...q });
    });
    await batch.commit();

    // Ana yarışma belgesini yaz
    const nowMs = admin.firestore.Timestamp.now().toMillis();
    const countdownEndsAt = admin.firestore.Timestamp.fromMillis(
      nowMs + DURATION_COUNTDOWN_S * 1000
    );

    await quizRef.set(
      {
        status: "countdown",               // countdown | in_progress | finished
        totalQuestions: TOTAL_QUESTIONS,
        questionDurationMs: QUESTION_MS,   // ileride süre değişirse tek yerden kontrol
        currentQuestionIndex: -1,          // countdown sırasında -1
        countdown: DURATION_COUNTDOWN_S,   // görsel amaçlı alan (server günceller)
        countdownEndsAt,                   // asıl hakikat burası
        questionEndsAt: null,              // soru safhasında dolacak
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    const message = `Yarışma ${selected.length} soru ile başlatıldı.`;
    console.log(message);
    return message;
  } catch (err) {
    console.error("Yarışma kurulurken hata:", err);
    throw new functions.https.HttpsError("internal", "Yarışma başlatılamadı.", err.message);
  }
}

/**
 * Manuel başlatma (HTTP)
 */
exports.startQuizManually = functions
  .runWith({ timeoutSeconds: 120, memory: "512MB" })
  .https.onRequest(async (req, res) => {
    try {
      const result = await setupAndStartQuiz();
      res.status(200).send(result);
    } catch (err) {
      console.error("Manuel tetikleme hatası:", err);
      res.status(500).send("Bir hata oluştu: " + err.message);
    }
  });

/**
 * Zamanlanmış başlatma (Her Cumartesi 19:59 TRT)
 */
exports.startQuizScheduler = functions.pubsub
  .schedule("59 19 * * 6")
  .timeZone("Europe/Istanbul")
  .onRun(() => setupAndStartQuiz());

/**
 * Oyun döngüsü:
 * - countdown: her ~1sn'de countdown'ı endsAt'e göre hesaplayıp yazar; 0 olunca in_progress'e geçer
 * - in_progress: aktif sorunun questionEndsAt'ine göre, tam vaktinde ya da gecikse bile doğru şekilde
 *                sonraki soruya (gerekirse birden fazla adım) ilerler; bittiğinde finished yapar
 *
 * Not: Tüm kritik yazmalar transaction içinde yapılır (idempotent & yarışsız).
 */
exports.quizGameLoop = functions.firestore
  .document(`quizzes/${QUIZ_DOC_ID}`)
  .onWrite(async (change) => {
    if (!change.after.exists) {
      console.log("active_quiz silindi, döngü durduruldu.");
      return null;
    }

    const quizRef = change.after.ref;
    const data = change.after.data() || {};
    const status = data.status;

    // Yardımcı: güvenli geri sayım yazımı (transaction)
    async function tickCountdownOnce() {
      await sleep(1000); // saniyeye yakın adım

      await db.runTransaction(async (tx) => {
        const snap = await tx.get(quizRef);
        if (!snap.exists) return;

        const d = snap.data() || {};
        if (d.status !== "countdown" || !d.countdownEndsAt) return;

        const now = admin.firestore.Timestamp.now();
        const remainingMs = d.countdownEndsAt.toMillis() - now.toMillis();
        const remaining = Math.max(0, Math.ceil(remainingMs / 1000));

        // Zaman dolmuşsa direkt safha değiştir
        if (remaining <= 0) {
          // in_progress'e geçiş
          tx.update(quizRef, {
            status: "in_progress",
            currentQuestionIndex: 0,
            questionEndsAt: admin.firestore.Timestamp.fromMillis(
              now.toMillis() + (d.questionDurationMs || QUESTION_MS)
            ),
            countdown: 0,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          return;
        }

        // Hâlâ geri sayım sürüyorsa, değer değiştiyse yaz
        if (d.countdown !== remaining) {
          tx.update(quizRef, {
            countdown: remaining,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      });

      // Yazma yaptıysak tekrar tetiklenecek ve yeni instance bu fonksiyonu tekrar çağıracak.
      // Yazma yapmadıysak (ör. ceil sebebiyle aynı saniye), bir sonraki onWrite yine bu sleep->tx turunu tetikleyecek.
      return null;
    }

    // Yardımcı: soru safhasında ilerleme (transaction)
    async function advanceQuestionsIfDue() {
      // Gecikmesiz ve tek atımlık tetik için kalan süre kadar bekleyebiliriz
      const nowMs = admin.firestore.Timestamp.now().toMillis();
      const endsAt = data.questionEndsAt ? data.questionEndsAt.toMillis() : null;

      if (!endsAt) {
        // ilk kez in_progress'e geçtiyse endsAt boş olabilir; transaction içinde düzeltelim
        return db.runTransaction(async (tx) => {
          const snap = await tx.get(quizRef);
          if (!snap.exists) return;

          const d = snap.data() || {};
          if (d.status !== "in_progress") return;

          const now = admin.firestore.Timestamp.now();
          tx.update(quizRef, {
            questionEndsAt: admin.firestore.Timestamp.fromMillis(
              now.toMillis() + (d.questionDurationMs || QUESTION_MS)
            ),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });
      }

      const waitMs = Math.max(0, endsAt - nowMs);
      if (waitMs > 0) {
        await sleep(waitMs);
      }

      // Vakit dolduktan sonra, transaction ile ilerlet
      await db.runTransaction(async (tx) => {
        const snap = await tx.get(quizRef);
        if (!snap.exists) return;

        const d = snap.data() || {};
        if (d.status !== "in_progress") return;
        if (!d.questionEndsAt) return;

        const now = admin.firestore.Timestamp.now();
        const qEnds = d.questionEndsAt.toMillis();
        const dur = d.questionDurationMs || QUESTION_MS;

        if (now.toMillis() < qEnds) {
          // başka bir instance erken yazdıysa, burada iş bitti
          return;
        }

        // Kaç adım geçmemiz gerektiğini hesapla (gecikme olsa bile)
        const overdueMs = now.toMillis() - qEnds;
        const steps = 1 + Math.floor(overdueMs / dur); // en az 1 soru ilerle
        const nextIndex = d.currentQuestionIndex + steps;

        if (nextIndex < d.totalQuestions) {
          // Sonraki soruya (gerekirse birden fazla adım) geç ve yeni bitiş zamanını set et
          const newEndsAt = admin.firestore.Timestamp.fromMillis(
            qEnds + steps * dur
          );
          tx.update(quizRef, {
            currentQuestionIndex: nextIndex,
            questionEndsAt: newEndsAt,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          // Yarışma bitti
          tx.update(quizRef, {
            status: "finished",
            questionEndsAt: null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      });

      return null;
    }

    // Durum makinesi
    if (status === "countdown") {
      // İlk kurulumda countdownEndsAt olmayabilir; garanti altına al
      if (!data.countdownEndsAt) {
        await db.runTransaction(async (tx) => {
          const snap = await tx.get(quizRef);
          if (!snap.exists) return;
          const d = snap.data() || {};
          if (d.status !== "countdown") return;

          const now = admin.firestore.Timestamp.now();
          const ends = admin.firestore.Timestamp.fromMillis(
            now.toMillis() + (DURATION_COUNTDOWN_S * 1000)
          );
          tx.update(quizRef, {
            countdownEndsAt: ends,
            countdown: DURATION_COUNTDOWN_S,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });
      }
      return tickCountdownOnce();
    }

    if (status === "in_progress") {
      return advanceQuestionsIfDue();
    }

    // finished vb.
    return null;
  });

/* ----------------- DİĞER FONKSİYONLAR (değişmeden/ufak temizlikle) ----------------- */

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
