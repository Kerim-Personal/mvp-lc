const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// 1. Yeni Kullanıcı için E-posta Gönderme Fonksiyonu
exports.sendVerificationCode = functions.auth.user().onCreate((user) => {
  const userEmail = user.email;
  const displayName = user.displayName || "User";

  if (!userEmail) {
    functions.logger.log(`User ${user.uid} does not have an email address.`);
    return null;
  }

  // Gmail ayarlarını functions.config() üzerinden okuma
  const gmailEmail = functions.config().gmail.email;
  const gmailPassword = functions.config().gmail.password;

  if (!gmailEmail || !gmailPassword) {
    functions.logger.error("Gmail credentials are not set in functions config.");
    return null;
  }

  const mailTransport = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: gmailEmail,
      pass: gmailPassword,
    },
  });

  const mailOptions = {
    from: `"LinguaChat Team" <${gmailEmail}>`,
    to: userEmail,
    subject: "Welcome to LinguaChat!",
    html: `<h1>Welcome, ${displayName}!</h1><p>Your account is ready. Please verify your email to start your language learning adventure.</p>`,
  };

  return mailTransport.sendMail(mailOptions)
      .then(() => functions.logger.log(`Welcome email sent to: ${userEmail}`))
      .catch((error) => functions.logger.error("There was an error while sending the email:", error));
});

// 2. Güvenli Hesap Silme (Anonimleştirme) Fonksiyonu
exports.deleteUserAccount = functions.region("us-central1") // Firebase projenizin bölgesini yazın
    .https.onCall(async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Bu işlemi gerçekleştirmek için kimlik doğrulaması gereklidir.",
        );
      }

      const uid = context.auth.uid;

      try {
        // Firestore'daki kullanıcı dokümanını silmek yerine anonimleştir.
        const userRef = admin.firestore().collection("users").doc(uid);
        await userRef.update({
          displayName: "Silinmiş Kullanıcı",
          email: `${uid}@deleted.lingua.chat`,
          avatarUrl: "",
          status: "deleted",
          deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Kullanıcının Auth kaydını kalıcı olarak sil.
        await admin.auth().deleteUser(uid);

        return {success: true};
      } catch (error) {
        functions.logger.error("Hesap silinirken/anonimleştirilirken hata oluştu:", uid, error);
        throw new functions.https.HttpsError(
            "internal",
            "Hesap silinirken bir sunucu hatası oluştu.",
        );
      }
    });

// 3. Yeni Gönderi Oluşturulduğunda Kullanıcı Profilini Güncelleme Fonksiyonu
exports.onPostCreated = functions.firestore
    .document('posts/{postId}')
    .onCreate(async (snap, context) => {
        const postData = snap.data();
        const userId = postData.userId;
        const postId = context.params.postId;

        if (!userId) {
            functions.logger.error("Post oluşturuldu ancak userId bulunamadı:", postId);
            return null;
        }

        const userRef = admin.firestore().collection('users').doc(userId);

        try {
            await userRef.update({
                posts: admin.firestore.FieldValue.arrayUnion(postId)
            });
            functions.logger.log(`Kullanıcı ${userId} için Post ${postId} referansı eklendi.`);
            return null;
        } catch (error) {
            functions.logger.error("Kullanıcının post referansı güncellenirken hata oluştu:", error);
            return null;
        }
    });

// 4. Gönderi Silindiğinde Kullanıcı Profilini Güncelleme Fonksiyonu
exports.onPostDeleted = functions.firestore
    .document('posts/{postId}')
    .onDelete(async (snap, context) => {
        const postData = snap.data();
        const userId = postData.userId;
        const postId = context.params.postId;

        if (!userId) {
            functions.logger.error("Post silindi ancak userId bulunamadı:", postId);
            return null;
        }

        const userRef = admin.firestore().collection('users').doc(userId);

        try {
            await userRef.update({
                posts: admin.firestore.FieldValue.arrayRemove(postId)
            });
            functions.logger.log(`Kullanıcı ${userId} için Post ${postId} referansı kaldırıldı.`);
            return null;
        } catch (error) {
            functions.logger.error("Kullanıcının post referansı güncellenirken hata oluştu:", error);
            return null;
        }
    });