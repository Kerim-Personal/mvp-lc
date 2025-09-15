// lib/screens/linguabot_chat_screen.dart
// This is not a chat screen, it's a language universe simulator.
// v2.4.0: Star animations have been calmed and naturalized. The environment is now authentic and not distracting.

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lingua_chat/services/linguabot_service.dart';
import 'package:lingua_chat/models/grammar_analysis.dart';
import 'package:lingua_chat/models/message_unit.dart';
import 'package:lingua_chat/widgets/linguabot/linguabot.dart';
import 'package:lingua_chat/utils/text_metrics.dart';

// --- MAIN SCREEN: THE HEART OF THE SIMULATOR ---

class LinguaBotChatScreen extends StatefulWidget {
  final bool isPremium;
  const LinguaBotChatScreen({super.key, this.isPremium = false});

  @override
  State<LinguaBotChatScreen> createState() => _LinguaBotChatScreenState();
}

class _LinguaBotChatScreenState extends State<LinguaBotChatScreen> with TickerProviderStateMixin {
  final LinguaBotService _botService = LinguaBotService();
  final ScrollController _scrollController = ScrollController();
  final List<MessageUnit> _messages = [];
  bool _isBotThinking = false;

  late AnimationController _backgroundController;
  late AnimationController _entryController;
  late Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _blurAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _messages.add(MessageUnit(
      text: "Welcome back to the language universe. Ready to push your limits?",
      sender: MessageSender.bot,
      grammarAnalysis: const GrammarAnalysis(tense: "Present Simple", verbCount: 1, nounCount: 2, complexity: 0.3, sentiment: 0.7),
    ));

    _entryController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _entryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _computeSuggestions() {
    if (_isBotThinking) return const [];
    if (_messages.isEmpty) {
      return const [
        'Hi! Can you test me with a travel topic? ✈️',
        'Let’s practice small talk about work.',
        'Give me a B1-level question.'
      ];
    }
    final last = _messages.last;
    if (last.sender == MessageSender.bot) {
      return const [
        'Could you ask me a follow-up question?',
        'Can you correct my last sentence if needed?',
        'How would a native say that?'
      ];
    } else {
      return const [
        'Please evaluate my grammar briefly.',
        'Suggest a richer phrase I can use.',
        'Ask me something tricky!'
      ];
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;

    // Gramer analizi: her durumda paralel başlat
    final Future<GrammarAnalysis?> analysisFuture = _botService.analyzeGrammar(text);

    final userMessage = MessageUnit(
      text: text,
      sender: MessageSender.user,
      grammarAnalysis: null, // analiz hazır olduğunda doldurulacak
      vocabularyRichness: TextMetrics.vocabularyRichness(text),
    );

    setState(() {
      _messages.add(userMessage);
      _isBotThinking = true;
    });
    _scrollToBottom();

    // Analiz tamamlanınca mesajı güncelle
    analysisFuture.then((analysis) {
      if (!mounted) return;
      if (analysis != null) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == userMessage.id);
          if (idx != -1) {
            _messages[idx].grammarAnalysis = analysis;
          }
        });
      }
    }).catchError((_) {
      // sessizce yoksay
    });

    final botStartTime = DateTime.now();

    try {
      await Future.delayed(Duration(milliseconds: 1500 + Random().nextInt(1500)));
      final botResponseText = await _botService.sendMessage(text);
      final botResponseTime = DateTime.now().difference(botStartTime);

      final botMessage = MessageUnit(
        text: botResponseText,
        sender: MessageSender.bot,
        botResponseTime: botResponseTime,
        grammarAnalysis: null, // bot mesajları analiz edilmez
        vocabularyRichness: TextMetrics.vocabularyRichness(botResponseText),
      );

      if (!mounted) return;
      setState(() {
        _messages.add(botMessage);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mesaj gönderilirken bir sorun oluştu.')));
    } finally {
      if (!mounted) return;
      setState(() => _isBotThinking = false);
      _scrollToBottom();
    }
  }

  void _updateMessageText(String messageId, String newText) {
    setState(() {
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        _messages[messageIndex].text = newText;
      }
    });
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withAlpha(235),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Ayarlar', style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('• Premium analiz sohbet sırasında otomatik çalışır.', style: TextStyle(color: Colors.white70)),
              Text('• Mesaj balonuna uzun basarak kopyalama / seslendirme / analiz seçeneklerine erişin.', style: TextStyle(color: Colors.white70)),
              Text('• Composer üzerinden emoji ve sesle yazma kullanılabilir.', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _computeSuggestions();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CelestialBackground(controller: _backgroundController),
          AnimatedBuilder(
            animation: _entryController,
            builder: (context, child) => BackdropFilter(
              filter: ImageFilter.blur(sigmaX: _blurAnimation.value, sigmaY: _blurAnimation.value),
              child: child,
            ),
            // IMPROVEMENT: A slight overlay has been added for the effect to be more pronounced.
            child: Container(color: Colors.black.withAlpha(26)),
          ),
          SafeArea(
            child: Column(
              children: [
                HolographicHeader(isBotThinking: _isBotThinking, onSettingsTap: _openSettings),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    itemCount: _messages.length + (_isBotThinking ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const MessageEntranceAnimator(child: TypingIndicator());
                      }
                      final message = _messages[index];
                      return MessageEntranceAnimator(
                        key: ValueKey(message.id),
                        child: MessageBubble(
                          message: message,
                          onCorrect: (newText) => _updateMessageText(message.id, newText),
                        ),
                      );
                    },
                  ),
                ),
                IntelligentComposer(
                  onSend: _sendMessage,
                  isThinking: _isBotThinking,
                  suggestions: suggestions,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
