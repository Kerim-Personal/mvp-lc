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
    final bool premiumStyle = widget.message.senderIsPremium;

    // Renkler
    final myStart = isDark ? Colors.teal.shade700 : Colors.teal.shade500;
    final myEnd = isDark ? Colors.teal.shade600 : Colors.teal.shade400;
    final otherBg = isDark ? (Colors.grey[850] ?? Colors.grey.shade800) : Colors.grey.shade100;
    final otherBorder = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    // Premium gradyanını temaya göre yumuşat
    final List<Color> premiumGradientColors = isDark
        ? [const Color(0xFFFFF3E0).withValues(alpha: 0.86), const Color(0xFFFFE082).withValues(alpha: 0.80)]
        : [const Color(0xFFFFF8E1).withValues(alpha: 0.95), const Color(0xFFFFE082).withValues(alpha: 0.90)];
    final Color premiumBorderColor = const Color(0xFFFFD54F).withAlpha(isDark ? 180 : 200);
    final Color premiumShadowColor = const Color(0xFFFFD54F).withAlpha(isDark ? 40 : 48);

    // Premium balonlarda açık altın zeminde koyu metin; aksi halde mevcut mantık
    final Color textColor = premiumStyle
        ? Colors.black87
        : (isMe
            ? Colors.white
            : (isDark ? Colors.grey.shade200 : Colors.black87));

    final showTranslated =
        widget.canTranslate && _translated != null && _showTranslation;

    // Köşe yarıçapları (WhatsApp benzeri)
    final BorderRadius radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(6),
      bottomRight: isMe ? const Radius.circular(6) : const Radius.circular(18),
    );

    // Mesaj içeriği
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

    // Saat metni
    final String timeText =
        DateFormat('HH:mm').format(widget.message.createdAt!.toDate());
    final Widget timestamp = Text(
      timeText,
      style: TextStyle(
        color: textColor.withValues(alpha: 0.6),
        fontSize: 11,
      ),
    );

    // Balon kutusu – premium ise altın gradyan; değilse eski stil
    final BoxDecoration decoration = premiumStyle
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: premiumGradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: radius,
            border: Border.all(color: premiumBorderColor, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: premiumShadowColor,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          )
        : (isMe
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
              ));

    // Dokununca çeviri aç/kapa
    return GestureDetector(
      onTap: widget.canTranslate ? _handleTranslate : null,
      child: Container(
        decoration: decoration,
        // Min genişlik -> saat + iç padding için yeterli alan
        constraints: const BoxConstraints(minWidth: 72),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metin, sağda saate yer bırakmak için hafif sağ padding ile
                Padding(
                  padding: const EdgeInsets.only(right: 36.0),
                  child: messageContent,
                ),
                const SizedBox(height: 2),
                // Saat alt-sağda ayrı bir satırda
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [timestamp],
                ),
              ],
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
