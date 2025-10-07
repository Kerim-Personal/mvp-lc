// lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  static const Map<String, String> _localeMap = {
    'en': 'en-US',
    'tr': 'tr-TR',
    'es': 'es-ES',
    'de': 'de-DE',
    'fr': 'fr-FR',
    'it': 'it-IT',
    'pt': 'pt-PT',
  };

  Future<void> _ensureInit() async {
    if (_initialized) return;
    // Basic defaults
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  String _stripEmojis(String input) {
    final buffer = StringBuffer();
    for (final cp in input.runes) {
      if (_isEmoji(cp) || _isModifier(cp)) continue;
      buffer.writeCharCode(cp);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _isModifier(int cp) =>
      cp == 0xFE0F || (cp >= 0x1F3FB && cp <= 0x1F3FF); // variation selector & skin tones

  bool _isEmoji(int cp) {
    return (
      (cp >= 0x1F300 && cp <= 0x1F5FF) || // symbols & pictographs
      (cp >= 0x1F600 && cp <= 0x1F64F) || // emoticons
      (cp >= 0x1F680 && cp <= 0x1F6FF) || // transport & map
      (cp >= 0x1F700 && cp <= 0x1F77F) ||
      (cp >= 0x1F780 && cp <= 0x1F7FF) ||
      (cp >= 0x1F800 && cp <= 0x1F8FF) ||
      (cp >= 0x1F900 && cp <= 0x1F9FF) ||
      (cp >= 0x1FA70 && cp <= 0x1FAFF) ||
      (cp >= 0x2600 && cp <= 0x26FF) ||   // misc symbols
      (cp >= 0x2700 && cp <= 0x27BF) ||   // dingbats
      (cp >= 0x1F1E6 && cp <= 0x1F1FF)    // flags
    );
  }

  Future<void> speakSmart(String text, {String? hintLanguageCode}) async {
    final cleaned = _stripEmojis(text);
    if (cleaned.isEmpty) return;
    await _ensureInit();
    final locale = _localeMap[hintLanguageCode ?? ''] ?? 'en-US';
    try { await _tts.setLanguage(locale); } catch (_) {}
    try { await _tts.stop(); } catch (_) {}
    await _tts.speak(cleaned);
  }

  Future<void> speak(String text, {String language = 'en-US'}) async {
    final cleaned = _stripEmojis(text);
    if (cleaned.trim().isEmpty) return;
    await _ensureInit();
    try { await _tts.setLanguage(language); } catch (_) {}
    try { await _tts.stop(); } catch (_) {}
    await _tts.speak(cleaned);
  }

  Future<void> stop() async {
    try { await _tts.stop(); } catch (_) {}
  }
}
