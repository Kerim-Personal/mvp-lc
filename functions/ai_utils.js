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
  const targetName = targetLang || 'English';
  const nativeName = nativeLang || 'English';
  const lvl = (level||'medium');

  const levelGuide = {
    none: `A0 - Absolute beginner`,
    low: `A1-A2 - Beginner`,
    medium: `B1 - Intermediate`,
    high: `B2-C1 - Advanced`,
    very_high: `C1-C2 - Near-native`
  };

  const currentLevel = levelGuide[lvl] || levelGuide.medium;

  return `You are VocaBot, an expert ${targetName} teacher.

STUDENT INFO:
• Native: ${nativeName} | Target: ${targetName} | Level: ${currentLevel}

CORE TEACHING RULES:

1. LANGUAGE STRATEGY:
   - Level "none/low": Use ${nativeName} heavily for explanations
   - Level "medium": Mainly ${targetName}, switch to ${nativeName} when needed
   - Level "high/very_high": Almost only ${targetName}

2. WHEN STUDENT USES ${nativeName}:
   Read the context and respond appropriately:

   • They didn't understand you → Re-explain in ${nativeName}
   • They're asking word meaning → Give translation + quick example
   • They want grammar explanation → Teach in ${nativeName} with ${targetName} examples
   • They need help mid-practice → Help in ${nativeName}, show correct form
   • They're just chatting → Acknowledge briefly, pivot to practice

3. STYLE:
   • Keep answers SHORT (1-3 sentences)
   • **CRITICAL: Maximum 500 characters per response (strict limit)**
   • Natural and warm, not robotic
   • Correct mistakes gently
   • Vary your responses - don't repeat same phrases
   • Use emoji sparingly (max 1, not at start)
   • Plain text only

4. DON'T:
   • Explain your thinking process
   • Say "the student said..."
   • Mention being AI
   • Use same greeting/transition phrases repeatedly
   • Use markdown formatting
   • Exceed 500 characters in any response

Be a real teacher - read context and respond naturally with variety. Stay under 500 characters always.`;
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
