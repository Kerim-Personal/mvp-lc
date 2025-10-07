// lib/widgets/linguabot/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocachat/models/grammar_analysis.dart';
import 'package:vocachat/models/message_unit.dart';
import 'package:vocachat/widgets/linguabot/message_insight_dialog.dart';
import 'package:vocachat/services/tts_service.dart';
import 'package:vocachat/services/translation_service.dart';
import 'package:vocachat/services/ai_translation_service.dart';

class MessageBubble extends StatelessWidget {
  final MessageUnit message;
  final Function(String) onCorrect;
  final bool isUserPremium;
  final String nativeLanguage;
  final bool isPremium;
  // Yeni: Quiz cevabı callback (sadece index)
  final ValueChanged<int>? onQuizAnswer;
  const MessageBubble({super.key, required this.message, required this.onCorrect, this.isUserPremium = false, required this.nativeLanguage, required this.isPremium, this.onQuizAnswer});

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
      final native = nativeLanguage.toLowerCase();
      if (detected == 'und') {
        detected = message.sender == MessageSender.bot ? 'en' : native;
      }
      final target = native; // her zaman anadil

      Future<String>? fut;
      if (detected != target) {
        fut = AiTranslationService.instance.translate(text: message.text, targetCode: target);
      }

      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.black.withAlpha(230),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (_) => _TranslationSheet(
          original: message.text,
          detected: detected,
            target: target,
          translationFuture: fut,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Translation failed: $e')));
    }
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
                  MessageBubble._showCopied(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.volume_up, color: Colors.white70),
                title: const Text('Speak', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  await tts.speakSmart(message.text, hintLanguageCode: message.sender == MessageSender.bot ? _guessLangFromMessage(message.text) : nativeLanguage);
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

  static void _showCopied(BuildContext context) {
    // İngilizce 'Copied' SnackBar'ı kaldırıldı. Diğer yerde gösterilen 'kopyalandı' bildirimi yeterli.
    // Bu fonksiyon artık bilerek boş bırakıldı (görsel geri bildirim istenirse burada yeniden eklenebilir).
  }

  Widget _buildQuiz(BuildContext context, Color baseTextColor) {
    final quiz = message.quiz!;
    final selected = message.selectedOptionIndex;
    final correct = quiz.correctIndex;

    Color tileColor(int idx) {
      if (selected == null) return Colors.white.withAlpha(12);
      if (idx == correct) return Colors.green.withAlpha(40);
      if (idx == selected && idx != correct) return Colors.red.withAlpha(40);
      return Colors.white.withAlpha(10);
    }

    Color borderColor(int idx) {
      if (selected == null) return Colors.white24;
      if (idx == correct) return Colors.greenAccent;
      if (idx == selected && idx != correct) return Colors.redAccent;
      return Colors.white24;
    }

    IconData iconFor(int idx) {
      if (selected == null) return Icons.circle_outlined;
      if (idx == correct) return Icons.check_circle;
      if (idx == selected && idx != correct) return Icons.cancel;
      return Icons.circle_outlined;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(quiz.question, style: TextStyle(color: baseTextColor, fontSize: 16, height: 1.4, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...List.generate(quiz.options.length, (i) {
          final opt = quiz.options[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: tileColor(i),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor(i), width: 1),
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              leading: Icon(iconFor(i), color: borderColor(i)),
              title: Text(opt, style: TextStyle(color: baseTextColor, fontSize: 15)),
              onTap: selected == null ? () => onQuizAnswer?.call(i) : null,
            ),
          );
        }),
        if (selected != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: (selected == correct ? Colors.green.withAlpha(28) : Colors.red.withAlpha(28)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected == correct ? Colors.greenAccent : Colors.redAccent, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(selected == correct ? Icons.emoji_events : Icons.school,
                    color: selected == correct ? Colors.greenAccent : Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selected == correct ? quiz.onCorrectNative : quiz.onWrongNative,
                    style: TextStyle(color: baseTextColor, fontSize: 14, height: 1.35),
                  ),
                ),
              ],
            ),
          )
        ]
      ],
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
        ? [const Color(0xFFFFF3E0).withValues(alpha: 0.86), const Color(0xFFFFE082).withValues(alpha: 0.80)]
        : [const Color(0xFFFFF8E1).withValues(alpha: 0.95), const Color(0xFFFFE082).withValues(alpha: 0.90)];

    Widget textWidget;
    if (!isUser && message.quiz != null) {
      textWidget = _buildQuiz(context, baseTextColor);
    } else if (isUser && ga != null) {
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
              if (message.quiz == null) // quiz mesajında gizle
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
                          MessageBubble._showCopied(context);
                        },
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        tooltip: 'Speak',
                        icon: Icon(Icons.volume_up, color: iconColor),
                        onPressed: () async {
                          await TtsService().speakSmart(message.text, hintLanguageCode: message.sender == MessageSender.bot ? _guessLangFromMessage(message.text) : nativeLanguage);
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

class _TranslationSheet extends StatefulWidget {
  final String original;
  final String detected;
  final String target;
  final Future<String>? translationFuture; // null -> çeviri yok (aynı dil)
  const _TranslationSheet({required this.original, required this.detected, required this.target, required this.translationFuture});
  @override
  State<_TranslationSheet> createState() => _TranslationSheetState();
}

class _TranslationSheetState extends State<_TranslationSheet> {
  String? _translated;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() async {
    if (widget.translationFuture == null) {
      // Çeviri gerekmiyor
      setState(() => _translated = widget.original);
      return;
    }
    try {
      final res = await widget.translationFuture!;
      if (!mounted) return;
      setState(() => _translated = res.trim().isEmpty ? widget.original : res.trim());
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = true; _translated = widget.original; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = _translated == null && !_error;
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
                Text('Translation (${widget.detected.toUpperCase()} → ${widget.target.toUpperCase()})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (loading) const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth:2)),
                IconButton(
                  icon: const Icon(Icons.copy_all_rounded, color: Colors.white70),
                  tooltip: 'Copy translation',
                  onPressed: _translated==null ? null : () async {
                    await Clipboard.setData(ClipboardData(text: _translated!));
                    if (context.mounted) {
                      MessageBubble._showCopied(context);
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
              child: Text(widget.original, style: const TextStyle(color: Colors.white, height: 1.4)),
            ),
            const SizedBox(height: 10),
            Text('Translation', style: TextStyle(color: Colors.cyanAccent.withAlpha(230), fontSize: 12)),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.cyan.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyan.withAlpha(80)),
              ),
              child: _error ? const Text('Translation failed', style: TextStyle(color: Colors.redAccent))
                  : loading ? const Text('Translating...', style: TextStyle(color: Colors.white70))
                  : SingleChildScrollView(child: Text(_translated!, style: const TextStyle(color: Colors.white, height: 1.4))),
            ),
          ],
        ),
      ),
    );
  }
}

// Yardımcı: basit dil ipucu (bot mesajı için) - alt kısma ekliyoruz
String _guessLangFromMessage(String text) {
  final lower = text.toLowerCase();
  if (RegExp(r'[çğıışöü]').hasMatch(lower) || lower.contains('hoş geldin')) return 'tr';
  if (lower.contains('bienvenido') || RegExp(r'[áéíñóúü¿¡]').hasMatch(lower)) return 'es';
  if (lower.contains('willkommen') || RegExp(r'[äöüß]').hasMatch(lower)) return 'de';
  if (lower.contains('bon retour') || lower.contains('prêt')) return 'fr';
  if (lower.contains('bentornato') || lower.contains('universo')) return 'it';
  if (lower.contains('bem-vindo') || lower.contains('idiomas')) return 'pt';
  return 'en';
}
