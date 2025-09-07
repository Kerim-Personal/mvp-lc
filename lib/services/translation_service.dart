// lib/services/translation_service.dart
// Premium kullanıcılar için İngilizceden kullanıcının anadil koduna çeviri sağlar.

import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:flutter/foundation.dart';
import 'dart:collection';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

class TranslationModelDownloadState {
  final bool inProgress;
  final int downloaded;
  final int total;
  final String? error;
  final bool completed;
  final String? targetCode;

  const TranslationModelDownloadState({
    required this.inProgress,
    required this.downloaded,
    required this.total,
    required this.error,
    required this.completed,
    required this.targetCode,
  });

  factory TranslationModelDownloadState.initial() => const TranslationModelDownloadState(
        inProgress: false,
        downloaded: 0,
        total: 0,
        error: null,
        completed: false,
        targetCode: null,
      );

  TranslationModelDownloadState copyWith({
    bool? inProgress,
    int? downloaded,
    int? total,
    String? error,
    bool? completed,
    String? targetCode,
  }) {
    return TranslationModelDownloadState(
      inProgress: inProgress ?? this.inProgress,
      downloaded: downloaded ?? this.downloaded,
      total: total ?? this.total,
      error: error,
      completed: completed ?? this.completed,
      targetCode: targetCode ?? this.targetCode,
    );
  }
}

