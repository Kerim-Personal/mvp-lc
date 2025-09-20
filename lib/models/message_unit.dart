// lib/models/message_unit.dart
import 'package:flutter/foundation.dart';
import 'package:vocachat/models/grammar_analysis.dart';

enum MessageSender { user, bot }

class MessageUnit {
  final String id;
  String text;
  final MessageSender sender;
  final DateTime timestamp;
  GrammarAnalysis? grammarAnalysis; // mutable & nullable
  final double vocabularyRichness;
  final Duration? botResponseTime;

  MessageUnit({
    required this.text,
    required this.sender,
    this.grammarAnalysis,
    this.vocabularyRichness = 0.5,
    this.botResponseTime,
  })  : id = UniqueKey().toString(),
        timestamp = DateTime.now();
}

