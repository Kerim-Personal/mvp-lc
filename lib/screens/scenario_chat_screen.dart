// lib/screens/scenario_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:vocachat/services/vocabot_service.dart';
import 'package:vocachat/models/message_unit.dart';
import 'package:vocachat/widgets/message_composer.dart';
import 'package:vocachat/widgets/vocabot/linguabot.dart';
import 'package:vocachat/utils/text_metrics.dart';

class ScenarioChatScreen extends StatefulWidget {
  final String scenario;
  final String targetLanguage;
  final String nativeLanguage;
  final String learningLevel;

  const ScenarioChatScreen({
    super.key,
    required this.scenario,
    required this.targetLanguage,
    required this.nativeLanguage,
    this.learningLevel = 'medium',
  });

  @override
  State<ScenarioChatScreen> createState() => _ScenarioChatScreenState();
}

class _ScenarioChatScreenState extends State<ScenarioChatScreen> {
  late LinguaBotService _botService;
  final ScrollController _scrollController = ScrollController();
  final List<MessageUnit> _messages = [];
  bool _isBotThinking = false;
  bool _botReady = false;

  // Bot karakteri (cinsiyet ve avatar için)
  String _botGender = 'female';
  String get _botName => _botGender == 'male' ? 'Alex' : 'Emma';

  @override
  void initState() {
    super.initState();
    _botService = LinguaBotService(
      targetLanguage: widget.targetLanguage,
      nativeLanguage: widget.nativeLanguage,
      learningLevel: widget.learningLevel,
    );
    _determineBotGender();
    _botReady = true;
    _sendInitialBotMessage();
  }

  void _determineBotGender() {
    final scenario = widget.scenario.toLowerCase();
    if (scenario.contains('doktor') ||
        scenario.contains('tamirci') ||
        scenario.contains('taksi') ||
        scenario.contains('benzin')) {
      _botGender = 'male';
    } else if (scenario.contains('hemşire') ||
               scenario.contains('öğretmen') ||
               scenario.contains('eczane')) {
      _botGender = 'female';
    } else {
      _botGender = DateTime.now().millisecond % 2 == 0 ? 'male' : 'female';
    }
  }

  // Senaryoya göre doğal ilk mesaj prompts (yedek; backend zaten yönetiyor)
  String _getInitialPrompt() {
    final s = widget.scenario.toLowerCase();
    final lang = widget.targetLanguage;

    // Her senaryo için spesifik, doğal bir açılış oluştur (20 temel durum)
    if (s.contains('restoran')) {
      return 'ROLEPLAY: You ARE a waiter. Customer sits. Say ONE short greeting in $lang. Respond ONLY in $lang. No explanations. Keep it natural and brief. Example: "İyi akşamlar, ne içmek istersiniz?"';
    } else if (s.contains('rezervasyon') || s.contains('reservation')) {
      return 'ROLEPLAY: You ARE a restaurant host. Guest calls/arrives to book. Say ONE short greeting in $lang and ask for details. Respond ONLY in $lang. Natural and brief.';
    } else if (s.contains('kafe') || s.contains('cafe')) {
      return 'ROLEPLAY: You ARE a barista. Customer enters. Say ONE short greeting in $lang and ask their order. Respond ONLY in $lang. Natural and brief.';
    } else if (s.contains('otel') || s.contains('check-in')) {
      return 'ROLEPLAY: You ARE hotel reception. Guest arrives for check-in. Say ONE professional greeting in $lang and request a detail (e.g., name). Respond ONLY in $lang. Brief.';
    } else if ((s.contains('otel') && s.contains('şikayet')) || s.contains('otel şikayet')) {
      return 'ROLEPLAY: You ARE a hotel manager. Guest has a complaint. Start with ONE polite greeting in $lang and ask what happened. Respond ONLY in $lang. Natural and brief.';
    } else if (s.contains('havaliman') || s.contains('airport')) {
      return 'ROLEPLAY: You ARE airport staff. Passenger approaches. Say ONE short greeting in $lang and offer help. Respond ONLY in $lang. Natural and brief.';
    } else if (s.contains('pasaport')) {
      return 'ROLEPLAY: You ARE a border control officer. Greet in $lang and ask for passport. Respond ONLY in $lang. Natural and brief.';
    } else if (s.contains('gümrük') || s.contains('customs')) {
      return 'ROLEPLAY: You ARE a customs officer. Greet in $lang and ask a simple question (e.g., anything to declare). Respond ONLY in $lang. Brief.';
    } else if ((s.contains('turist') && s.contains('bilgi')) || s.contains('tourist info')) {
      return 'ROLEPLAY: You ARE a tourist information agent. Greet in $lang and ask how you can help. Respond ONLY in $lang. Natural and brief.';
    } else if (s.contains('otobüs') || s.contains('otobuste') || s.contains('bus')) {
      return 'ROLEPLAY: You ARE a bus driver/ticket agent. Greet in $lang and ask destination. Respond ONLY in $lang. Natural and brief.';
    } else if (s.contains('tren') || s.contains('train')) {
      return 'ROLEPLAY: You ARE a station clerk. Greet in $lang and ask where they are traveling. Respond ONLY in $lang. Natural and brief.';
    } else if (s.contains('taksi')) {
      return 'ROLEPLAY: You ARE a taxi driver. Passenger enters. Greet in $lang and ask where to. Respond ONLY in $lang. Natural and brief. Example: "Nereye gidiyorsunuz?"';
    } else if ((s.contains('araç') && s.contains('kirala')) || s.contains('rent a car') || s.contains('araç kiralama')) {
      return 'ROLEPLAY: You ARE a car rental desk agent. Greet in $lang and ask for booking or dates. Respond ONLY in $lang. Brief and natural.';
    } else if (s.contains('benzin') || s.contains('gas station')) {
      return 'ROLEPLAY: You ARE a gas station attendant. Greet in $lang and ask how much/fuel type. Respond ONLY in $lang. Natural and brief.';
    } else if (s.contains('banka')) {
      return 'ROLEPLAY: You ARE a bank teller. Greet in $lang and ask what service they need. Respond ONLY in $lang. Natural and brief.';
    } else if (s.contains('eczane') || s.contains('pharmac')) {
      return 'ROLEPLAY: You ARE a pharmacist. Greet in $lang and ask how you can help. Respond ONLY in $lang. Natural and brief.';
    } else if (s.contains('doktor') || s.contains('hastane') || s.contains('randevu')) {
      return 'ROLEPLAY: You ARE a doctor. Patient enters. Greet in $lang and ask about the issue. Respond ONLY in $lang. Natural and brief.';
    } else if (s.contains('market') || s.contains('alışveriş') || s.contains('supermarket')) {
      return 'ROLEPLAY: You ARE a store employee. Greet in $lang and offer help. Respond ONLY in $lang. Natural and brief.';
    } else if (s.contains('müşteri hizmet') || s.contains('customer service') || s.contains('telefon')) {
      return 'ROLEPLAY: You ARE a call center agent. Answer in $lang with ONE short greeting and offer help. Respond ONLY in $lang. Natural and brief.';
    } else if (s.contains('yön') && (s.contains('tarifi') || s.contains('tarif'))) {
      return 'ROLEPLAY: You ARE a local person in the street. Someone asks for directions. Greet in $lang and ask where they need to go. Respond ONLY in $lang. Natural and brief.';
    } else {
      // Genel yedek
      return 'ROLEPLAY: ${widget.scenario}. You ARE this person. Say ONE natural greeting in $lang. Respond ONLY in $lang. No teaching. Keep it short and natural.';
    }
  }

