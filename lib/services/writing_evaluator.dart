// lib/services/writing_evaluator.dart
import 'dart:math';
import 'package:vocachat/models/writing_models.dart';

class WritingEvaluator {
  WritingEvaluator._();
  static final WritingEvaluator instance = WritingEvaluator._();

  static final _sentenceRegex = RegExp(r'[^.!?]+[.!?]');
  static final _wordRegex = RegExp(r"[A-Za-z']+");
  static const _stopwords = <String>{
    'the','a','an','and','or','but','to','of','in','on','for','with','at','by','is','are','was','were','be','it','this','that','as','from','so','if','then','than','too','very','can','could','would','should','will','about'
  };

  WritingEvaluation evaluate(String text, WritingPrompt prompt) {
    final clean = text.trim();
    if (clean.isEmpty) {
      return const WritingEvaluation(
        wordCount: 0,
        lexicalDiversity: 0,
        avgSentenceLength: 0,
        repeatedWords: [],
        fleschReadingEase: 0,
        completionScore: 0,
        suggestions: ['Metin boş. Lütfen yazmaya başla.'],
      );
    }
    final words = _wordRegex.allMatches(clean).map((m)=>m.group(0)!.toLowerCase()).toList();
    final wordCount = words.length;

    // Sentences
    final sentences = _sentenceRegex.allMatches(clean).map((m)=>m.group(0)!.trim()).where((s)=>s.isNotEmpty).toList();
    final sentenceCount = sentences.isEmpty ? 1 : sentences.length;
    final avgSentenceLength = wordCount / sentenceCount;

    // Lexical diversity
    final uniqueWords = words.where((w)=>!_stopwords.contains(w)).toSet();
    final double lexicalDiversity = wordCount == 0 ? 0.0 : uniqueWords.length / wordCount;

    // Repeated words (simple frequency)
    final freq = <String,int>{};
    for (final w in words) {
      if (_stopwords.contains(w)) continue;
      freq[w] = (freq[w] ?? 0) + 1;
    }
    final repeated = freq.entries.where((e)=>e.value >= 3).map((e)=>e.key).take(10).toList();

    // Approx syllable count (very rough): count vowels groups
    int syllables = 0;
    final vowelGroup = RegExp(r'[aeiouy]+', caseSensitive: false);
    for (final w in words) {
      final groups = vowelGroup.allMatches(w).length;
      syllables += max(1, groups);
    }
    final flesch = _fleschReadingEase(wordCount, sentenceCount, syllables);

    final suggestions = <String>[];
    // Word range check
    if (wordCount < prompt.level.minWords) {
      suggestions.add('Kelime sayısı düşük: en az ${prompt.level.minWords} kelime hedefle.');
    } else if (wordCount > prompt.level.maxWords) {
      suggestions.add('Kelime sayısı yüksek: ${prompt.level.maxWords} sınırını aşma.');
    }
    if (avgSentenceLength > 28) {
      suggestions.add('Cümleler çok uzun; bazılarını bölmeyi düşün.');
    } else if (avgSentenceLength < 8 && wordCount > 40) {
      suggestions.add('Cümleler çok kısa; bazılarını birleştirerek akıcılığı artır.');
    }
    if (lexicalDiversity < 0.35 && wordCount > 80) {
      suggestions.add('Daha çeşitli kelimeler kullan (eş anlamlılar ekle).');
    }
    if (repeated.isNotEmpty) {
      suggestions.add('Bazı kelimeler sık tekrar ediyor: ${repeated.take(5).join(', ')}');
    }
    if (flesch < 50) {
      suggestions.add('Okunabilirlik düşmüş; daha kısa cümleler ve daha basit kelimeler kullan.');
    }
    // Focus point coverage (rudimentary string contains check)
    int focusHit = 0;
    final lower = clean.toLowerCase();
    for (final f in prompt.focusPoints) {
      final key = f.split(' ').first.toLowerCase();
      if (lower.contains(key)) focusHit++;
    }
    if (focusHit < (prompt.focusPoints.length / 2).ceil()) {
      suggestions.add('Talimat maddelerinin bazıları eksik görünüyor; listeni yeniden gözden geçir.');
    }

    // Completion score heuristic 0-100
    double completion = 0;
    final lengthScore =  (wordCount / prompt.level.minWords).clamp(0, 1) * 30;
    final focusScore = (focusHit / prompt.focusPoints.length).clamp(0, 1) * 30;
    final diversityScore = (lexicalDiversity.clamp(0, 0.6) / 0.6) * 20;
    final structureScore = avgSentenceLength > 5 ? 10 : 5;
    final readabilityScore = flesch >= 50 ? 10 : flesch >= 30 ? 6 : 2;
    completion = lengthScore + focusScore + diversityScore + structureScore + readabilityScore;

    return WritingEvaluation(
      wordCount: wordCount,
      lexicalDiversity: lexicalDiversity,
      avgSentenceLength: avgSentenceLength,
      repeatedWords: repeated,
      fleschReadingEase: flesch,
      completionScore: completion.clamp(0, 100),
      suggestions: suggestions.isEmpty ? ['Harika! Temel kriterler iyi görünüyor.'] : suggestions,
    );
  }

  double _fleschReadingEase(int words, int sentences, int syllables) {
    if (words == 0 || sentences == 0) return 0;
    // Classic formula adapted
    final wps = words / sentences;
    final spw = syllables / words;
    final score = 206.835 - (1.015 * wps) - (84.6 * spw);
    return score.clamp(0, 100);
  }
}
