// lib/services/ai_translation_service.dart
// Sunucu tarafı Gemini proxy (Cloud Function aiTranslate) kullanır.

import 'package:cloud_functions/cloud_functions.dart';

class AiTranslationService {
  AiTranslationService._();
  static final AiTranslationService instance = AiTranslationService._();

  static const String _fallback = '';

  Future<String> translate({required String text, required String targetCode, String? sourceCode}) async {
    final input = text.trim();
    if (input.isEmpty) return '';
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('aiTranslate');
      final res = await callable.call(<String, dynamic>{
        'text': input,
        'targetCode': targetCode,
        if (sourceCode != null) 'sourceCode': sourceCode,
      });
      final data = res.data;
      if (data is Map && data['translation'] is String) {
        return (data['translation'] as String).trim();
      }
      return _fallback;
    } catch (_) {
      return input; // hata halinde orijinali döndür
    }
  }
}
