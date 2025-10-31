// lib/models/speaking_models.dart
import 'package:flutter/material.dart';

/// Types of speaking exercises
enum SpeakingMode { shadowing, repeat, roleplay, qna }

extension SpeakingModeX on SpeakingMode {
  String get label => switch (this) {
    SpeakingMode.shadowing => 'Shadowing',
    SpeakingMode.repeat => 'Repeat',
    SpeakingMode.roleplay => 'Role-play',
    SpeakingMode.qna => 'Q&A',
  };
  IconData get icon => switch (this) {
    SpeakingMode.shadowing => Icons.graphic_eq_rounded,
    SpeakingMode.repeat => Icons.replay_rounded,
    SpeakingMode.roleplay => Icons.theater_comedy_rounded,
    SpeakingMode.qna => Icons.quiz_rounded,
  };
}

/// Levels for speaking prompts (for UI filtering)
enum SpeakingLevel { beginner, intermediate, advanced }

extension SpeakingLevelX on SpeakingLevel {
  String get label => switch (this) {
        SpeakingLevel.beginner => 'Beginner',
        SpeakingLevel.intermediate => 'Intermediate',
        SpeakingLevel.advanced => 'Advanced',
      };
}

class SpeakingPrompt {
  final String id;
  final String title;
  final SpeakingMode mode;
  final String context; // short scenario / situation
  final List<String> targets; // The sentence(s) we want the user to say
  final List<String> tips; // tips
  final String? partnerLine; // partner's line for roleplay (single line / template)
  final SpeakingLevel level;
  const SpeakingPrompt({
    required this.id,
    required this.title,
    required this.mode,
    required this.context,
    required this.targets,
    this.tips = const [],
    this.partnerLine,
    this.level = SpeakingLevel.beginner,
  });
}

class SpeakingEvaluation {
  final double similarity; // 0-100 average similarity to the target sentence
  final int totalWords;
  final double wordsPerMinute;
  final int fillerCount; // uh / um / like ...
  final List<String> detectedFillers;
  final List<String> suggestions;
  const SpeakingEvaluation({
    required this.similarity,
    required this.totalWords,
    required this.wordsPerMinute,
    required this.fillerCount,
    required this.detectedFillers,
    required this.suggestions,
  });
}