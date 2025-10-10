/* eslint-disable no-console */
const { functions, admin, db } = require('../shared');

exports.setPremiumStatus = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Giriş gerekli');
    }
    const uid = context.auth.uid;

    function takeBool(key) {
      const v = data && data[key];
      if (typeof v === 'boolean') return v;
      if (v === 'true') return true;
      if (v === 'false') return false;
      return undefined;
    }
    function takeStr(key, maxLen) {
      const v = data && data[key];
      if (v == null) return null;
      const s = String(v).trim();
      if (!s) return null;
      return s.length > maxLen ? s.slice(0, maxLen) : s;
    }

    const isPremium = takeBool('isPremium');
    if (typeof isPremium !== 'boolean') {
      throw new functions.https.HttpsError('invalid-argument', 'isPremium zorunlu ve boolean olmalı');
    }

    const payload = {
      isPremium: isPremium,
      premiumEntitlementId: takeStr('premiumEntitlementId', 64),
      premiumWillRenew: takeBool('premiumWillRenew'),
      premiumStore: takeStr('premiumStore', 32),
      premiumPeriodType: takeStr('premiumPeriodType', 32),
      premiumOriginalPurchaseDateIso: takeStr('premiumOriginalPurchaseDateIso', 40),
      premiumLatestPurchaseDateIso: takeStr('premiumLatestPurchaseDateIso', 40),
      premiumExpirationDateIso: takeStr('premiumExpirationDateIso', 40),
      premiumProductIdentifier: takeStr('premiumProductIdentifier', 80),
      premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    try {
      await db.collection('users').doc(uid).set(payload, { merge: true });
      return { success: true, isPremium };
    } catch (e) {
      console.error('setPremiumStatus error', e);
      throw new functions.https.HttpsError('internal', 'Premium güncellenemedi');
    }
  });

