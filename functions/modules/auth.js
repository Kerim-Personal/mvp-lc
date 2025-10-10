/* eslint-disable no-console */
const { functions } = require('../shared');
const nodemailer = require('nodemailer');

exports.sendVerificationCode = functions.auth.user().onCreate((user) => {
  const userEmail = user.email;
  const displayName = user.displayName || 'User';
  if (!userEmail) return null;

  const gmailEmail = functions.config().gmail.email;
  const gmailPassword = functions.config().gmail.password;
  if (!gmailEmail || !gmailPassword) return null;

  const mailTransport = nodemailer.createTransport({
    service: 'gmail',
    auth: { user: gmailEmail, pass: gmailPassword },
  });

  const mailOptions = {
    from: `"VocaChat Team" <${gmailEmail}>`,
    to: userEmail,
    subject: 'Welcome to VocaChat!',
    html: `<h1>Welcome, ${displayName}!</h1><p>Your account is ready. Please verify your email to start your language learning adventure.</p>`,
  };

  return mailTransport.sendMail(mailOptions);
});

