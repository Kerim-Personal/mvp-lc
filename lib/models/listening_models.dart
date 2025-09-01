// lib/models/listening_models.dart

/// Zorluk seviyeleri
enum ListeningLevel { beginner, intermediate, advanced }

extension ListeningLevelX on ListeningLevel {
  String get label => switch (this) {
        ListeningLevel.beginner => 'Beginner',
        ListeningLevel.intermediate => 'Intermediate',
        ListeningLevel.advanced => 'Advanced',
      };
}

/// Soru tipi
enum ListeningQuestionType { multipleChoice, gapFill, dictation }

class ListeningQuestionOption {
  final String id;
  final String text;
  const ListeningQuestionOption({required this.id, required this.text});
}

class ListeningQuestion {
  final String id;
  final ListeningQuestionType type;
  final String prompt; // Soru veya boşluk talimatı
  final List<ListeningQuestionOption> options; // multipleChoice için
  final String? correctOptionId; // multipleChoice için
  final String? answer; // gapFill & dictation
  final int startMs; // sorunun kapsadığı başlangıç
  final int endMs; // sorunun kapsadığı bitiş
  const ListeningQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    this.options = const [],
    this.correctOptionId,
    this.answer,
    required this.startMs,
    required this.endMs,
  });
}

/// Transcript kelime zamanlaması (isteğe bağlı ince highlight)
class WordTiming {
  final String word;
  final int startMs;
  final int endMs;
  const WordTiming({required this.word, required this.startMs, required this.endMs});
}

class ListeningExercise {
  final String id;
  final String title;
  final String category;
  final ListeningLevel level;
  final String audioUrl; // asset: veya https://
  final int durationMs;
  final String transcript;
  final List<WordTiming> timings;
  final List<ListeningQuestion> questions;
  final String? description;
  final String accent; // örn: US, UK, AU
  final List<String> skills; // örn: ['gist','detail','vocab']

  const ListeningExercise({
    required this.id,
    required this.title,
    required this.category,
    required this.level,
    required this.audioUrl,
    required this.durationMs,
    required this.transcript,
    required this.timings,
    required this.questions,
    this.description,
    this.accent = 'General',
    this.skills = const [],
  });
}
