// lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    // Basic defaults
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  Future<void> speak(String text, {String language = 'en-US'}) async {
    if (text.trim().isEmpty) return;
    await _ensureInit();
    try {
      await _tts.setLanguage(language);
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
    await _tts.speak(text);
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

