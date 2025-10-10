/* eslint-disable no-console */
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { GoogleGenerativeAI, HarmCategory, HarmBlockThreshold } = require('@google/generative-ai');

// Initialize Admin SDK once per process
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function requirePremium(uid) {
  try {
    const snap = await db.collection('users').doc(uid).get();
    if (!snap.exists) {
      throw new functions.https.HttpsError('permission-denied','Premium gerekli (profil yok)');
    }
    const premium = snap.get('isPremium') === true;
    if (!premium) {
      throw new functions.https.HttpsError('permission-denied','Bu özellik için premium gerekli');
    }
  } catch (e) {
    if (e instanceof functions.https.HttpsError) throw e;
    console.error('requirePremium error', e);
    throw new functions.https.HttpsError('internal','Premium doğrulanamadı');
  }
}

module.exports = {
  functions,
  admin,
  db,
  GoogleGenerativeAI,
  HarmCategory,
  HarmBlockThreshold,
  requirePremium,
};
