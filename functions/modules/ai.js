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
    const scenarioBlock = scenario ? `\nSCENARIO: ${scenario}\nROLE: Act within this scenario. Keep responses contextual and realistic. Use short, natural dialogue lines.` : '';
    const augmented = `USER_MESSAGE: "${message}"\nINTENT: ${intent}${scenarioBlock}\nGUIDELINES: Keep it short (<=2 sentences) unless explanation asked. Natural tone.`;
    const result = await model.generateContent([{text: augmented}]);
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

    let topicPath, topicTitle, targetLanguage, nativeLanguage, learningLevel;
    try {
      topicPath = takeStringLocal(data, 'topicPath', 64);
      topicTitle = takeStringLocal(data, 'topicTitle', 120);
      targetLanguage = takeStringLocal(data, 'targetLanguage', 8);
      nativeLanguage = takeStringLocal(data, 'nativeLanguage', 8);
      learningLevel = takeStringLocal(data, 'learningLevel', 16, false) || 'medium';
    } catch (argErr) {
      console.warn('vocabotGrammarQuiz invalid args, serving fallback', { uid, err: String(argErr) });
      topicPath = clampStr(data && data.topicPath, 64, 'general');
      topicTitle = clampStr(data && data.topicTitle, 120, 'General grammar');
      targetLanguage = clampStr(data && data.targetLanguage, 8, 'en');
      nativeLanguage = clampStr(data && data.nativeLanguage, 8, 'en');
      learningLevel = clampStr(data && data.learningLevel, 16, 'medium') || 'medium';
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

    try {
      const sys = `You are a concise language tutor. Create ONE multiple-choice question (3 options, exactly one correct) in the learner's target language about the given grammar topic.
- Keep the question short and clear.
- Make distractors plausible.
- Difficulty should align with level: ${learningLevel}.
- Return STRICT JSON only with fields: topicPath, topicTitle, question, options (array of 3 strings), correctIndex (0..2), onCorrectNative (string), onWrongNative (string).
- onCorrectNative: congratulate and give a VERY brief summary of the rule in ${nativeLanguage}.
- onWrongNative: explain the correct rule briefly in ${nativeLanguage}, optionally give one short example.
- Do NOT include any extra commentary or markdown.
- Ensure options length is exactly 3 and only one correct.
- The question must be written in the target language (${targetLanguage}).`;

      const user = `Topic: ${topicTitle} (${topicPath})\nTarget language: ${targetLanguage}\nNative language: ${nativeLanguage}`;

      const resp = await model.generateContent({ contents: [
        { role: 'user', parts: [{ text: sys + '\n\n' + user }] },
      ]});
      const text = resp?.response?.text?.();
      const parsed = extractJson(text);
      if (!parsed || !parsed.question || !Array.isArray(parsed.options) || parsed.options.length !== 3 || typeof parsed.correctIndex !== 'number') {
        console.warn('Invalid quiz JSON, serving fallback', { uid, topicPath });
        return fallbackQuiz(topicPath, topicTitle, targetLanguage, nativeLanguage);
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
      return { quiz };
    } catch (e) {
      console.error('vocabotGrammarQuiz error, serving fallback', e);
      return fallbackQuiz(topicPath, topicTitle, targetLanguage, nativeLanguage);
    }
  });

