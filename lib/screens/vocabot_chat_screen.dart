// lib/screens/vocabot_chat_screen.dart
// This is not a chat screen, it's a language universe simulator.
// v2.4.0: Star animations have been calmed and naturalized. The environment is now authentic and not distracting.

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vocachat/services/vocabot_service.dart';
import 'package:vocachat/models/grammar_analysis.dart';
import 'package:vocachat/models/message_unit.dart';
import 'package:vocachat/widgets/linguabot/linguabot.dart';
import 'package:vocachat/utils/text_metrics.dart';
import 'package:vocachat/widgets/message_composer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocachat/services/translation_service.dart';

// --- MAIN SCREEN: THE HEART OF THE SIMULATOR ---

class LinguaBotChatScreen extends StatefulWidget {
  final bool isPremium;
  const LinguaBotChatScreen({super.key, this.isPremium = false});

  @override
  State<LinguaBotChatScreen> createState() => _LinguaBotChatScreenState();
}

class _LinguaBotChatScreenState extends State<LinguaBotChatScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final LinguaBotService _botService = LinguaBotService();
  final ScrollController _scrollController = ScrollController();
  final List<MessageUnit> _messages = [];
  bool _isBotThinking = false;
  String _nativeLanguage = 'en';
  bool _isPremium = false;
  bool _allowPop = false; // allow programmatic pop after confirm
  bool _composerEmojiOpen = false; // composer emoji panel durumu

  late AnimationController _backgroundController;
  late AnimationController _entryController;
  late Animation<double> _blurAnimation;

  // Oturum süresi takibi (leaderboard için totalRoomTime)
  DateTime? _sessionStart;
  static const int _maxSessionSeconds = 6 * 60 * 60; // 6 saat güvenlik sınırı

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionStart = DateTime.now();

    _backgroundController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _blurAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _messages.add(MessageUnit(
      text: "Welcome back to the language universe. Ready to push your limits?",
      sender: MessageSender.bot,
      grammarAnalysis: const GrammarAnalysis(tense: "Present Simple", verbCount: 1, nounCount: 2, complexity: 0.3, sentiment: 0.7),
    ));

    _entryController.forward();
    _loadNativeLanguage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _commitAndResetSessionTime();
    _backgroundController.dispose();
    _entryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _commitAndResetSessionTime();
    } else if (state == AppLifecycleState.resumed) {
      // Yeni dilim için başlangıcı sıfırla
      _sessionStart = DateTime.now();
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _commitAndResetSessionTime() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final start = _sessionStart;
    if (start == null) {
      _sessionStart = DateTime.now();
      return;
    }
    final seconds = DateTime.now().difference(start).inSeconds;
    if (seconds > 0) {
      final safeSeconds = seconds > _maxSessionSeconds ? _maxSessionSeconds : seconds;
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'totalRoomTime': FieldValue.increment(safeSeconds)});
      } catch (_) {
        // sessiz: offline veya yetki hatası olabilir
      }
    }
    // Yeni dilim için başlangıcı sıfırla
    _sessionStart = DateTime.now();
  }

  Future<void> _loadNativeLanguage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = snap.data();
      if (!mounted || data == null) return;
      setState(() {
        _nativeLanguage = (data['nativeLanguage'] as String?) ?? 'en';
        _isPremium = (data['isPremium'] as bool?) ?? false;
      });
      // Premium + EN dışı anadil için çeviri modellerini önden indir
      if (_isPremium && _nativeLanguage.toLowerCase() != 'en') {
        unawaited(TranslationService.instance.preDownloadModels(_nativeLanguage));
      }
    } catch (_) {
      // sessizce geç
    }
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('There was a problem sending the message.')));
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
              Text('Settings', style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('• Premium analysis runs automatically during chat.', style: TextStyle(color: Colors.white70)),
              Text('• Long-press a bubble for copy / TTS / analysis options.', style: TextStyle(color: Colors.white70)),
              Text('• Use emojis and voice typing from the composer.', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // Chat exit confirmation dialog
  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black.withAlpha(235),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          title: const Text('Leave chat?', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to exit this chat screen?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.cyanAccent)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
    return result ?? false;
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
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Eğer alt composer geri tuşunu emoji/klavye kapatmak için kullandıysa, onay diyaloğunu açmayalım
        final primaryFocus = FocusManager.instance.primaryFocus;
        if (_composerEmojiOpen || (primaryFocus != null && primaryFocus.hasFocus)) {
          return;
        }
        _confirmExit().then((shouldPop) async {
          if (shouldPop && mounted) {
            await _commitAndResetSessionTime();
            setState(() => _allowPop = true);
            Navigator.of(context).pop();
          }
        });
      },
      child: Scaffold(
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
                            isUserPremium: _isPremium,
                            nativeLanguage: _nativeLanguage,
                            isPremium: _isPremium,
                          ),
                        );
                      },
                    ),
                  ),
                  if (suggestions.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: suggestions
                              .take(6)
                              .map((s) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ActionChip(
                                      label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      onPressed: _isBotThinking ? null : () => _sendMessage(s),
                                      backgroundColor: Colors.black.withAlpha(64),
                                      side: BorderSide(color: Colors.cyanAccent.withAlpha(100)),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: ThemeData.dark().colorScheme.copyWith(
                        primary: Colors.cyanAccent,
                        surface: const Color(0xFF121212),
                        onSurface: Colors.white,
                      ),
                      iconTheme: const IconThemeData(color: Colors.white),
                      hintColor: Colors.white70,
                      dividerColor: Colors.white24,
                      cardColor: const Color(0xFF1E1E1E),
                    ),
                    child: MessageComposer(
                      onSend: _sendMessage,
                      nativeLanguage: _nativeLanguage,
                      enableTranslation: _nativeLanguage != 'en',
                      enableSpeech: true,
                      enableEmojis: true,
                      hintText: 'Type a message...',
                      characterLimit: 1000,
                      enabled: true,
                      onEmojiVisibilityChanged: (open) => setState(() => _composerEmojiOpen = open),
                      isPremium: _isPremium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
