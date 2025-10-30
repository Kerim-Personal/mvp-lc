// lib/models/writing_models.dart

enum WritingLevel { beginner, intermediate, advanced }

extension WritingLevelX on WritingLevel {
  String get label => switch (this) {
        WritingLevel.beginner => 'Başlangıç',
        WritingLevel.intermediate => 'Orta',
        WritingLevel.advanced => 'İleri',
      };
  int get minChars => switch (this) {
        WritingLevel.beginner => 100,
        WritingLevel.intermediate => 200,
        WritingLevel.advanced => 300,
      };
  String get icon => switch (this) {
        WritingLevel.beginner => '🌱',
        WritingLevel.intermediate => '🌿',
        WritingLevel.advanced => '🌳',
      };
}

class WritingTask {
  final String id;
  final String task; // Görev açıklaması
  final WritingLevel level;
  final String emoji;

  const WritingTask({
    required this.id,
    required this.task,
    required this.level,
    required this.emoji,
  });
}

class WritingAnalysis {
  final int overallScore;
  final List<String> strengths;
  final List<String> improvements;
  final List<GrammarIssue> grammarIssues;
  final String vocabularyFeedback;
  final String structureFeedback;
  final String taskCompletion;
  final String nextSteps;

  const WritingAnalysis({
    required this.overallScore,
    required this.strengths,
    required this.improvements,
    required this.grammarIssues,
    required this.vocabularyFeedback,
    required this.structureFeedback,
    required this.taskCompletion,
    required this.nextSteps,
  });

  factory WritingAnalysis.fromJson(Map<String, dynamic> json) {
    final strengths = (json['strengths'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final improvements = (json['improvements'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

    final giListDynamic = json['grammarIssues'] as List?;
    final giList = giListDynamic == null
        ? const <GrammarIssue>[]
        : giListDynamic
            .where((e) => e is Map)
            .map((e) => GrammarIssue.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

    return WritingAnalysis(
      overallScore: (json['overallScore'] as num?)?.toInt() ?? 0,
      strengths: strengths,
      improvements: improvements,
      grammarIssues: giList,
      vocabularyFeedback: json['vocabularyFeedback']?.toString() ?? '',
      structureFeedback: json['structureFeedback']?.toString() ?? '',
      taskCompletion: json['taskCompletion']?.toString() ?? '',
      nextSteps: json['nextSteps']?.toString() ?? '',
    );
  }
}

class GrammarIssue {
  final String text;
  final String correction;
  final String explanation;

  const GrammarIssue({
    required this.text,
    required this.correction,
    required this.explanation,
  });

  factory GrammarIssue.fromJson(Map<String, dynamic> json) {
    return GrammarIssue(
      text: json['text']?.toString() ?? '',
      correction: json['correction']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
    );
  }
}
