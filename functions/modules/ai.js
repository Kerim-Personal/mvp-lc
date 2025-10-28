/* eslint-disable no-console */
const { functions } = require('../shared');
const { requirePremium } = require('../shared');
const {
  getGeminiClient,
  sanitizeReply,
  classifyIntent,
  buildSystemPrompt,
  checkDailyQuota,
  extractJson,
  heuristicGrammar,
  HarmCategory,
  HarmBlockThreshold,
} = require('../ai_utils');

exports.vocabotSend = functions.region('us-central1').https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated','Giriş gerekli');
  await requirePremium(context.auth.uid);
  await checkDailyQuota(context, 'vocabotSend');
  const message = (data && data.message)||'';
  const targetLanguage = (data && data.targetLanguage)||'en';
  const nativeLanguage = (data && data.nativeLanguage)||'en';
  const learningLevel = (data && data.learningLevel)||'medium';
  const scenario = (data && data.scenario) ? String(data.scenario).trim() : '';
  const chatHistory = (data && Array.isArray(data.chatHistory)) ? data.chatHistory : [];
  if (!message.trim()) throw new functions.https.HttpsError('invalid-argument','Boş mesaj');
  if (message.length > 1200) throw new functions.https.HttpsError('invalid-argument','Mesaj çok uzun');
  try {
    const genAI = getGeminiClient();
    const systemInstruction = buildSystemPrompt(targetLanguage, nativeLanguage, learningLevel);
    const intent = classifyIntent(message);
    const model = genAI.getGenerativeModel({
      model: 'gemini-2.5-flash-lite',
      systemInstruction,
      safetySettings: [
        {category: HarmCategory.HARM_CATEGORY_HARASSMENT, threshold: HarmBlockThreshold.BLOCK_NONE},
        {category: HarmCategory.HARM_CATEGORY_HATE_SPEECH, threshold: HarmBlockThreshold.BLOCK_NONE},
        {category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT, threshold: HarmBlockThreshold.BLOCK_NONE},
        {category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT, threshold: HarmBlockThreshold.BLOCK_NONE},
      ],
    });

    // Senaryo varsa ekle
    const scenarioNote = scenario ? `\n\nSCENARIO CONTEXT: ${scenario}\nStay in character and keep responses natural to this scenario.` : '';

    // Konuşma geçmişi - istemci zaten son 8 mesajı gönderiyor
    let conversationContext = '';
    if (chatHistory && chatHistory.length > 0) {
      const lines = chatHistory.map(msg => {
        const role = msg.role === 'user' ? 'Student' : 'Teacher';
        return `${role}: ${msg.content}`;
      });
      conversationContext = `\n\nCONVERSATION HISTORY:\n${lines.join('\n')}\n`;
    }

    // Basit ve temiz prompt - system instruction zaten her şeyi içeriyor
    const prompt = `${conversationContext}
Student's new message: "${message}"

Message intent: ${intent}${scenarioNote}

Respond naturally as their teacher.`;
    const result = await model.generateContent([{text: prompt}]);

    const reply = sanitizeReply(result.response.text());
    return {reply};
  } catch (e) {
    console.error('vocabotSend error', e);
    throw new functions.https.HttpsError('internal','VocaBot yanıt üretilemedi');
  }
});

