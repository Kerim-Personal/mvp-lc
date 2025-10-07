// lib/models/grammar_quiz.dart
class GrammarQuiz {
  final String topicPath; // e.g. a1_present_simple
  final String topicTitle;
  final String question; // in target language
  final List<String> options; // length = 3
  final int correctIndex; // 0..2
  final String onCorrectNative; // short summary in native language
  final String onWrongNative; // explanation in native language

  GrammarQuiz({
    required this.topicPath,
    required this.topicTitle,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.onCorrectNative,
    required this.onWrongNative,
  });

  factory GrammarQuiz.fromMap(Map<String, dynamic> map) {
    final opts = (map['options'] as List).map((e) => e.toString()).toList();
    return GrammarQuiz(
      topicPath: (map['topicPath'] ?? '').toString(),
      topicTitle: (map['topicTitle'] ?? '').toString(),
      question: (map['question'] ?? '').toString(),
      options: opts,
      correctIndex: (map['correctIndex'] as num).toInt(),
      onCorrectNative: (map['onCorrectNative'] ?? '').toString(),
      onWrongNative: (map['onWrongNative'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'topicPath': topicPath,
        'topicTitle': topicTitle,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'onCorrectNative': onCorrectNative,
        'onWrongNative': onWrongNative,
      };
}

