// lib/widgets/linguabot/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingua_chat/models/grammar_analysis.dart';
import 'package:lingua_chat/models/message_unit.dart';
import 'package:lingua_chat/widgets/linguabot/message_insight_dialog.dart';
import 'package:lingua_chat/services/tts_service.dart';
import 'package:lingua_chat/services/translation_service.dart';

class MessageBubble extends StatelessWidget {
  final MessageUnit message;
  final Function(String) onCorrect;
  // To apply a special background for premium users' bubbles
  final bool isUserPremium;
  // The user's native language code for the translation target (e.g., 'en')
  final String nativeLanguage;
  // Is the user premium? This enables the translation interaction.
  final bool isPremium;
  const MessageBubble({super.key, required this.message, required this.onCorrect, this.isUserPremium = false, required this.nativeLanguage, required this.isPremium});

  TextSpan _buildAnalyzedSpan(String text, GrammarAnalysis ga, {required Color baseColor}) {
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
        spans.add(TextSpan(text: token, style: TextStyle(color: baseColor)));
      }
    }
    return TextSpan(children: spans);
  }

  Future<void> _handleTranslate(BuildContext context) async {
    if (!isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Translation is a Premium feature.')));
      return;
    }
    final src = message.text.trim();
    if (src.isEmpty) return;

    try {
      String detected = await TranslationService.instance.detectLanguage(src);
      // Determine target: EN <-> native language
      String target;
      final native = nativeLanguage.toLowerCase();
      if (detected == 'und') {
        // If uncertain: default to EN -> native, as bot messages are usually in English
        detected = message.sender == MessageSender.bot ? 'en' : (native == 'en' ? 'en' : native);
      }
      if (detected == 'en') {
        target = native == 'en' ? 'en' : native;
      } else if (detected == native) {
        target = 'en';
      } else {
        // If it's a different source language, translate to EN
        target = 'en';
      }

      if (detected == target) {
        // Already in the target language
        await _showTranslationSheet(context, original: message.text, translated: message.text, detected: detected, target: target);
        return;
      }

      final translated = await TranslationService.instance.translatePair(
        message.text,
        sourceCode: detected,
        targetCode: target,
      );

      await _showTranslationSheet(context, original: message.text, translated: translated, detected: detected, target: target);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Translation failed: $e')));
    }
  }

  Future<void> _showTranslationSheet(BuildContext context, {required String original, required String translated, required String detected, required String target}) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withAlpha(230),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.translate_rounded, color: Colors.cyanAccent),
                    const SizedBox(width: 8),
                    Text('Translation (${detected.toUpperCase()} → ${target.toUpperCase()})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy_all_rounded, color: Colors.white70),
                      tooltip: 'Copy translation',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: translated));
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Translation copied')));
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Original', style: TextStyle(color: Colors.white70.withAlpha(200), fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(original, style: const TextStyle(color: Colors.white, height: 1.4)),
                ),
                const SizedBox(height: 10),
                Text('Translation', style: TextStyle(color: Colors.cyanAccent.withAlpha(230), fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyan.withAlpha(80)),
                  ),
                  child: SingleChildScrollView(child: Text(translated, style: const TextStyle(color: Colors.white, height: 1.4))),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withAlpha(230),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final tts = TtsService();
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.content_copy, color: Colors.white70),
                title: const Text('Copy', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: message.text));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.volume_up, color: Colors.white70),
                title: const Text('Speak', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  await tts.speak(message.text, language: 'en-US');
                },
              ),
              ListTile(
                leading: const Icon(Icons.translate_rounded, color: Colors.white70),
                title: Text(isPremium ? 'Translate' : 'Translate (Premium)', style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  await _handleTranslate(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.insights, color: Colors.white70),
                title: const Text('Analyze', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withAlpha(128),
                    builder: (_) => MessageInsightDialog(
                      message: message,
                      onCorrect: onCorrect,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isUser = message.sender == MessageSender.user;
    final ga = message.grammarAnalysis;

    // Is it a premium user bubble?
    final bool premiumStyle = isUser && isUserPremium;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color baseTextColor = premiumStyle ? Colors.black87 : Colors.white;
    final Color iconColor = premiumStyle ? Colors.black54 : Colors.white70;

    // Soften the premium gradient based on the theme
    final List<Color> premiumGradientColors = isDark
        ? [const Color(0xFFFFF3E0).withOpacity(0.86), const Color(0xFFFFE082).withOpacity(0.80)]
        : [const Color(0xFFFFF8E1).withOpacity(0.95), const Color(0xFFFFE082).withOpacity(0.90)];

    Widget textWidget;
    if (isUser && ga != null) {
      textWidget = RichText(text: _buildAnalyzedSpan(message.text, ga, baseColor: baseTextColor));
    } else {
      textWidget = Text(
        message.text,
        style: TextStyle(color: baseTextColor, fontSize: 16, height: 1.5),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showActions(context),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: premiumStyle
                  ? const Color(0xFFFFD54F).withAlpha(180)
                  : (isUser ? Colors.tealAccent.withAlpha(128) : Colors.purpleAccent.withAlpha(128)),
              width: premiumStyle ? 1.1 : 1.0,
            ),
            gradient: premiumStyle
                ? LinearGradient(
              colors: premiumGradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : LinearGradient(
              colors: isUser
                  ? [Colors.teal.withAlpha(51), Colors.cyan.withAlpha(26)]
                  : [Colors.purple.withAlpha(51), Colors.deepPurple.withAlpha(26)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: premiumStyle
                ? [
              BoxShadow(
                color: const Color(0xFFFFD54F).withAlpha(40),
                blurRadius: 8,
                spreadRadius: 0.5,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
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
                ),
              // Quick actions (small icons)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      tooltip: 'Copy',
                      icon: Icon(Icons.copy, color: iconColor),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: message.text));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied')));
                      },
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      tooltip: 'Speak',
                      icon: Icon(Icons.volume_up, color: iconColor),
                      onPressed: () async {
                        await TtsService().speak(message.text, language: 'en-US');
                      },
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      tooltip: isPremium ? 'Translate' : 'Translate (Premium)',
                      icon: Icon(Icons.translate_rounded, color: iconColor),
                      onPressed: () async {
                        await _handleTranslate(context);
                      },
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      tooltip: 'Analyze',
                      icon: Icon(Icons.insights, color: iconColor),
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.black.withAlpha(128),
                          builder: (_) => MessageInsightDialog(
                            message: message,
                            onCorrect: onCorrect,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}