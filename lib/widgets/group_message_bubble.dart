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
  bool _showTranslation = true;

  Future<void> _handleTranslate() async {
    if (_translating) return;
    if (_translated == null) {
      if (!widget.canTranslate) return;
      setState(() {
        _translating = true;
      });
      try {
        await TranslationService.instance
            .ensureReady(widget.targetLanguageCode);
        final tr = await TranslationService.instance.translateFromEnglish(
            widget.message.text, widget.targetLanguageCode);
        if (mounted) setState(() => _translated = tr);
      } catch (e) {
        // Çeviri hatası görsel olarak bastırılıyor; istenirse SnackBar gösterilebilir.
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

    // Renkler
    final myStart = isDark ? Colors.teal.shade700 : Colors.teal.shade500;
    final myEnd = isDark ? Colors.teal.shade600 : Colors.teal.shade400;
    final otherBg = isDark ? (Colors.grey[850] ?? Colors.grey.shade800) : Colors.grey.shade100;
    final otherBorder = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    final textColor = isMe
        ? Colors.white
        : (isDark ? Colors.grey.shade200 : Colors.black87);

    final showTranslated =
        widget.canTranslate && _translated != null && _showTranslation;

    // Köşe yarıçapları (WhatsApp benzeri)
    final BorderRadius radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(6),
      bottomRight: isMe ? const Radius.circular(6) : const Radius.circular(18),
    );

    Widget messageContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTranslated)
          Text(
            widget.message.text,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
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
              height: 1.35,
              fontWeight:
                  showTranslated ? FontWeight.w500 : FontWeight.normal),
        ),
      ],
    );

    // Sadece saat – görüldü ikonu KALDIRILDI
    Widget timestamp = Padding(
      padding: const EdgeInsets.only(top: 2, left: 8),
      child: Text(
        DateFormat('HH:mm').format(widget.message.createdAt!.toDate()),
        style: TextStyle(
          color: textColor.withValues(alpha: 0.6),
          fontSize: 11,
        ),
      ),
    );

    // Balon kutusu – painter yerine dekorasyon
    final BoxDecoration decoration = isMe
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: [myStart, myEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          )
        : BoxDecoration(
            color: otherBg,
            borderRadius: radius,
            border: Border.all(color: otherBorder, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          );

    // Dokununca çeviri aç/kapa
    return GestureDetector(
      onTap: widget.canTranslate ? _handleTranslate : null,
      child: Container(
        decoration: decoration,
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
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: radius,
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
