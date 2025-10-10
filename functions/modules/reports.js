/* eslint-disable no-console */
const { functions, admin, db } = require('../shared');

exports.onReportCreated = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snap, _context) => {
    try {
      const data = snap.data() || {};
      const contentId = data.reportedContentId;
      if (!contentId) return null;
      const contentType = data.reportedContentType || null;
      const parentId = data.reportedContentParentId || null;
      const reportedUserId = data.reportedUserId || null;
      const aggRef = db.collection('content_reports').doc(contentId);
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
      await snap.ref.set({ aggregateCount: newCount }, { merge: true });
    } catch (e) {
      console.error('onReportCreated aggregation error:', e);
    }
    return null;
  });

exports.createReport = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Giriş gerekli');
    }
    const uid = context.auth.uid;
    const now = Date.now();
    const MIN_INTERVAL_MS = 15 * 1000;
    const WINDOW_MS = 60 * 60 * 1000;
    const WINDOW_LIMIT = 20;

    function takeString(key, maxLen, required = true) {
      const v = data[key];
      if ((v == null || v === '') && !required) return '';
      if (typeof v !== 'string') {
        throw new functions.https.HttpsError('invalid-argument', key + ' string değil');
      }
      if (v.length > maxLen) {
        throw new functions.https.HttpsError('invalid-argument', key + ' çok uzun');
      }
      return v.trim();
    }

    const reportedUserId = takeString('reportedUserId', 128);
    const reason = takeString('reason', 120);
    const details = takeString('details', 2000, false);
    const reportedContent = takeString('reportedContent', 4000, false);
    const reportedContentId = takeString('reportedContentId', 256, false);
    const reportedContentType = takeString('reportedContentType', 64, false);
    const reportedContentParentId = takeString('reportedContentParentId', 256, false);

    const rlRef = db.collection('rate_limits').doc('reports_' + uid);
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
            throw new functions.https.HttpsError('resource-exhausted', 'Çok hızlı raporlama (bekleyin)');
          }
          if (count >= WINDOW_LIMIT) {
            throw new functions.https.HttpsError('resource-exhausted', 'Saatlik rapor limiti aşıldı');
          }
        }
        count += 1;
        tx.set(rlRef, { lastAt: now, windowStart, count }, { merge: true });
      });

      let docId = undefined;
      if (reportedContentId) docId = uid + '_' + reportedContentId;
      const reportsCol = db.collection('reports');
      if (docId) {
        const exist = await reportsCol.doc(docId).get();
        if (exist.exists) {
          throw new functions.https.HttpsError('already-exists', 'Bu içeriği zaten raporladınız');
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
        status: 'pending',
        serverAuth: true,
      };
      if (docId) {
        await reportsCol.doc(docId).set(baseData, { merge: false });
      } else {
        await reportsCol.add(baseData);
      }
      return { success: true };
    } catch (e) {
      if (e instanceof functions.https.HttpsError) throw e;
      console.error('createReport error:', e);
      throw new functions.https.HttpsError('internal', 'Rapor hatası');
    }
  });

