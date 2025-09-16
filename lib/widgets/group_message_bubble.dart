// lib/widgets/group_message_bubble.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/models/group_message.dart';
import 'package:lingua_chat/services/translation_service.dart';
import 'package:lingua_chat/models/grammar_analysis.dart';

class GroupMessageBubble extends StatefulWidget {
  final GroupMessage message;
  final bool isMe;
  final bool canTranslate;
  final String targetLanguageCode;
  final GrammarAnalysis? grammarAnalysis;
  final bool analyzing;
  final bool isContinuation;

  const GroupMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.canTranslate,
    required this.targetLanguageCode,
    this.grammarAnalysis,
    this.analyzing = false,
    this.isContinuation = false,
  });

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
      setState(() {
        _translating = true;
        _error = null;
      });
      try {
        await TranslationService.instance
            .ensureReady(widget.targetLanguageCode);
        final tr = await TranslationService.instance.translateFromEnglish(
            widget.message.text, widget.targetLanguageCode);
        if (mounted) setState(() => _translated = tr);
      } catch (e) {
        if (mounted) setState(() => _error = 'Translation failed.');
      } finally {
        if (mounted) setState(() => _translating = false);
      }
    } else {
      setState(() => _showTranslation = !_showTranslation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMe = widget.isMe;

    final myBubbleColor = isDark ? Colors.teal.shade700 : Colors.teal.shade500;
    final otherBubbleColor =
        isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    final bubbleColor = isMe ? myBubbleColor : otherBubbleColor;
    final textColor = isMe
        ? Colors.white
        : (isDark ? Colors.grey.shade200 : Colors.black87);

    final showTranslated =
        widget.canTranslate && _translated != null && _showTranslation;

    Widget messageContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTranslated)
          Text(
            widget.message.text,
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              height: 1.3,
            ),
          ),
        if (showTranslated) const SizedBox(height: 4),
        Text(
          showTranslated ? _translated! : widget.message.text,
          style: TextStyle(
              color: textColor,
              fontSize: 15,
              height: 1.3,
              fontWeight:
                  showTranslated ? FontWeight.w500 : FontWeight.normal),
        ),
      ],
    );

    Widget timestamp = Padding(
      padding: const EdgeInsets.only(top: 2, left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('HH:mm').format(widget.message.createdAt!.toDate()),
            style: TextStyle(
              color: textColor.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 4),
            Icon(Icons.done_all_rounded,
                size: 14, color: textColor.withOpacity(0.6)),
          ]
        ],
      ),
    );

    return CustomPaint(
      painter: _BubblePainter(
        color: bubbleColor,
        isMe: isMe,
        isContinuation: widget.isContinuation,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: messageContent,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: timestamp,
            ),
            if (_translating)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final Color color;
  final bool isMe;
  final bool isContinuation;

  _BubblePainter({
    required this.color,
    required this.isMe,
    required this.isContinuation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final RRect rrect = RRect.fromLTRBAndCorners(
      0,
      0,
      size.width,
      size.height,
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft:
          isMe ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight:
          isMe ? const Radius.circular(4) : const Radius.circular(18),
    );

    canvas.drawRRect(rrect, paint);

    if (!isContinuation) {
      final path = Path();
      if (isMe) {
        path.moveTo(size.width - 0.5, size.height - 10);
        path.quadraticBezierTo(
          size.width + 8,
          size.height,
          size.width,
          size.height,
        );
        path.close();
      } else {
        path.moveTo(0.5, size.height - 10);
        path.quadraticBezierTo(
          -8,
          size.height,
          0,
          size.height,
        );
        path.close();
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