exports.vocabotAnalyzeGrammar = functions.region('us-central1').https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated','Giriş gerekli');
  await requirePremium(context.auth.uid);
  await checkDailyQuota(context, 'vocabotAnalyzeGrammar');
  const userMessage = (data && data.userMessage)||'';
  const targetLanguage = (data && data.targetLanguage)||'en';
  const learningLevel = (data && data.learningLevel)||'medium';
  if (!userMessage.trim()) throw new functions.https.HttpsError('invalid-argument','Boş mesaj');
  try {
    const genAI = getGeminiClient();
    const model = genAI.getGenerativeModel({model:'gemini-2.5-flash-lite'});
    const maxErrors = (learningLevel==='none'||learningLevel==='low') ? 3 : 5;
    const explainLen = (learningLevel==='none'||learningLevel==='low') ? 6 : 8;
    const prompt = [
      `You are a concise grammar feedback engine for learners of ${targetLanguage}. Level: ${learningLevel}.`,
      'Return ONLY raw JSON (no markdown). Schema:',
      '{',
      '  "grammarScore": float (0..1),',
      '  "formality": "informal|neutral|formal",',
      '  "sentiment": float (-1..1),',
      '  "complexity": float (0..1),',
      '  ' + '"errors": [ { "original":"...", "correction":"...", "explanation":"short" } ],',
      '  "suggestions": ["short tip", ...]',
      '}',
      'Rules:',
      `- Max ${maxErrors} errors; only real mistakes.`,
      `- Keep explanations <= ${explainLen} words.`,
      '- If perfect: grammarScore=1, errors=[], give 1 improvement suggestion.',
      '- No extra fields.',
      `User message: "${userMessage}"`
    ].join('\n');
    const result = await model.generateContent([{text: prompt}]);
    const raw = (result.response.text()||'').trim();
    const start = raw.indexOf('{');
    const end = raw.lastIndexOf('}');
    let parsed = null;
    if (start !== -1 && end !== -1 && end>start) {
      try { parsed = JSON.parse(raw.substring(start, end+1)); } catch(_) { parsed = null; }
    }
    if (!parsed) parsed = heuristicGrammar(userMessage);
    return {analysis: parsed};
  } catch (e) {
    console.error('vocabotAnalyzeGrammar error', e);
    return {analysis: heuristicGrammar(userMessage)};
  }
});

exports.aiTranslate = functions.region('us-central1').https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated','Giriş gerekli');
  await requirePremium(context.auth.uid);
  await checkDailyQuota(context, 'aiTranslate');
  const text = (data && data.text)||'';
  const targetCode = (data && data.targetCode)||'en';
  const sourceCode = data && data.sourceCode;
  if (!text.trim()) return {translation: ''};
  try {
    const genAI = getGeminiClient();
    const model = genAI.getGenerativeModel({model:'gemini-2.5-flash-lite'});
    const prompt = [
      sourceCode ? `Source language: ${sourceCode}` : 'Detect the source language automatically',
      `Target language: ${targetCode}`,
      'RULES:',
      '- Output ONLY the translated sentence(s).',
      '- No quotes, no explanations, no language labels.',
      '- If already in target language, return original unchanged.',
      'TEXT:',
      text
    ].join('\n');
    const result = await model.generateContent([{text: prompt}]);
    let out = sanitizeReply(result.response.text());
    if ((out.startsWith('"') && out.endsWith('"')) || (out.startsWith("'") && out.endsWith("'"))) {
      out = out.slice(1,-1).trim();
    }
    return {translation: out};
  } catch (e) {
    console.error('aiTranslate error', e);
    return {translation: text};
  }
});

