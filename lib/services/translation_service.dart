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
    {'code': 'ht', 'label': 'Haitian'}, // on-device destek yok
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
    {'code': 'mr', 'label': 'Marathi'}, // yeniden eklendi (on-device destek yok)
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

  // On-device çeviri modeli olmayan eklenen diller
  static const Set<String> unsupportedModelLangs = {'ht','mr'};

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
    if (unsupportedModelLangs.contains(targetCode)) return text; // destek yok -> orijinal
    final cacheKey = '$text|$targetCode';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;
    try {
      // Tırnak içindeki ifadeleri koru
      final protectedPhrases = <String>[];
      final protectedMarkers = <String>[];
      String textToTranslate = text;

      // Çift tırnak içindeki ifadeleri bul ve benzersiz marker ile değiştir
      textToTranslate = textToTranslate.replaceAllMapped(
        RegExp(r'"([^"]+)"'),
        (match) {
          final marker = 'XYZQUOTE${protectedPhrases.length}XYZ';
          protectedPhrases.add(match.group(0)!);
          protectedMarkers.add(marker);
          return marker;
        },
      );

      // Tek tırnak içindeki ifadeleri bul - ama kesme işaretlerini (It's, don't) hariç tut
      // Sadece izole tek tırnakları yakala: boşluk 'kelime' boşluk veya başlangıç/bitiş
      textToTranslate = textToTranslate.replaceAllMapped(
        RegExp(r"(?<=\s|^)'([^']+)'(?=\s|$|[.,!?;:])"),
        (match) {
          final marker = 'XYZQUOTE${protectedPhrases.length}XYZ';
          protectedPhrases.add(match.group(0)!);
          protectedMarkers.add(marker);
          return marker;
        },
      );

      final key = 'en->$targetCode';
      var translator = _translators[key];
      if (translator == null) {
        translator = OnDeviceTranslator(
          sourceLanguage: _langFromCode('en'),
          targetLanguage: _langFromCode(targetCode),
        );
        _translators[key] = translator;
      }
      String translated = await translator.translateText(textToTranslate);

      // Marker'ları orijinal tırnaklı ifadelerle değiştir
      for (int i = 0; i < protectedPhrases.length; i++) {
        final marker = protectedMarkers[i];
        final phrase = protectedPhrases[i];

        translated = translated.replaceAll(marker, phrase);
        translated = translated.replaceAll(marker.toLowerCase(), phrase);
        translated = translated.replaceAll(RegExp(marker, caseSensitive: false), phrase);
        translated = translated.replaceAll(RegExp(r'xyzquote\s*' + i.toString() + r'\s*xyz', caseSensitive: false), phrase);
      }

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

    // Tırnak içindeki ifadeleri koru
    final protectedPhrases = <String>[];
    final protectedMarkers = <String>[];
    String textToTranslate = source;

    textToTranslate = textToTranslate.replaceAllMapped(
      RegExp(r'"([^"]+)"'),
      (match) {
        final marker = 'XYZQUOTE${protectedPhrases.length}XYZ';
        protectedPhrases.add(match.group(0)!);
        protectedMarkers.add(marker);
        return marker;
      },
    );

    textToTranslate = textToTranslate.replaceAllMapped(
      RegExp(r"(?<=\s|^)'([^']+)'(?=\s|$|[.,!?;:])"),
      (match) {
        final marker = 'XYZQUOTE${protectedPhrases.length}XYZ';
        protectedPhrases.add(match.group(0)!);
        protectedMarkers.add(marker);
        return marker;
      },
    );

    final translator = OnDeviceTranslator(
      sourceLanguage: _langFromCode(code),
      targetLanguage: _langFromCode('en'),
    );
    String translated = await translator.translateText(textToTranslate);
    await translator.close();

    // Marker'ları orijinal tırnaklı ifadelerle değiştir
    for (int i = 0; i < protectedPhrases.length; i++) {
      final marker = protectedMarkers[i];
      final phrase = protectedPhrases[i];

      translated = translated.replaceAll(marker, phrase);
      translated = translated.replaceAll(marker.toLowerCase(), phrase);
      translated = translated.replaceAll(marker.replaceAll('XYZ', ' XYZ '), phrase);
      translated = translated.replaceAll(marker.toLowerCase().replaceAll('xyz', ' xyz '), phrase);
      translated = translated.replaceAll(RegExp(marker, caseSensitive: false), phrase);
      translated = translated.replaceAll(RegExp(r'xyzquote\s*' + i.toString() + r'\s*xyz', caseSensitive: false), phrase);
    }

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
          'ıyorum', 'iyorsun', 'iyoruz', 'iyorsunuz', 'iyorlar',
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

    // Tırnak içindeki ifadeleri koru
    final protectedPhrases = <String>[];
    final protectedMarkers = <String>[];
    String textToTranslate = source;

    textToTranslate = textToTranslate.replaceAllMapped(
      RegExp(r'"([^"]+)"'),
      (match) {
        final marker = 'XYZQUOTE${protectedPhrases.length}XYZ';
        protectedPhrases.add(match.group(0)!);
        protectedMarkers.add(marker);
        return marker;
      },
    );

    textToTranslate = textToTranslate.replaceAllMapped(
      RegExp(r"(?<=\s|^)'([^']+)'(?=\s|$|[.,!?;:])"),
      (match) {
        final marker = 'XYZQUOTE${protectedPhrases.length}XYZ';
        protectedPhrases.add(match.group(0)!);
        protectedMarkers.add(marker);
        return marker;
      },
    );

    final translator = OnDeviceTranslator(
      sourceLanguage: _langFromCode(code),
      targetLanguage: _langFromCode(targetCode),
    );
    String translated = await translator.translateText(textToTranslate);
    await translator.close();

    // Marker'ları orijinal tırnaklı ifadelerle değiştir
    for (int i = 0; i < protectedPhrases.length; i++) {
      final marker = protectedMarkers[i];
      final phrase = protectedPhrases[i];

      translated = translated.replaceAll(marker, phrase);
      translated = translated.replaceAll(marker.toLowerCase(), phrase);
      translated = translated.replaceAll(marker.replaceAll('XYZ', ' XYZ '), phrase);
      translated = translated.replaceAll(marker.toLowerCase().replaceAll('xyz', ' xyz '), phrase);
      translated = translated.replaceAll(RegExp(marker, caseSensitive: false), phrase);
      translated = translated.replaceAll(RegExp(r'xyzquote\s*' + i.toString() + r'\s*xyz', caseSensitive: false), phrase);
    }

    return translated;
  }

  Future<String> translatePair(String text, {required String sourceCode, required String targetCode}) async {
    final source = text.trim();
    if (source.isEmpty) return text;
    if (sourceCode == targetCode) return text;
    if (unsupportedModelLangs.contains(sourceCode) || unsupportedModelLangs.contains(targetCode)) {
      return text; // on-device destek yok
    }

    // Gerekli modelleri indir: en + diğer dil yeterli; ancak ikisi de en dışındaysa ikisini de garantiye al
    if (sourceCode == 'en' && targetCode != 'en') {
      await ensureReady(targetCode);
    } else if (sourceCode != 'en' && targetCode == 'en') {
      await ensureReady(sourceCode);
    } else {
      await ensureReady(sourceCode);
      await ensureReady(targetCode);
    }

    // Tırnak içindeki ifadeleri koru
    final protectedPhrases = <String>[];
    final protectedMarkers = <String>[];
    String textToTranslate = source;

    textToTranslate = textToTranslate.replaceAllMapped(
      RegExp(r'"([^"]+)"'),
      (match) {
        final marker = 'XYZQUOTE${protectedPhrases.length}XYZ';
        protectedPhrases.add(match.group(0)!);
        protectedMarkers.add(marker);
        return marker;
      },
    );

    textToTranslate = textToTranslate.replaceAllMapped(
      RegExp(r"(?<=\s|^)'([^']+)'(?=\s|$|[.,!?;:])"),
      (match) {
        final marker = 'XYZQUOTE${protectedPhrases.length}XYZ';
        protectedPhrases.add(match.group(0)!);
        protectedMarkers.add(marker);
        return marker;
      },
    );

    final translator = OnDeviceTranslator(
      sourceLanguage: _langFromCode(sourceCode),
      targetLanguage: _langFromCode(targetCode),
    );
    String translated = await translator.translateText(textToTranslate);
    await translator.close();

    // Marker'ları orijinal tırnaklı ifadelerle değiştir
    for (int i = 0; i < protectedPhrases.length; i++) {
      final marker = protectedMarkers[i];
      final phrase = protectedPhrases[i];

      translated = translated.replaceAll(marker, phrase);
      translated = translated.replaceAll(marker.toLowerCase(), phrase);
      translated = translated.replaceAll(marker.replaceAll('XYZ', ' XYZ '), phrase);
      translated = translated.replaceAll(marker.toLowerCase().replaceAll('xyz', ' xyz '), phrase);
      translated = translated.replaceAll(RegExp(marker, caseSensitive: false), phrase);
      translated = translated.replaceAll(RegExp(r'xyzquote\s*' + i.toString() + r'\s*xyz', caseSensitive: false), phrase);
    }

    return translated;
  }

  final ValueNotifier<TranslationModelDownloadState> downloadState =
      ValueNotifier(TranslationModelDownloadState.initial());
  final OnDeviceTranslatorModelManager _modelManager = OnDeviceTranslatorModelManager();

  Future<bool> isModelReady(String targetCode) async {
    if (unsupportedModelLangs.contains(targetCode)) return true; // model gerekmiyor
    final neededCodes = <String>{'en', targetCode};
    for (final code in neededCodes) {
      final lang = _langFromCode(code);
      final downloaded = await _modelManager.isModelDownloaded(lang.bcpCode);
      if (!downloaded) return false;
    }
    return true;
  }

  /// Model mevcut değilse indirir ve hazır olana kadar bekler. Zaman aşımı atar.
  Future<void> ensureReady(String targetCode, {Duration timeout = const Duration(seconds: 20)}) async {
    if (unsupportedModelLangs.contains(targetCode)) return; // indirilmeyecek
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
    if (unsupportedModelLangs.contains(targetCode)) {
      // Model yok, direkt completed state gönder (indirilmeyecek)
      downloadState.value = downloadState.value.copyWith(
        inProgress: false,
        downloaded: 0,
        total: 0,
        completed: true,
        targetCode: targetCode,
        error: null,
      );
      return;
    }

    // Eğer şu an aynı hedef için indiriliyorsa tekrar başlatma
    final current = downloadState.value;
    if (current.inProgress && current.targetCode == targetCode) return;

    // İndirilecek modeller (en + hedef)
    final neededCodes = <String>{'en', targetCode};

    // Önce hızlı kontrol - tüm modeller hazır mı?
    bool allReady = true;
    for (final code in neededCodes) {
      final lang = _langFromCode(code);
      if (!await _modelManager.isModelDownloaded(lang.bcpCode)) {
        allReady = false;
        break;
      }
    }

    if (allReady) {
      // Tüm modeller zaten hazır
      downloadState.value = TranslationModelDownloadState(
        inProgress: false,
        downloaded: neededCodes.length,
        total: neededCodes.length,
        completed: true,
        error: null,
        targetCode: targetCode,
      );
      return;
    }

    // İndirme başlat - başlangıç durumu
    downloadState.value = TranslationModelDownloadState(
      inProgress: true,
      downloaded: 0,
      total: neededCodes.length,
      error: null,
      completed: false,
      targetCode: targetCode,
    );

    try {
      int downloaded = 0;
      // Sıralı indirme; her bitişte durum güncelle
      for (final code in neededCodes) {
        final lang = _langFromCode(code);
        final already = await _modelManager.isModelDownloaded(lang.bcpCode);
        if (already) {
          downloaded++;
          downloadState.value = downloadState.value.copyWith(downloaded: downloaded);
        } else {
          // Gerçekten indir - TranslateLanguage kullan
          await _modelManager.downloadModel(
            lang.bcpCode,
            isWifiRequired: false,
          );
          downloaded++;
          downloadState.value = downloadState.value.copyWith(downloaded: downloaded);
        }
      }

      // Tamamlandı
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
