// lib/widgets/group_message_bubble.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/models/group_message.dart';
import 'package:lingua_chat/services/translation_service.dart';
import 'package:lingua_chat/models/grammar_analysis.dart';

class GroupMessageBubble extends StatefulWidget {
  final GroupMessage message;
  final bool isMe;
  final bool canTranslate;
  final String targetLanguageCode;
  final GrammarAnalysis? grammarAnalysis; // premium kendi mesajı
  final bool analyzing;

  const GroupMessageBubble({super.key, required this.message, required this.isMe, required this.canTranslate, required this.targetLanguageCode, this.grammarAnalysis, this.analyzing = false});

  @override
  State<GroupMessageBubble> createState() => _GroupMessageBubbleState();
}

class _GroupMessageBubbleState extends State<GroupMessageBubble> {
  String? _translated;
  bool _translating = false;
  String? _error;
  bool _showTranslation = true;

  Future<void> _handleTranslate() async {
    if (_translating) return;
    if (_translated == null) {
      if (!widget.canTranslate) return;
      setState(() { _translating = true; _error = null; });
      try {
        await TranslationService.instance.ensureReady(widget.targetLanguageCode);
        final tr = await TranslationService.instance.translateFromEnglish(widget.message.text, widget.targetLanguageCode);
        setState(() { _translated = tr; _showTranslation = true; });
      } catch (e) {
        setState(() { _error = 'Çeviri başarısız: ${e.toString()}'; });
      } finally {
        if (mounted) setState(() { _translating = false; });
      }
    } else {
      setState(() { _showTranslation = !_showTranslation; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    final baseColor = isMe ? Colors.white : Colors.black87;

    // Mesaj balonu için tekil radius tanımı (overlay ile birebir aynı kullanılacak)
    final BorderRadius bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
    );

    // Çok uzun mesajlarda avatar/zaman ile çakışmayı önlemek için üst genişlik sınırı
    final double maxBubbleWidth = MediaQuery.of(context).size.width * 0.72;

    Widget inner;
    if (widget.canTranslate && _translated != null && _showTranslation) {
      inner = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.message.text,
            style: TextStyle(color: baseColor.withValues(alpha: 0.65), fontSize: 13, fontStyle: FontStyle.italic, height: 1.25),
            softWrap: true,
            overflow: TextOverflow.visible,
            textWidthBasis: TextWidthBasis.parent,
          ),
          const SizedBox(height: 3),
          Text(
            _translated!,
            style: TextStyle(color: baseColor, fontSize: 14, fontWeight: FontWeight.w500, height: 1.25),
            softWrap: true,
            overflow: TextOverflow.visible,
            textWidthBasis: TextWidthBasis.parent,
          ),
        ],
      );
    } else {
      inner = Text(
        widget.message.text,
        style: TextStyle(color: baseColor, fontSize: 14, height: 1.25),
        softWrap: true,
        overflow: TextOverflow.visible,
        textWidthBasis: TextWidthBasis.parent,
      );
    }

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.teal.shade300 : Colors.grey.shade200,
        borderRadius: bubbleRadius,
      ),
      child: inner,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.canTranslate ? _handleTranslate : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            child: ClipRRect(
              borderRadius: bubbleRadius,
              child: Stack(
                children: [
                  bubble,
                  if (_translating)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4),
            child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
          ),
      ],
    );
  }
}

