// lib/models/message_unit.dart
import 'package:flutter/foundation.dart';
import 'package:vocachat/models/grammar_analysis.dart';
import 'package:vocachat/models/grammar_quiz.dart';

enum MessageSender { user, bot }

class MessageUnit {
  final String id;
  String text;
  final MessageSender sender;
  final DateTime timestamp;
  GrammarAnalysis? grammarAnalysis; // mutable & nullable
  final double vocabularyRichness;
  final Duration? botResponseTime;
  // Yeni: Quiz içeriği (bot tarafından gönderilen çoktan seçmeli soru)
  GrammarQuiz? quiz; // null değilse, text yerine quiz.question gösterilebilir
  int? selectedOptionIndex; // kullanıcı seçimi (0..2)

  MessageUnit({
    required this.text,
    required this.sender,
    this.grammarAnalysis,
    this.vocabularyRichness = 0.5,
    this.botResponseTime,
    this.quiz,
    this.selectedOptionIndex,
    DateTime? timestamp,
  })  : id = UniqueKey().toString(),
        timestamp = timestamp ?? DateTime.now();

  // Hafif serileştirme (yerel depolama için)
  Map<String, dynamic> toPersistedMap() => {
    't': text,
    's': sender == MessageSender.user ? 'u' : 'b',
    'ts': timestamp.toIso8601String(),
    if (botResponseTime != null) 'br': botResponseTime!.inMilliseconds,
    // Quiz ve seçili şık bilgilerini de sakla (geriye uyumlu, yoksa yazma)
    if (quiz != null) 'q': quiz!.toMap(),
    if (selectedOptionIndex != null) 'si': selectedOptionIndex,
  };

  factory MessageUnit.fromPersistedMap(Map<String, dynamic> map) {
    final sRaw = (map['s'] ?? 'u').toString();
    final sender = sRaw == 'b' ? MessageSender.bot : MessageSender.user;
    final tsStr = (map['ts'] ?? DateTime.now().toIso8601String()).toString();
    final DateTime ts = DateTime.tryParse(tsStr) ?? DateTime.now();
    final brMs = map['br'];

    GrammarQuiz? quiz;
    final q = map['q'];
    if (q is Map<String, dynamic>) {
      quiz = GrammarQuiz.fromMap(q);
    } else if (q is Map) {
      quiz = GrammarQuiz.fromMap(q.cast<String, dynamic>());
    }

    int? selIdx;
    final si = map['si'];
    if (si is int) {
      selIdx = si;
    } else if (si is num) {
      selIdx = si.toInt();
    }

    final unit = MessageUnit(
      text: (map['t'] ?? '').toString(),
      sender: sender,
      grammarAnalysis: null,
      vocabularyRichness: 0.5,
      botResponseTime: (brMs is int) ? Duration(milliseconds: brMs) : null,
      timestamp: ts,
      quiz: quiz,
      selectedOptionIndex: selIdx,
    );
    return unit;
  }
}
