// Firebase v2
const {onUserCreated} = require("firebase-functions/v2/auth");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const functions = require("firebase-functions");

admin.initializeApp();

// E-posta gönderim fonksiyonu
exports.sendVerificationCode = onUserCreated(async (event) => {
  const user = event.data; // v2'de kullanıcı bilgisi buradan alınır
  const userEmail = user.email;
  const displayName = user.displayName || "User";
  const userId = user.uid;

  if (!userEmail) {
    logger.log(`User ${userId} does not have an email address.`);
    return;
  }

  // Güvenli ayarları fonksiyonun içinden okuma
  const gmailEmail = functions.config().gmail.email;
  const gmailPassword = functions.config().gmail.password;

  if (!gmailEmail || !gmailPassword) {
      logger.error("Gmail credentials are not set in functions config.");
      return;
  }

  const mailTransport = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: gmailEmail,
      pass: gmailPassword,
    },
  });

  const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = admin.firestore.Timestamp.fromMillis(Date.now() + 15 * 60 * 1000);

  try {
    await admin.firestore().collection("users").doc(userId).update({
      verificationCode: verificationCode,
      verificationCodeExpiresAt: expiresAt,
    });
    logger.log(`Successfully stored verification code for user: ${userId}`);
  } catch (error) {
    logger.error(`Error storing verification code for ${userId}:`, error);
    return;
  }

  const mailOptions = {
    from: `"LinguaChat Team" <${gmailEmail}>`,
    to: userEmail,
    subject: "Your Verification Code for LinguaChat",
    html: `<h1>Welcome to LinguaChat, ${displayName}!</h1><p>Here is your verification code to activate your account:</p><p style="font-size: 24px; font-weight: bold; letter-spacing: 2px;">${verificationCode}</p><p>This code will expire in 15 minutes.</p>`,
  };

  try {
    await mailTransport.sendMail(mailOptions);
    logger.log(`Verification email sent to: ${userEmail}`);
  } catch (error) {
    logger.error("There was an error while sending the email:", error);
  }
});