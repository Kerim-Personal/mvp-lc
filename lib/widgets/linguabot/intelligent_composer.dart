// lib/widgets/linguabot/intelligent_composer.dart
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:lingua_chat/services/stt_service.dart';

class IntelligentComposer extends StatefulWidget {
  final Function(String) onSend;
  final bool isThinking;
  // Yeni: hızlı öneriler (dokununca direkt gönderilir)
  final List<String> suggestions;
  const IntelligentComposer({super.key, required this.onSend, required this.isThinking, this.suggestions = const []});

  @override
  State<IntelligentComposer> createState() => _IntelligentComposerState();
}

class _IntelligentComposerState extends State<IntelligentComposer> {
  final _controller = TextEditingController();
  final _stt = SttService();
  bool _showEmoji = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _stt.stop();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stt.stop();
      setState(() => _isListening = false);
      return;
    }
    final ok = await _stt.init();
    if (!ok) return;
    setState(() => _isListening = true);
    await _stt.start(onResult: (text) {
      if (!mounted) return;
      setState(() {
        _controller.text = text;
        _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
      });
    });
  }

  void _send() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    widget.onSend(value);
    _controller.clear();
    if (_showEmoji) setState(() => _showEmoji = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeBorder = Border.all(color: Colors.purpleAccent.withAlpha(128));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.suggestions.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final s in widget.suggestions.take(6)) ...[
                    ActionChip(
                      label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      onPressed: widget.isThinking ? null : () => widget.onSend(s),
                      backgroundColor: Colors.white.withAlpha(18),
                      side: BorderSide(color: Colors.cyanAccent.withAlpha(100)),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(77),
            borderRadius: BorderRadius.circular(30),
            border: themeBorder,
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(_showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined, color: Colors.amberAccent),
                onPressed: widget.isThinking ? null : () => setState(() => _showEmoji = !_showEmoji),
                tooltip: _showEmoji ? 'Klavye' : 'Emoji',
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Mesaj yaz...",
                    hintStyle: TextStyle(color: Colors.white.withAlpha(128)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: widget.isThinking ? null : (_) => _send(),
                ),
              ),
              IconButton(
                icon: Icon(
                  widget.isThinking
                      ? Icons.hourglass_empty
                      : (_controller.text.trim().isEmpty ? (_isListening ? Icons.stop_circle_outlined : Icons.mic_none) : Icons.send),
                  color: widget.isThinking ? Colors.purpleAccent : (_controller.text.trim().isEmpty ? Colors.redAccent : Colors.purpleAccent),
                ),
                onPressed: widget.isThinking
                    ? null
                    : () {
                        if (_controller.text.trim().isEmpty) {
                          _toggleListening();
                        } else {
                          _send();
                        }
                      },
                tooltip: _controller.text.trim().isEmpty ? (_isListening ? 'Dinlemeyi durdur' : 'Sesle yaz') : 'Gönder',
              )
            ],
          ),
        ),
        if (_showEmoji)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                _controller
                  ..text += emoji.emoji
                  ..selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
                setState(() {}); // buton ikonunu güncellemek için
              },
              config: const Config(
                emojiViewConfig: EmojiViewConfig(columns: 8, emojiSizeMax: 28),
                categoryViewConfig: CategoryViewConfig(showBackspaceButton: true),
              ),
            ),
          ),
      ],
    );
  }
}
