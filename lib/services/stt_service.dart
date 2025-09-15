// lib/services/stt_service.dart
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool get isAvailable => _available;
  bool get isListening => _speech.isListening;

  Future<bool> init({String localeId = 'en_US'}) async {
    _available = await _speech.initialize();
    return _available;
  }

  Future<bool> start({
    required Function(String) onResult,
    String localeId = 'en_US',
  }) async {
    if (!_available) {
      _available = await _speech.initialize();
      if (!_available) return false;
    }
    final ok = await _speech.listen(
      onResult: (res) {
        final text = res.recognizedWords;
        onResult(text);
      },
      localeId: localeId,
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      ),
    );
    return ok;
  }

  Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancel() async {
    await _speech.cancel();
  }
}
