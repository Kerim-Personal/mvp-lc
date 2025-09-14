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
import 'package:lingua_chat/widgets/linguabot/holographic_header.dart';
import 'package:lingua_chat/widgets/linguabot/intelligent_composer.dart';
import 'package:lingua_chat/widgets/linguabot/message_entrance_animator.dart';
import 'package:lingua_chat/widgets/linguabot/message_bubble.dart';
import 'package:lingua_chat/widgets/linguabot/celestial_background.dart';

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
      grammarAnalysis: GrammarAnalysis(tense: "Present Simple", verbCount: 1, nounCount: 2, complexity: 0.3, sentiment: 0.7),
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

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;

    // If premium, start the grammar analysis request immediately (to run concurrently)
    Future<GrammarAnalysis?> analysisFuture = widget.isPremium
        ? _botService.analyzeGrammar(text)
        : Future.value(null);

    double _computeVocabRichness(String input) {
      final words = input.toLowerCase().split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();
      if (words.isEmpty) return 0.0;
      final unique = words.toSet().length;
      return (unique / words.length).clamp(0.0, 1.0);
    }

    final userMessage = MessageUnit(
      text: text,
      sender: MessageSender.user,
      grammarAnalysis: null, // will remain null if not premium, will be filled later if premium
      vocabularyRichness: _computeVocabRichness(text),
    );

    setState(() {
      _messages.add(userMessage);
      _isBotThinking = true;
    });
    _scrollToBottom();

    // Update the message when the analysis is ready
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
    });

    final botStartTime = DateTime.now();

    await Future.delayed(Duration(milliseconds: 1500 + Random().nextInt(1500)));
    final botResponseText = await _botService.sendMessage(text);
    final botResponseTime = DateTime.now().difference(botStartTime);

    final botMessage = MessageUnit(
      text: botResponseText,
      sender: MessageSender.bot,
      botResponseTime: botResponseTime,
      grammarAnalysis: null, // Bot messages are not analyzed (requirement: only the user's own message)
      vocabularyRichness: _computeVocabRichness(botResponseText),
    );

    setState(() {
      _messages.add(botMessage);
      _isBotThinking = false;
    });
    _scrollToBottom();
  }

  void _updateMessageText(String messageId, String newText) {
    setState(() {
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        _messages[messageIndex].text = newText;
      }
    });
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
                HolographicHeader(isBotThinking: _isBotThinking),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return MessageEntranceAnimator(
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