class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  final Map<String, OnDeviceTranslator> _translators = {};
  // key: "text|target". Basit LRU için LinkedHashMap kullanılır.
  final LinkedHashMap<String, String> _cache = LinkedHashMap();
  static const int _cacheLimit = 500; // makul bir sınır

  // Desteklenen 59 dil (ISO 639-1 kodu -> Görünen ad)
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'af', 'label': 'Afrikaans'},
    {'code': 'sq', 'label': 'Shqip'},
    {'code': 'ar', 'label': 'العربية'},
    {'code': 'be', 'label': 'Беларуская'},
    {'code': 'bg', 'label': 'Български'},
    {'code': 'bn', 'label': 'বাংলা'},
    {'code': 'ca', 'label': 'Català'},
    {'code': 'zh', 'label': '中文'},
    {'code': 'hr', 'label': 'Hrvatski'},
    {'code': 'cs', 'label': 'Čeština'},
    {'code': 'da', 'label': 'Dansk'},
    {'code': 'nl', 'label': 'Nederlands'},
    {'code': 'en', 'label': 'English'},
    {'code': 'eo', 'label': 'Esperanto'},
    {'code': 'et', 'label': 'Eesti'},
    {'code': 'fi', 'label': 'Suomi'},
    {'code': 'fr', 'label': 'Français'},
    {'code': 'gl', 'label': 'Galego'},
    {'code': 'ka', 'label': 'ქართული'},
    {'code': 'de', 'label': 'Deutsch'},
    {'code': 'el', 'label': 'Ελληνικά'},
    {'code': 'gu', 'label': 'ગુજરાતી'},
    {'code': 'he', 'label': 'עברית'},
    {'code': 'hi', 'label': 'हिन्दी'},
    {'code': 'hu', 'label': 'Magyar'},
    {'code': 'is', 'label': 'Íslenska'},
    {'code': 'id', 'label': 'Bahasa Indonesia'},
    {'code': 'ga', 'label': 'Gaeilge'},
    {'code': 'it', 'label': 'Italiano'},
    {'code': 'ja', 'label': '日本語'},
    {'code': 'kn', 'label': 'ಕನ್ನಡ'},
    {'code': 'ko', 'label': '한국어'},
    {'code': 'lv', 'label': 'Latviešu'},
    {'code': 'lt', 'label': 'Lietuvių'},
    {'code': 'mk', 'label': 'Македонски'},
    {'code': 'ms', 'label': 'Bahasa Melayu'},
    {'code': 'mt', 'label': 'Malti'},
    {'code': 'no', 'label': 'Norsk'},
    {'code': 'fa', 'label': 'فارسی'},
    {'code': 'pl', 'label': 'Polski'},
    {'code': 'pt', 'label': 'Português'},
    {'code': 'ro', 'label': 'Română'},
    {'code': 'ru', 'label': 'Русский'},
    {'code': 'sk', 'label': 'Slovenčina'},
    {'code': 'sl', 'label': 'Slovenščina'},
    {'code': 'es', 'label': 'Español'},
    {'code': 'sw', 'label': 'Kiswahili'},
    {'code': 'sv', 'label': 'Svenska'},
    {'code': 'tl', 'label': 'Tagalog'},
    {'code': 'ta', 'label': 'தமிழ்'},
    {'code': 'te', 'label': 'తెలుగు'},
    {'code': 'th', 'label': 'ไทย'},
    {'code': 'tr', 'label': 'Türkçe'},
    {'code': 'uk', 'label': 'Українська'},
    {'code': 'ur', 'label': 'اردو'},
    {'code': 'vi', 'label': 'Tiếng Việt'},
    {'code': 'cy', 'label': 'Cymraeg'},
  ];

  // Kod -> TranslateLanguage eşleme tablosu
  static final Map<String, TranslateLanguage> _codeMap = {
    'af': TranslateLanguage.afrikaans,
    'sq': TranslateLanguage.albanian,
    'ar': TranslateLanguage.arabic,
    'be': TranslateLanguage.belarusian,
    'bg': TranslateLanguage.bulgarian,
    'bn': TranslateLanguage.bengali,
    'ca': TranslateLanguage.catalan,
    'zh': TranslateLanguage.chinese,
    'hr': TranslateLanguage.croatian,
    'cs': TranslateLanguage.czech,
    'da': TranslateLanguage.danish,
    'nl': TranslateLanguage.dutch,
    'en': TranslateLanguage.english,
    'eo': TranslateLanguage.esperanto,
    'et': TranslateLanguage.estonian,
    'fi': TranslateLanguage.finnish,
    'fr': TranslateLanguage.french,
    'gl': TranslateLanguage.galician,
    'ka': TranslateLanguage.georgian,
    'de': TranslateLanguage.german,
    'el': TranslateLanguage.greek,
    'gu': TranslateLanguage.gujarati,
    'he': TranslateLanguage.hebrew,
    'hi': TranslateLanguage.hindi,
    'hu': TranslateLanguage.hungarian,
    'is': TranslateLanguage.icelandic,
    'id': TranslateLanguage.indonesian,
    'ga': TranslateLanguage.irish,
    'it': TranslateLanguage.italian,
    'ja': TranslateLanguage.japanese,
    'kn': TranslateLanguage.kannada,
    'ko': TranslateLanguage.korean,
    'lv': TranslateLanguage.latvian,
    'lt': TranslateLanguage.lithuanian,
    'mk': TranslateLanguage.macedonian,
    'ms': TranslateLanguage.malay,
    'mt': TranslateLanguage.maltese,
    'no': TranslateLanguage.norwegian,
    'fa': TranslateLanguage.persian,
    'pl': TranslateLanguage.polish,
    'pt': TranslateLanguage.portuguese,
    'ro': TranslateLanguage.romanian,
    'ru': TranslateLanguage.russian,
    'sk': TranslateLanguage.slovak,
    'sl': TranslateLanguage.slovenian,
    'es': TranslateLanguage.spanish,
    'sw': TranslateLanguage.swahili,
    'sv': TranslateLanguage.swedish,
    'tl': TranslateLanguage.tagalog,
    'ta': TranslateLanguage.tamil,
    'te': TranslateLanguage.telugu,
    'th': TranslateLanguage.thai,
    'tr': TranslateLanguage.turkish,
    'uk': TranslateLanguage.ukrainian,
    'ur': TranslateLanguage.urdu,
    'vi': TranslateLanguage.vietnamese,
    'cy': TranslateLanguage.welsh,
  };

  TranslateLanguage _langFromCode(String code) => _codeMap[code] ?? TranslateLanguage.english;

  void _cachePut(String key, String value) {
    // Mevcutsa yerine koy, değilse sona ekle
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    }
    _cache[key] = value;
    if (_cache.length > _cacheLimit) {
      // En eski girdiyi sil
      _cache.remove(_cache.keys.first);
    }
  }

  Future<String> translateFromEnglish(String text, String targetCode) async {
    if (text.trim().isEmpty) return text;
    if (targetCode == 'en') return text; // Aynı dil
    final cacheKey = '$text|$targetCode';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;
    try {
      final key = 'en->$targetCode';
      var translator = _translators[key];
      if (translator == null) {
        translator = OnDeviceTranslator(
          sourceLanguage: _langFromCode('en'),
          targetLanguage: _langFromCode(targetCode),
        );
        _translators[key] = translator;
      }
      final translated = await translator.translateText(text);
      _cachePut(cacheKey, translated);
      return translated;
    } catch (_) {
      return text; // Hata durumunda orijinal metni göster
    }
  }

  Future<String> translateToEnglishAuto(String text) async {
    final source = text.trim();
    if (source.isEmpty) return text;
    final identifier = LanguageIdentifier(confidenceThreshold: 0.5);
    final code = await identifier.identifyLanguage(source);
    await identifier.close();

    if (code == 'en' || code == 'und') return text;

    // Modelleri hazırla (en + tespit edilen kaynak)
    await ensureReady(code);

    final translator = OnDeviceTranslator(
      sourceLanguage: _langFromCode(code),
      targetLanguage: _langFromCode('en'),
    );
    final translated = await translator.translateText(source);
    await translator.close();
    return translated;
  }

  Future<String> translateSmartEnTr(String text) async {
    final source = text.trim();
    if (source.isEmpty) return text;

    final identifier = LanguageIdentifier(confidenceThreshold: 0.5);
    String code = await identifier.identifyLanguage(source);

    if (code == 'und') {
      // Olası dilleri al ve en yüksek güveni seç
      final possibles = await identifier.identifyPossibleLanguages(source);
      if (possibles.isNotEmpty) {
        possibles.sort((a, b) => b.confidence.compareTo(a.confidence));
        code = possibles.first.languageTag;
      }

      // Hâlâ belirsizse basit heuristik: İngilizce ipuçları vs Türkçe ipuçları
      if (code == 'und') {
        final s = source.toLowerCase();
        final englishHints = [' the ', ' and ', ' is ', ' are ', ' you ', 'hello', ' hi ', ' i ', "i'm", "i am", ' my '];
        final turkishHints = [' ve ', ' ile ', ' mi', ' mı', ' mu', ' mü', 'merhaba', 'nasıl', 'teşekkür', 'evet', 'hayır', 'lütfen', 'ben ', ' sen ', ' biz ', ' siz ', ' onlar '];
        // Yaygın Türkçe ek/sonekleri
        final trSuffixes = [
          'yorum', 'yorsun', 'yoruz', 'yorsunuz', 'yorlar',
          'iyorum', 'iyorsun', 'iyoruz', 'iyorsunuz', 'iyorlar',
          'acak', 'ecek', 'mış', 'miş', 'muş', 'müş', 'dır', 'dir', 'dur', 'dür',
          'lar', 'ler', 'dan', 'den', 'ten', 'tan', 'ında', 'inde', 'undan', 'ünden', 'dır', 'dir'
        ];
        final enRegex = RegExp("^[a-zA-Z0-9 ,.!?\-\'\"]+");
        bool enHit = englishHints.any((h) => s.contains(h)) || enRegex.hasMatch(s);
        bool trHit = turkishHints.any((h) => s.contains(h)) || RegExp(r'[çğıöşü]').hasMatch(s) || trSuffixes.any((suf) => s.endsWith(suf));
        if (enHit && !trHit) code = 'en';
        if (trHit && !enHit) code = 'tr';
        // eşitlikte kısa tek kelimelerde: hello/hi -> en, merhaba -> tr
        if (code == 'und') {
          if (s.trim() == 'hello' || s.trim() == 'hi') code = 'en';
          if (s.trim() == 'merhaba') code = 'tr';
          if (code == 'und') code = 'en';
        }
      }
    }

    await identifier.close();

    String targetCode;
    String ensureCode; // en dışındaki modelin kodu
    if (code == 'en') {
      targetCode = 'tr';
      ensureCode = 'tr';
    } else if (code == 'tr') {
      targetCode = 'en';
      ensureCode = 'tr';
    } else {
      targetCode = 'en';
      ensureCode = code;
    }

    // Gerekli modelleri hazırla (en + ensureCode)
    await ensureReady(ensureCode);

    final translator = OnDeviceTranslator(
      sourceLanguage: _langFromCode(code),
      targetLanguage: _langFromCode(targetCode),
    );
    final translated = await translator.translateText(source);
    await translator.close();
    return translated;
  }

  Future<String> translatePair(String text, {required String sourceCode, required String targetCode}) async {
    final source = text.trim();
    if (source.isEmpty) return text;
    if (sourceCode == targetCode) return text;

    // Gerekli modelleri indir: en + diğer dil yeterli; ancak ikisi de en dışındaysa ikisini de garantiye al
    if (sourceCode == 'en' && targetCode != 'en') {
      await ensureReady(targetCode);
    } else if (sourceCode != 'en' && targetCode == 'en') {
      await ensureReady(sourceCode);
    } else {
      await ensureReady(sourceCode);
      await ensureReady(targetCode);
    }

    final translator = OnDeviceTranslator(
      sourceLanguage: _langFromCode(sourceCode),
      targetLanguage: _langFromCode(targetCode),
    );
    final translated = await translator.translateText(source);
    await translator.close();
    return translated;
  }

  final ValueNotifier<TranslationModelDownloadState> downloadState =
      ValueNotifier(TranslationModelDownloadState.initial());
  final OnDeviceTranslatorModelManager _modelManager = OnDeviceTranslatorModelManager();

  Future<bool> isModelReady(String targetCode) async {
    final neededCodes = <String>{'en', targetCode};
    for (final code in neededCodes) {
      final downloaded = await _modelManager.isModelDownloaded(code);
      if (!downloaded) return false;
    }
    return true;
  }

  /// Model mevcut değilse indirir ve hazır olana kadar bekler. Zaman aşımı atar.
  Future<void> ensureReady(String targetCode, {Duration timeout = const Duration(seconds: 20)}) async {
    if (await isModelReady(targetCode)) return;
    await preDownloadModels(targetCode);
    final start = DateTime.now();
    while (true) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (await isModelReady(targetCode)) return;
      if (DateTime.now().difference(start) > timeout) {
        throw Exception('Model indirme zaman aşımı');
      }
    }
  }

  Future<void> preDownloadModels(String targetCode) async {
    // Eğer şu an aynı hedef için indiriliyorsa tekrar başlatma
    final current = downloadState.value;
    if (current.inProgress && current.targetCode == targetCode) return;

    // İndirilecek modeller (en + hedef)
    final neededCodes = <String>{'en', targetCode};

    // Mevcut durumları kontrol et
    int downloaded = 0;
    for (final code in neededCodes) {
      final isDownloaded = await _modelManager.isModelDownloaded(code);
      if (isDownloaded) downloaded++;
    }

    final total = neededCodes.length;
    // Hepsi zaten inmişse durum güncelle ve çık
    if (downloaded == total) {
      downloadState.value = downloadState.value.copyWith(
        inProgress: false,
        downloaded: downloaded,
        total: total,
        completed: true,
        error: null,
        targetCode: targetCode,
      );
      return;
    }

    downloadState.value = TranslationModelDownloadState(
      inProgress: true,
      downloaded: downloaded,
      total: total,
      error: null,
      completed: false,
      targetCode: targetCode,
    );

    try {
      // Sıralı indirme; her bitişte durum güncelle
      for (final code in neededCodes) {
        final already = await _modelManager.isModelDownloaded(code);
        if (!already) {
          await _modelManager.downloadModel(code);
          downloaded++;
          downloadState.value = downloadState.value.copyWith(downloaded: downloaded);
        }
      }

      downloadState.value = downloadState.value.copyWith(
        inProgress: false,
        completed: true,
        error: null,
      );
    } catch (e) {
      downloadState.value = downloadState.value.copyWith(
        inProgress: false,
        error: e.toString(),
        completed: false,
      );
    }
  }

  Future<void> dispose() async {
    for (final t in _translators.values) {
      await t.close();
    }
    _translators.clear();
  }

  /// Metnin dilini tespit eder. Hata veya belirsizlikte 'und' döner.
  Future<String> detectLanguage(String text) async {
    final source = text.trim();
    if (source.isEmpty) return 'und';
    final identifier = LanguageIdentifier(confidenceThreshold: 0.5);
    try {
      final code = await identifier.identifyLanguage(source);
      await identifier.close();
      return code;
    } catch (_) {
      try { await identifier.close(); } catch (_) {}
      return 'und';
    }
  }
}
