/* eslint-disable no-console */
const { functions, admin, db } = require('../shared');

// RevenueCat webhook endpoint
// Güvenlik: İsteğe bağlı gizli anahtar doğrulaması (Bearer veya X-Webhook-Secret veya ?secret=)
// Config kaynağı: process.env.RC_WEBHOOK_SECRET veya functions.config().revenuecat.webhook_secret
exports.revenuecatWebhook = functions
  .region('us-central1')
  .https.onRequest(async (req, res) => {
    try {
      if (req.method !== 'POST') {
        res.set('Allow', 'POST');
        return res.status(405).send('Method Not Allowed');
      }

      // Auth check (optional but recommended)
      const cfg = (functions.config && functions.config().revenuecat) || {};
      const secretCfg = process.env.RC_WEBHOOK_SECRET || cfg.webhook_secret;
      const bearer = (req.get('Authorization') || '').replace(/^Bearer\s+/i, '').trim();
      const headerSecret = (req.get('X-Webhook-Secret') || '').trim();
      const querySecret = (req.query && (req.query.secret || req.query.token)) || '';

      const provided = String(bearer || headerSecret || querySecret || '');
      if (secretCfg) {
        if (!provided || provided !== String(secretCfg)) {
          console.warn('Webhook unauthorized');
          return res.status(401).json({ ok: false, error: 'unauthorized' });
        }
      } else {
        console.warn('RevenueCat webhook secret is not configured; accepting requests without verification.');
      }

      // Parse body (JSON expected). If empty, try rawBody.
      let payload = req.body;
      if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
        try {
          const raw = req.rawBody && req.rawBody.toString('utf8');
          if (raw) payload = JSON.parse(raw);
        } catch (_) { /* ignore */ }
      }
      if (!payload || typeof payload !== 'object') {
        return res.status(400).json({ ok: false, error: 'invalid_payload' });
      }

      // Extract fields in a schema-tolerant way
      const nowMs = Date.now();
      const ev = payload.event || payload; // bazı gönderimlerde kök seviyede olabilir

      const uid = ev.app_user_id || payload.app_user_id || ev.user_id || ev.uid;
      const eventType = (ev.type || ev.event_type || ev.event || '').toString().toUpperCase();

      // Expiration timestamps (ms)
      const expirationMs = num(ev.expiration_at_ms ?? ev.expires_at_ms ?? ev.expiration_ms);
      const originalMs = num(ev.original_purchase_date_ms ?? ev.original_purchase_ms ?? ev.purchased_at_ms);
      const latestMs = num(ev.latest_purchase_date_ms ?? ev.latest_purchase_ms ?? ev.renewed_at_ms ?? ev.purchase_date_ms);

      // Product / entitlement metadata
      const entitlementId = str(ev.entitlement_id ?? ev.entitlement ?? firstKey(ev.entitlements));
      const productId = str(ev.product_id ?? ev.product_identifier ?? ev.product ?? fromEnt(ev, 'product_identifier'));
      const store = str(ev.store ?? fromEnt(ev, 'store'));
      const periodType = str(ev.period_type ?? fromEnt(ev, 'period_type'));
      const willRenew = boolish(ev.will_renew ?? ev.auto_resume ?? fromEnt(ev, 'will_renew'));

      // Premium hesaplama: süre dolmadıysa aktif say
      let isPremium = false;
      if (typeof expirationMs === 'number' && !Number.isNaN(expirationMs)) {
        isPremium = expirationMs > nowMs;
      } else {
        // Zaman bilgisi yoksa etkinlik tipine göre çıkarım
        const positive = ['INITIAL_PURCHASE', 'RENEWAL', 'PRODUCT_CHANGE', 'UNCANCELLATION', 'NON_RENEWING_PURCHASE'];
        const negative = ['EXPIRATION', 'CANCELLATION', 'BILLING_ISSUE'];
        if (positive.includes(eventType)) isPremium = true;
        if (negative.includes(eventType)) isPremium = false;
      }

      if (!uid) {
        console.warn('Webhook missing app_user_id; skipping write.');
        return res.status(200).json({ ok: true, skipped: true });
      }

      // DÜZELTİLMİŞ KOD BLOĞU (BUNU KULLAN)

      const toIso = (ms) => (typeof ms === 'number' && !Number.isNaN(ms) ? new Date(ms).toISOString() : null);

      const update = {
        isPremium: isPremium,
        // Değer yoksa 'undefined' yerine 'null' kullanıyoruz.
        premiumEntitlementId: entitlementId ?? null,
        premiumWillRenew: typeof willRenew === 'boolean' ? willRenew : null,
        premiumStore: store ?? null,
        premiumPeriodType: periodType ?? null,
        premiumOriginalPurchaseDateIso: toIso(originalMs),
        premiumLatestPurchaseDateIso: toIso(latestMs),
        premiumExpirationDateIso: toIso(expirationMs),
        premiumProductIdentifier: productId ?? null,
        premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Yazma: test kancası veya Firestore
      if (process.env.MOCK_FIRESTORE === '1') {
        global.__TEST_WRITES = global.__TEST_WRITES || [];
        global.__TEST_WRITES.push({ uid: String(uid), update });
      } else {
        await db.collection('users').doc(String(uid)).set(update, { merge: true });
      }

      return res.status(200).json({ ok: true });
    } catch (e) {
      console.error('revenuecatWebhook error', e);
      return res.status(500).json({ ok: false, error: 'internal' });
    }
  });

// Helpers
function str(v) {
  if (v == null) return undefined;
  const s = String(v).trim();
  return s.length ? s : undefined;
}
function num(v) {
  if (v == null) return undefined;
  const n = typeof v === 'string' ? Number(v) : v;
  return Number.isFinite(n) ? n : undefined;
}
function boolish(v) {
  if (typeof v === 'boolean') return v;
  if (typeof v === 'string') {
    const s = v.toLowerCase();
    if (s === 'true') return true;
    if (s === 'false') return false;
  }
  return undefined;
}
function firstKey(obj) {
  if (!obj || typeof obj !== 'object') return undefined;
  const keys = Object.keys(obj);
  return keys.length ? keys[0] : undefined;
}
function fromEnt(ev, key) {
  // Bazı payload'larda entitlements: { <id>: { product_identifier, store, ... } }
  try {
    const entKey = firstKey(ev.entitlements);
    if (!entKey) return undefined;
    const ent = ev.entitlements[entKey];
    const val = ent && ent[key];
    return val == null ? undefined : val;
  } catch (_) {
    return undefined;
  }
}