  Future<void> _sendInitialBotMessage() async {
    setState(() => _isBotThinking = true);

    try {
      // Dil karışmasını önlemek için: içerik yönlendirmesini backend yapsın
      // Nötr bir başlangıç sinyali gönderiyoruz
      final response = await _botService.sendMessage(
        '#start',
        scenario: widget.scenario,
      );

      if (mounted) {
        setState(() {
          _messages.add(MessageUnit(
            text: response,
            sender: MessageSender.bot,
          ));
          _isBotThinking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(MessageUnit(
            text: 'Hello!',
            sender: MessageSender.bot,
          ));
          _isBotThinking = false;
        });
      }
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || !_botReady) return;

    final userMessage = MessageUnit(
      text: text.trim(),
      sender: MessageSender.user,
      vocabularyRichness: TextMetrics.vocabularyRichness(text),
    );

    setState(() {
      _messages.add(userMessage);
      _isBotThinking = true;
    });

    // Sohbet geçmişini hazırla
    final chatHistory = _messages.map((m) => {
      'role': m.sender == MessageSender.user ? 'user' : 'assistant',
      'content': m.text,
    }).toList();

    try {
      final response = await _botService.sendMessage(
        text,
        scenario: widget.scenario,
        chatHistory: chatHistory.length > 8 ? chatHistory.sublist(chatHistory.length - 8) : chatHistory,
      );

      if (mounted) {
        setState(() {
          _messages.add(MessageUnit(
            text: response,
            sender: MessageSender.bot,
            vocabularyRichness: TextMetrics.vocabularyRichness(response),
          ));
          _isBotThinking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBotThinking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send message.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.cyanAccent.withAlpha(200),
                    Colors.cyanAccent.withAlpha(120),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  _botName[0],
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _botName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.scenario,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: _messages.length + (_isBotThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isBotThinking && index == 0) {
                  return const MessageEntranceAnimator(child: TypingIndicator());
                }

                final messageIndex = _isBotThinking ? index - 1 : index;
                if (messageIndex >= _messages.length) return const SizedBox.shrink();

                final actualIndex = _messages.length - 1 - messageIndex;
                if (actualIndex < 0) return const SizedBox.shrink();

                final message = _messages[actualIndex];
                return MessageEntranceAnimator(
                  key: ValueKey(message.id),
                  child: MessageBubble(
                    message: message,
                    onCorrect: (newText) {},
                    isUserPremium: false,
                    nativeLanguage: widget.nativeLanguage,
                    isPremium: false,
                    onQuizAnswer: (idx) {},
                    onRequestMoreQuiz: (topicPath, topicTitle) {},
                    isLast: actualIndex == _messages.length - 1,
                  ),
                );
              },
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
              nativeLanguage: widget.nativeLanguage,
              enableTranslation: widget.nativeLanguage != widget.targetLanguage,
              enableSpeech: true,
              enableEmojis: true,
              hintText: 'Message',
              characterLimit: 1000,
              enabled: _botReady,
              isPremium: false,
              useAiTranslation: true,
              aiTargetLanguage: widget.targetLanguage,
              // Senaryo ekranı için: ataç özelliklerini devre dışı bırak
              hideAttachButton: true,
            ),
          ),
        ],
      ),
    );
  }
}