exports.vocabotGrammarQuiz = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    await requirePremium(context.auth.uid);
    // Günlük kota kontrolü: 150
    await checkDailyQuota(context, 'vocabotGrammarQuiz');
    const uid = context.auth.uid;

    function clampStr(v, max, def = '') {
      if (v == null) return def;
      const s = typeof v === 'string' ? v : String(v);
      return s.length > max ? s.slice(0, max).trim() : s.trim();
    }

    function takeStringLocal(obj, key, maxLen, required=true) {
      const v = obj && obj[key];
      if ((v == null || v === '') && !required) return '';
      if (typeof v !== 'string') throw new functions.https.HttpsError('invalid-argument', key + ' must be string');
      if (v.length > maxLen) throw new functions.https.HttpsError('invalid-argument', key + ' too long');
      return String(v).trim();
    }

    function fallbackQuiz(topicPath, topicTitle, targetLanguage, nativeLanguage) {
      return {
        quiz: {
          topicPath,
          topicTitle,
          question: `(${targetLanguage}) ${topicTitle}: Doğru seçeneği işaretle.`,
          options: ['A', 'B', 'C'],
          correctIndex: 0,
          onCorrectNative: 'Doğru! Kısa kural özeti.',
          onWrongNative: 'Yanlış. Kuralın kısa açıklaması.',
        }
      };
    }

    // Basit normalizasyon ve benzerlik araçları
    function normalizeQuestion(text) {
      if (!text) return '';
      const lower = String(text).toLowerCase();
      const cleaned = lower.replace(/[^a-z0-9çğıışöüáéíóúñäöüßâêîôûãõàèìòù¿¡]+/gi, ' ');
      return cleaned.split(/\s+/).filter(Boolean).join(' ');
    }
    function jaccardSimilarity(a, b) {
      const sa = new Set(normalizeQuestion(a).split(' ').filter(Boolean));
      const sb = new Set(normalizeQuestion(b).split(' ').filter(Boolean));
      if (sa.size === 0 && sb.size === 0) return 1;
      if (sa.size === 0 || sb.size === 0) return 0;
      let inter = 0;
      for (const t of sa) if (sb.has(t)) inter++;
      const union = sa.size + sb.size - inter;
      return inter / union;
    }
    function isTooSimilar(question, excludes, threshold) {
      if (!question || !Array.isArray(excludes) || excludes.length === 0) return false;
      const qn = normalizeQuestion(question);
      for (const prev of excludes) {
        const pn = normalizeQuestion(prev);
        if (!pn) continue;
        if (pn.length > 8 && (qn.includes(pn) || pn.includes(qn))) return true;
        const sim = jaccardSimilarity(pn, qn);
        if (sim >= threshold) return true;
      }
      return false;
    }

    let topicPath, topicTitle, targetLanguage, nativeLanguage, learningLevel, excludeQuestions;
    try {
      topicPath = takeStringLocal(data, 'topicPath', 64);
      topicTitle = takeStringLocal(data, 'topicTitle', 120);
      targetLanguage = takeStringLocal(data, 'targetLanguage', 8);
      nativeLanguage = takeStringLocal(data, 'nativeLanguage', 8);
      learningLevel = takeStringLocal(data, 'learningLevel', 16, false) || 'medium';
      // excludeQuestions: optional array of strings (limit 10, each <= 200 chars)
      const rawEx = Array.isArray(data && data.excludeQuestions) ? data.excludeQuestions : [];
      excludeQuestions = rawEx
        .map((s) => (typeof s === 'string' ? s.trim() : ''))
        .filter((s) => s)
        .slice(0, 10)
        .map((s) => (s.length > 200 ? s.slice(0, 200) : s));
    } catch (argErr) {
      console.warn('vocabotGrammarQuiz invalid args, serving fallback', { uid, err: String(argErr) });
      topicPath = clampStr(data && data.topicPath, 64, 'general');
      topicTitle = clampStr(data && data.topicTitle, 120, 'General grammar');
      targetLanguage = clampStr(data && data.targetLanguage, 8, 'en');
      nativeLanguage = clampStr(data && data.nativeLanguage, 8, 'en');
      learningLevel = clampStr(data && data.learningLevel, 16, 'medium') || 'medium';
      excludeQuestions = [];
      return fallbackQuiz(topicPath, topicTitle, targetLanguage, nativeLanguage);
    }

    let model;
    try {
      const gen = getGeminiClient();
      model = gen.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
    } catch (e) {
      console.warn('vocabotGrammarQuiz: Gemini client unavailable, serving fallback', { uid, topicPath });
      return fallbackQuiz(topicPath, topicTitle, targetLanguage, nativeLanguage);
    }

    // Sunucu tarafı retry ve çeşitlilik zorlama
    const maxTries = 6;
    const similarityThreshold = 0.8;

    try {
      let lastParsed = null;
      for (let attempt = 0; attempt < maxTries; attempt++) {
        const avoidBlock = excludeQuestions && excludeQuestions.length
          ? `\nAvoid repeating or paraphrasing ANY of these previous questions (make it clearly different in syntax and content):\n- ${excludeQuestions.join('\n- ').slice(0, 1200)}`
          : '';

        const sys = `You are a concise language tutor. Create ONE multiple-choice question (3 options, exactly one correct) in the learner's target language about the given grammar topic.
- Keep the question short and clear.
- Make distractors plausible.
- Vary structure between attempts (tense, person, negation/affirmation, examples) to avoid repetition.${attempt>0 ? '\n- Your last try was too similar. Create a substantially different question now.' : ''}
- Difficulty should align with level: ${learningLevel}.
- Return STRICT JSON only with fields: topicPath, topicTitle, question, options (array of 3 strings), correctIndex (0..2), onCorrectNative (string), onWrongNative (string).
- onCorrectNative: congratulate and give a VERY brief summary of the rule in ${nativeLanguage}.
- onWrongNative: explain the correct rule briefly in ${nativeLanguage}, optionally give one short example.
- Do NOT include any extra commentary or markdown.
- Ensure options length is exactly 3 and only one correct.
- The question must be written in the target language (${targetLanguage}).${avoidBlock}`;

        const user = `Topic: ${topicTitle} (${topicPath})\nTarget language: ${targetLanguage}\nNative language: ${nativeLanguage}`;

        const resp = await model.generateContent({ contents: [
          { role: 'user', parts: [{ text: sys + '\n\n' + user }] },
        ]});
        const text = resp?.response?.text?.();
        const parsed = extractJson(text);
        lastParsed = parsed;
        if (!parsed || !parsed.question || !Array.isArray(parsed.options) || parsed.options.length !== 3 || typeof parsed.correctIndex !== 'number') {
          console.warn('Invalid quiz JSON (attempt ' + attempt + '), retrying', { uid, topicPath });
          continue;
        }
        const quiz = {
          topicPath,
          topicTitle,
          question: String(parsed.question).trim(),
          options: parsed.options.map((o) => String(o).trim()).slice(0,3),
          correctIndex: Math.max(0, Math.min(2, parseInt(parsed.correctIndex, 10))),
          onCorrectNative: String(parsed.onCorrectNative || '').trim() || 'Doğru!',
          onWrongNative: String(parsed.onWrongNative || '').trim() || 'Yanlış.',
        };
        if (!isTooSimilar(quiz.question, excludeQuestions, similarityThreshold)) {
          return { quiz };
        } else {
          console.warn('Quiz too similar to recent, retrying', { uid, topicPath });
          // Bir sonraki denemede aynı listeden kaçınmaya devam edeceğiz
        }
      }
      // Max denemeden sonra son geçerli parse veya fallback
      if (lastParsed && lastParsed.question && Array.isArray(lastParsed.options) && lastParsed.options.length === 3) {
        const quiz = {
          topicPath,
          topicTitle,
          question: String(lastParsed.question).trim(),
          options: lastParsed.options.map((o) => String(o).trim()).slice(0,3),
          correctIndex: Math.max(0, Math.min(2, parseInt(lastParsed.correctIndex, 10) || 0)),
          onCorrectNative: String(lastParsed.onCorrectNative || '').trim() || 'Doğru!',
          onWrongNative: String(lastParsed.onWrongNative || '').trim() || 'Yanlış.',
        };
        return { quiz };
      }
      return fallbackQuiz(topicPath, topicTitle, targetLanguage, nativeLanguage);
    } catch (e) {
      console.error('vocabotGrammarQuiz error, serving fallback', e);
      return fallbackQuiz(topicPath, topicTitle, targetLanguage, nativeLanguage);
    }
  });
