/* eslint-disable no-console */
const functions = require("firebase-functions");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const db = admin.firestore();

/**
 * Kullanıcının premium durumunu güvenli şekilde günceller.
 * İstemci RevenueCat durumunu iletir; bu fonksiyon sadece kimliği doğrulanmış
 * kullanıcı için kendi users/{uid} belgesini günceller. (Admin SDK kuralları bypass eder.)
 * Not: Üretimde RevenueCat Webhook/Server API ile doğrulama önerilir.
 */
exports.setPremiumStatus = onCall({ region: "us-central1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Giriş gerekli");
  }

  const data = request.data || {};
  const uid = request.auth.uid;

  // Yardımcılar: ISO string ya da millis -> Timestamp
  const toMillis = (v) => {
    if (v == null) return null;
    if (typeof v === 'number' && Number.isFinite(v) && v > 0) return v;
    if (typeof v === 'string') {
      const d = new Date(v);
      const m = d.getTime();
      if (Number.isFinite(m) && m > 0) return m;
    }
    return null;
  };
  const toStr = (v, max = 256) => (typeof v === 'string' ? v.slice(0, max) : null);

  // ISO ya da millis anahtarları - her ikisini de destekle
  const originalMs = toMillis(data?.premiumOriginalPurchaseDateMillis ?? data?.premiumOriginalPurchaseDateIso);
  const latestMs = toMillis(data?.premiumLatestPurchaseDateMillis ?? data?.premiumLatestPurchaseDateIso);
  const expirationMs = toMillis(data?.premiumExpirationDateMillis ?? data?.premiumExpirationDateIso);

  // Sinyaller (erken okunur ki isPremium hesaplamasında kullanılabilsin)
  const prodIdRaw = toStr(data?.premiumProductIdentifier, 128);
  const willRenewSignal = (data?.premiumWillRenew === true);

  // Mevcut belgeyi oku (korumalı birleştirme için)
  let prev = null;
  try {
    const snap = await db.collection('users').doc(uid).get();
    prev = snap.exists ? (snap.data() || null) : null;
  } catch (e) {
    // okuması başarısız olsa da devam edebiliriz
    console.error('setPremiumStatus read error:', e);
  }

  const nowMs = Date.now();

  // isPremium hesapla (asla yanlışlıkla false'a düşürme)
  const requestedIsPremium = data?.isPremium === true;
  let newIsPremium = requestedIsPremium;

  // Expiration gelecekte ise premium kesinlikle true kabul edilir
  if (expirationMs && expirationMs > nowMs) {
    newIsPremium = true;
  }

  // Otomatik yenileme sinyali true ise premium kabul et (özellikle iOS/Android RC gecikmelerinde)
  if (!newIsPremium && willRenewSignal) {
    newIsPremium = true;
  }

  // Ürün kimliği premium içeriyorsa (entitlement yoksa dahi) premium kabul et
  if (!newIsPremium && typeof prodIdRaw === 'string') {
    try {
      if (/\bpremium\b/i.test(prodIdRaw) || prodIdRaw.toLowerCase().startsWith('premium') || prodIdRaw.toLowerCase().includes('premium:')) {
        newIsPremium = true;
      }
    } catch (_) { /* yut */ }
  }

  // İstemci false gönderirse ama daha önce premium ve süresi dolmadı ise premium'u koru
  if (!newIsPremium && prev) {
    const prevExp = prev.premiumExpirationDate && prev.premiumExpirationDate.toMillis ? prev.premiumExpirationDate.toMillis() : null;
    if (prev.isPremium === true && prevExp && prevExp > nowMs) {
      newIsPremium = true;
    }
  }

  const updated = {
    // yalnıza hesaplanmış değer yazılır
    isPremium: newIsPremium,
    premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  // String alanları sadece non-null ise güncelle (aksi halde mevcut veriyi koru)
  const strFields = {
    premiumEntitlementId: toStr(data?.premiumEntitlementId, 128),
    premiumWillRenew: (data?.premiumWillRenew === true || data?.premiumWillRenew === false) ? data.premiumWillRenew : null,
    premiumStore: toStr(data?.premiumStore, 64),
    premiumPeriodType: toStr(data?.premiumPeriodType, 32),
    premiumProductIdentifier: toStr(data?.premiumProductIdentifier, 128),
  };
  for (const [k, v] of Object.entries(strFields)) {
    if (v !== null) updated[k] = v;
  }

  // Tarih alanları da sadece sağlanmışsa güncellenir; yoksa mevcut saklanır
  if (originalMs) updated.premiumOriginalPurchaseDate = admin.firestore.Timestamp.fromMillis(originalMs);
  if (latestMs) updated.premiumLatestPurchaseDate = admin.firestore.Timestamp.fromMillis(latestMs);
  if (expirationMs) updated.premiumExpirationDate = admin.firestore.Timestamp.fromMillis(expirationMs);

  // Basit tanılama logu
  try {
    console.log('setPremiumStatus', {
      uid,
      requestedIsPremium,
      willRenewSignal,
      hasProdId: !!prodIdRaw,
      hasExpiration: !!expirationMs,
      newIsPremium,
    });
  } catch (_) { /* yut */ }

  try {
    await db.collection('users').doc(uid).set(updated, { merge: true });
    return { success: true, isPremium: newIsPremium };
  } catch (e) {
    console.error('setPremiumStatus write error:', e);
    throw new HttpsError('internal', 'Premium güncellemesi başarısız');
  }
});
