// lib/utils/text_metrics.dart
class TextMetrics {
  /// 0..1 arasında farklı kelime oranı (type/token ratio)
  static double vocabularyRichness(String input) {
    final words = input
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();
    if (words.isEmpty) return 0.0;
    final unique = words.toSet().length;
    final ratio = unique / words.length;
    return ratio.clamp(0.0, 1.0);
  }
}

