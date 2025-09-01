// lib/models/writing_models.dart

enum WritingLevel { beginner, intermediate, advanced }

extension WritingLevelX on WritingLevel {
  String get label => switch (this) {
        WritingLevel.beginner => 'Beginner',
        WritingLevel.intermediate => 'Intermediate',
        WritingLevel.advanced => 'Advanced',
      };
  int get minWords => switch (this) {
        WritingLevel.beginner => 60,
        WritingLevel.intermediate => 120,
        WritingLevel.advanced => 180,
      };
  int get maxWords => switch (this) {
        WritingLevel.beginner => 120,
        WritingLevel.intermediate => 200,
        WritingLevel.advanced => 260,
      };
}

enum WritingType { email, essay, story, summary, opinion }

extension WritingTypeX on WritingType {
  String get label => switch (this) {
        WritingType.email => 'Email',
        WritingType.essay => 'Essay',
        WritingType.story => 'Story',
        WritingType.summary => 'Summary',
        WritingType.opinion => 'Opinion',
      };
  String get icon => switch (this) {
        WritingType.email => '📧',
        WritingType.essay => '📝',
        WritingType.story => '📖',
        WritingType.summary => '🗂️',
        WritingType.opinion => '💭',
      };
}

class WritingPrompt {
  final String id;
  final String title;
  final String category;
  final WritingLevel level;
  final WritingType type;
  final String instructions; // Task directions
  final List<String> focusPoints; // bullet list of what to include
  final List<String> targetVocab; // optional target vocabulary
  final String? sampleOutline; // optional outline
  final String? sampleAnswer; // optional model answer
  final int suggestedMinutes; // estimated time
  const WritingPrompt({
    required this.id,
    required this.title,
    required this.category,
    required this.level,
    required this.type,
    required this.instructions,
    required this.focusPoints,
    this.targetVocab = const [],
    this.sampleOutline,
    this.sampleAnswer,
    this.suggestedMinutes = 15,
  });
}

class WritingEvaluation {
  final int wordCount;
  final double lexicalDiversity; // unique/total
  final double avgSentenceLength; // words per sentence
  final List<String> repeatedWords; // frequent repeats (excluding stopwords)
  final double fleschReadingEase; // approximate (English assumption)
  final double completionScore; // 0-100 ( heuristic )
  final List<String> suggestions;
  const WritingEvaluation({
    required this.wordCount,
    required this.lexicalDiversity,
    required this.avgSentenceLength,
    required this.repeatedWords,
    required this.fleschReadingEase,
    required this.completionScore,
    required this.suggestions,
  });
}

