// lib/widgets/linguabot/intelligent_composer.dart
import 'package:flutter/material.dart';

class IntelligentComposer extends StatefulWidget {
  final Function(String) onSend;
  final bool isThinking;
  const IntelligentComposer({super.key, required this.onSend, required this.isThinking});

  @override
  State<IntelligentComposer> createState() => _IntelligentComposerState();
}

class _IntelligentComposerState extends State<IntelligentComposer> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.black.withAlpha(77),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.purpleAccent.withAlpha(128))
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  hintText: "Type your message...",
                  hintStyle: TextStyle(color: Colors.white.withAlpha(128)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10)
              ),
              onSubmitted: widget.isThinking ? null : (value) => _send(),
            ),
          ),
          IconButton(
            icon: Icon(widget.isThinking ? Icons.hourglass_empty : Icons.send, color: Colors.purpleAccent),
            onPressed: widget.isThinking ? null : _send,
          )
        ],
      ),
    );
  }

  void _send() {
    widget.onSend(_controller.text);
    _controller.clear();
  }
}

