// lib/widgets/linguabot/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:lingua_chat/models/grammar_analysis.dart';
import 'package:lingua_chat/models/message_unit.dart';
import 'package:lingua_chat/widgets/linguabot/message_insight_dialog.dart';

class MessageBubble extends StatelessWidget {
  final MessageUnit message;
  final Function(String) onCorrect;
  const MessageBubble({super.key, required this.message, required this.onCorrect});

  TextSpan _buildAnalyzedSpan(String text, GrammarAnalysis ga) {
    final List<InlineSpan> spans = [];
    final regex = RegExp(r'(\s+)');
    int last = 0;
    final matches = regex.allMatches(text);
    final List<String> tokens = [];
    for (final m in matches) {
      if (m.start > last) tokens.add(text.substring(last, m.start));
      tokens.add(text.substring(m.start, m.end)); // whitespace token
      last = m.end;
    }
    if (last < text.length) tokens.add(text.substring(last));

    final corrections = ga.corrections.map((k,v)=> MapEntry(k.toLowerCase().trim(), v));
    final errorTokens = ga.errors.map((e)=> e.original.toLowerCase().trim()).toSet();

    for (final token in tokens) {
      if (token.trim().isEmpty) { // whitespace
        spans.add(TextSpan(text: token));
        continue;
      }
      final cleaned = token.toLowerCase().replaceAll(RegExp(r'^[^A-Za-z]+|[^A-Za-z]+$'), '');
      if (cleaned.isNotEmpty && corrections.containsKey(cleaned)) {
        spans.add(const TextSpan(text: '', style: TextStyle()));
        spans.add(TextSpan(text: token, style: const TextStyle(decoration: TextDecoration.underline, decorationColor: Colors.redAccent, color: Colors.redAccent)));
      } else if (cleaned.isNotEmpty && errorTokens.contains(cleaned)) {
        spans.add(TextSpan(text: token, style: const TextStyle(color: Colors.orangeAccent, decoration: TextDecoration.underline)));
      } else {
        spans.add(TextSpan(text: token, style: const TextStyle(color: Colors.white)));
      }
    }
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    bool isUser = message.sender == MessageSender.user;
    final ga = message.grammarAnalysis;
    Widget textWidget;
    if (isUser && ga != null) {
      textWidget = RichText(text: _buildAnalyzedSpan(message.text, ga));
    } else {
      textWidget = const SizedBox.shrink();
      textWidget = Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5));
    }
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          showDialog(
            context: context,
            barrierColor: Colors.black.withAlpha(128),
            builder: (_) => MessageInsightDialog(
              message: message,
              onCorrect: onCorrect,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isUser ? Colors.tealAccent.withAlpha(128) : Colors.purpleAccent.withAlpha(128)),
            gradient: LinearGradient(
              colors: isUser
                  ? [Colors.teal.withAlpha(51), Colors.cyan.withAlpha(26)]
                  : [Colors.purple.withAlpha(51), Colors.deepPurple.withAlpha(26)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              textWidget,
              if (isUser && ga != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.cyanAccent.withAlpha((255*0.4).round())),
                        ),
                        child: Text('Score ${(ga.grammarScore*100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withAlpha((255*0.4).round())),
                        ),
                        child: Text(ga.cefr, style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

