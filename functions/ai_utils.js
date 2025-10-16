/* eslint-disable no-console */
const { functions, admin, GoogleGenerativeAI, HarmCategory, HarmBlockThreshold } = require('./shared');

function getGeminiClient() {
  const key = (functions.config().gemini && functions.config().gemini.key) || process.env.GEMINI_API_KEY;
  if (!key) {
    throw new functions.https.HttpsError('failed-precondition', 'Gemini API anahtarı eksik (functions:config:set gemini.key=...)');
  }
  return new GoogleGenerativeAI(key);
}

function sanitizeReply(text) {
  if (!text) return '';
  let t = text.trim();
  if (t.startsWith('```')) {
    t = t.replace(/^```[a-zA-Z0-9]*\n?/, '').replace(/```$/,'').trim();
  }
  t = t.replace(/\n{3,}/g, '\n\n');
  return t;
}

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
  // Tüm işlemler için varsayılan günlük limitler 150
  const defaults = {
    vocabotSend: 150,
    vocabotAnalyzeGrammar: 150,
    aiTranslate: 150,
    vocabotGrammarQuiz: 150,
  };
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

async function checkDailyQuota(context, key) {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated','Giriş gerekli');
  const uid = context.auth.uid;
  const today = new Date();
  const ymd = today.toISOString().slice(0,10).replace(/-/g,'');
  const ref = admin.firestore().collection('ai_usage').doc(uid + '_' + ymd);
  const limit = resolveDailyLimit(key);
  try {
    await admin.firestore().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const base = snap.exists ? (snap.data() || {}) : { uid, date: ymd, counts: {} };
      const counts = base.counts || {};
      const current = counts[key] || 0;
      if (current >= limit) {
        throw new functions.https.HttpsError('resource-exhausted', `Günlük ${key} limiti aşıldı (${limit})`);
      }
      counts[key] = current + 1;
      base.counts = counts;
      base.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      if (!snap.exists) base.createdAt = admin.firestore.FieldValue.serverTimestamp();
      tx.set(ref, base, { merge: true });
    });
  } catch (e) {
    if (e instanceof functions.https.HttpsError) throw e;
    console.error('checkDailyQuota error', e);
    throw new functions.https.HttpsError('internal','Kota kontrolü başarısız');
  }
}

function extractJson(text) {
  if (!text) return null;
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

module.exports = {
  getGeminiClient,
  sanitizeReply,
  classifyIntent,
  buildSystemPrompt,
  resolveDailyLimit,
  checkDailyQuota,
  extractJson,
  heuristicGrammar,
  HarmCategory,
  HarmBlockThreshold,
};
