// lib/services/translation_service.dart
// Premium kullanıcılar için İngilizceden kullanıcının anadil koduna çeviri sağlar.

import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:flutter/foundation.dart';

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
  final Map<String, String> _cache = {}; // key: text|target

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
      _cache[cacheKey] = translated;
      return translated;
    } catch (_) {
      return text; // Hata durumunda orijinal metni göster
    }
  }

  final ValueNotifier<TranslationModelDownloadState> downloadState =
      ValueNotifier(TranslationModelDownloadState.initial());
  final OnDeviceTranslatorModelManager _modelManager = OnDeviceTranslatorModelManager();

  Future<bool> isModelReady(String targetCode) async {
    final neededCodes = <String>{'en', targetCode};
    for (final c in neededCodes) {
      final downloaded = await _modelManager.isModelDownloaded(c);
      if (!downloaded) return false;
    }
    return true;
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
      // Manager String (dil kodu) bekliyor
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
}
