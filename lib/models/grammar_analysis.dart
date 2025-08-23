// lib/models/grammar_analysis.dart
// Premium kullanıcı mesajları için gramer analizi model ve enum tanımları.

enum Formality { informal, neutral, formal }

class GrammarError {
  final String type; // ör: verb tense, article, preposition
  final String original;
  final String correction;
  final String severity; // low|medium|high
  final String explanation;

  const GrammarError({
    required this.type,
    required this.original,
    required this.correction,
    required this.severity,
    required this.explanation,
  });

  factory GrammarError.fromMap(Map<String, dynamic> map) => GrammarError(
    type: (map['type'] ?? '').toString(),
    original: (map['original'] ?? '').toString(),
    correction: (map['correction'] ?? '').toString(),
    severity: (map['severity'] ?? '').toString(),
    explanation: (map['explanation'] ?? '').toString(),
  );

  Map<String, dynamic> toMap() => {
    'type': type,
    'original': original,
    'correction': correction,
    'severity': severity,
    'explanation': explanation,
  };
}

class GrammarAnalysis {
  final String tense;
  final int nounCount;
  final int verbCount;
  final int adjectiveCount;
  final double sentiment; // -1.0 .. 1.0
  final double complexity; // 0.0 .. 1.0 (yaklaşık zorluk / yapısal karmaşıklık)
  final Formality formality;
  final Map<String, String> corrections; // hatalı -> doğru
  final double grammarScore; // 0..1 genel doğruluk
  final String cefr; // A1..C2 tahmini
  final List<String> suggestions; // geliştirme önerileri
  final List<GrammarError> errors; // ayrıntılı hatalar

  const GrammarAnalysis({
    this.tense = "Present Simple",
    this.nounCount = 0,
    this.verbCount = 0,
    this.adjectiveCount = 0,
    this.sentiment = 0.0,
    this.complexity = 0.0,
    this.formality = Formality.neutral,
    this.corrections = const {},
    this.grammarScore = 0.0,
    this.cefr = 'A1',
    this.suggestions = const [],
    this.errors = const [],
  });

  factory GrammarAnalysis.fromMap(Map<String, dynamic> map) {
    Formality formality = Formality.neutral;
    final f = (map['formality'] ?? '').toString().toLowerCase();
    if (f.contains('inform')) formality = Formality.informal;
    else if (f.contains('formal')) formality = Formality.formal;

    Map<String, String> corr = {};
    if (map['corrections'] is Map) {
      (map['corrections'] as Map).forEach((k, v) {
        if (k is String && v is String) corr[k] = v;
      });
    } else if (map['corrections'] is List) {
      // Eğer liste formatında (ör: [{"wrong":"goed","correct":"went"}]) geldiyse dönüştür.
      for (final item in (map['corrections'] as List)) {
        if (item is Map && item['wrong'] is String && item['correct'] is String) {
          corr[item['wrong'] as String] = item['correct'] as String;
        }
      }
    }

    int safeInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : 0);
    double safeDouble(dynamic v) => v is double ? v : (v is num ? v.toDouble() : 0.0);

    List<GrammarError> errs = [];
    if (map['errors'] is List) {
      for (final e in (map['errors'] as List)) {
        if (e is Map) errs.add(GrammarError.fromMap(e.cast<String, dynamic>()));
      }
    }
    List<String> sugg = [];
    if (map['suggestions'] is List) {
      sugg = (map['suggestions'] as List).whereType<String>().toList();
    }

    return GrammarAnalysis(
      tense: (map['tense'] ?? '').toString().isEmpty ? 'Unknown' : map['tense'].toString(),
      nounCount: safeInt(map['nounCount']),
      verbCount: safeInt(map['verbCount']),
      adjectiveCount: safeInt(map['adjectiveCount']),
      sentiment: (safeDouble(map['sentiment'])).clamp(-1.0, 1.0),
      complexity: (safeDouble(map['complexity'])).clamp(0.0, 1.0),
      formality: formality,
      corrections: corr,
      grammarScore: (safeDouble(map['grammarScore'])).clamp(0.0, 1.0),
      cefr: (map['cefr'] ?? 'A1').toString(),
      suggestions: sugg,
      errors: errs,
    );
  }

  Map<String, dynamic> toMap() => {
    'tense': tense,
    'nounCount': nounCount,
    'verbCount': verbCount,
    'adjectiveCount': adjectiveCount,
    'sentiment': sentiment,
    'complexity': complexity,
    'formality': formality.name,
    'corrections': corrections,
    'grammarScore': grammarScore,
    'cefr': cefr,
    'suggestions': suggestions,
    'errors': errors.map((e) => e.toMap()).toList(),
  };
}
