// test/models/message_unit_persist_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocachat/models/grammar_quiz.dart';
import 'package:vocachat/models/message_unit.dart';

void main() {
  test('MessageUnit with quiz persists and restores correctly', () {
    final quiz = GrammarQuiz(
      topicPath: 'a1_present_simple',
      topicTitle: 'Present Simple',
      question: 'Choose the correct form',
      options: const ['goes', 'go', 'going'],
      correctIndex: 0,
      onCorrectNative: 'Doğru!',
      onWrongNative: 'Yanlış açıklaması',
    );

    final unit = MessageUnit(
      text: quiz.question,
      sender: MessageSender.bot,
      quiz: quiz,
      selectedOptionIndex: 2,
    );

    final map = unit.toPersistedMap();
    // Simüle: JSON'a yaz/oku
    final decoded = jsonDecode(jsonEncode(map)) as Map<String, dynamic>;
    final restored = MessageUnit.fromPersistedMap(decoded);

    expect(restored.sender, MessageSender.bot);
    expect(restored.text, quiz.question);
    expect(restored.quiz, isNotNull);
    expect(restored.quiz!.question, quiz.question);
    expect(restored.quiz!.options, quiz.options);
    expect(restored.quiz!.correctIndex, quiz.correctIndex);
    expect(restored.selectedOptionIndex, 2);
  });
}

