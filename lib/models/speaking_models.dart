// lib/models/speaking_models.dart
import 'package:flutter/material.dart';

/// Konuşma alıştırması türleri
enum SpeakingMode { shadowing, repeat, roleplay, qna }

extension SpeakingModeX on SpeakingMode {
  String get label => switch (this) {
        SpeakingMode.shadowing => 'Shadowing',
        SpeakingMode.repeat => 'Tekrar',
        SpeakingMode.roleplay => 'Rol Oyunu',
        SpeakingMode.qna => 'Soru-Cevap',
      };
  IconData get icon => switch (this) {
        SpeakingMode.shadowing => Icons.graphic_eq_rounded,
        SpeakingMode.repeat => Icons.replay_rounded,
        SpeakingMode.roleplay => Icons.theater_comedy_rounded,
        SpeakingMode.qna => Icons.quiz_rounded,
      };
}

class SpeakingPrompt {
  final String id;
  final String title;
  final SpeakingMode mode;
  final String context; // kısa senaryo / durum
  final List<String> targets; // Kullanıcının söylemesini istediğimiz cümle(ler)
  final List<String> tips; // ipuçları
  final String? partnerLine; // roleplay için karşı taraf repliği (tek satır / şablon)
  const SpeakingPrompt({
    required this.id,
    required this.title,
    required this.mode,
    required this.context,
    required this.targets,
    this.tips = const [],
    this.partnerLine,
  });
}

class SpeakingEvaluation {
  final double similarity; // 0-100 hedef cümleye benzerlik ortalaması
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

