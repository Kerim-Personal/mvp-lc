// lib/screens/linguabot_chat_screen.dart
// Bu bir sohbet ekranı değil, bir dil evreni simülatörüdür.
// v2.4.0: Yıldız animasyonları sakinleştirildi ve doğallaştırıldı. Ortam artık otantik ve dikkat dağıtıcı değil.

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lingua_chat/services/linguabot_service.dart';

// --- DEVRİM 1: VERİ MODELLERİNİN YENİDEN DOĞUŞU ---

enum MessageSender { user, bot }
enum Formality { informal, neutral, formal }

class MessageUnit {
  final String id;
  String text;
  final MessageSender sender;
  final DateTime timestamp;
  final GrammarAnalysis? grammarAnalysis;
  final double vocabularyRichness;
  final Duration? botResponseTime;

  MessageUnit({
    required this.text,
    required this.sender,
    this.grammarAnalysis,
    this.vocabularyRichness = 0.5,
    this.botResponseTime,
  })  : id = UniqueKey().toString(),
        timestamp = DateTime.now();
}

class GrammarAnalysis {
  final String tense;
  final int nounCount;
  final int verbCount;
  final int adjectiveCount;
  final double sentiment;
  final double complexity;
  final Formality formality;
  final Map<String, String> corrections;

  GrammarAnalysis({
    this.tense = "Present Simple",
    this.nounCount = 0,
    this.verbCount = 0,
    this.adjectiveCount = 0,
    this.sentiment = 0.0,
    this.complexity = 0.0,
    this.formality = Formality.neutral,
    this.corrections = const {},
  });
}

// --- ANA EKRAN: SİMÜLATÖRÜN KALBİ ---

class LinguaBotChatScreen extends StatefulWidget {
  const LinguaBotChatScreen({super.key});

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
      text: "Dil evrenine yeniden hoş geldin. Sınırları zorlamaya hazır mısın?",
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
    final userMessage = MessageUnit(
        text: text,
        sender: MessageSender.user,
        grammarAnalysis: GrammarAnalysis(
            tense: "Past Simple",
            nounCount: 2,
            verbCount: 1,
            corrections: text.toLowerCase().contains("i goed") ? {"goed": "went"} : {},
            sentiment: 0.2,
            complexity: 0.4,
            formality: Formality.informal),
        vocabularyRichness: 0.6);

    setState(() {
      _messages.add(userMessage);
      _isBotThinking = true;
    });

    _scrollToBottom();
    final botStartTime = DateTime.now();

    await Future.delayed(Duration(milliseconds: 1500 + Random().nextInt(1500)));
    final botResponseText = await _botService.sendMessage(text);
    final botResponseTime = DateTime.now().difference(botStartTime);

    final botMessage = MessageUnit(
      text: botResponseText,
      sender: MessageSender.bot,
      botResponseTime: botResponseTime,
      grammarAnalysis: GrammarAnalysis(
          tense: "Future Simple",
          verbCount: 2,
          nounCount: 3,
          adjectiveCount: 1,
          sentiment: -0.1,
          complexity: 0.6,
          formality: Formality.formal),
      vocabularyRichness: 0.7,
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
            // İYİLEŞTİRME: Efektin daha belirgin olması için hafif bir overlay eklendi.
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

// --- DEVRİMSEL WIDGET'LAR ---

class HolographicHeader extends StatefulWidget {
  final bool isBotThinking;
  const HolographicHeader({super.key, required this.isBotThinking});

  @override
  State<HolographicHeader> createState() => _HolographicHeaderState();
}

class _HolographicHeaderState extends State<HolographicHeader> with TickerProviderStateMixin {
  late AnimationController _thinkingController;

  @override
  void initState() {
    super.initState();
    _thinkingController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void didUpdateWidget(covariant HolographicHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBotThinking) {
      _thinkingController.repeat();
    } else {
      _thinkingController.stop();
    }
  }

  @override
  void dispose() {
    _thinkingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white70)),
          AnimatedBuilder(
            animation: _thinkingController,
            builder: (context, child) {
              final angle = widget.isBotThinking ? _thinkingController.value * 2 * pi : 0.0;
              final color = widget.isBotThinking ? Colors.cyanAccent : Colors.white;
              return Transform.rotate(
                angle: angle,
                child: Icon(
                  widget.isBotThinking ? Icons.psychology_alt_sharp : Icons.smart_toy_outlined,
                  color: color,
                  size: 30,
                  shadows: [Shadow(color: color, blurRadius: 15)],
                ),
              );
            },
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, color: Colors.white70)),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final MessageUnit message;
  final Function(String) onCorrect;
  const MessageBubble({super.key, required this.message, required this.onCorrect});

  @override
  Widget build(BuildContext context) {
    bool isUser = message.sender == MessageSender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          showDialog(
            context: context,
            // İYİLEŞTİRME: Diyalog arkaplanı daha estetik hale getirildi.
            barrierColor: Colors.black.withAlpha(128),
            builder: (_) => MessageInsightDialog(
              message: message,
              onCorrect: onCorrect,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            // İYİLEŞTİRME: Kenarlık ve arkaplan opaklıkları ayarlandı.
            border: Border.all(color: isUser ? Colors.tealAccent.withAlpha(128) : Colors.purpleAccent.withAlpha(128)),
            gradient: LinearGradient(
              colors: isUser
                  ? [Colors.teal.withAlpha(51), Colors.cyan.withAlpha(26)]
                  : [Colors.purple.withAlpha(51), Colors.deepPurple.withAlpha(26)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
        ),
      ),
    );
  }
}

class MessageInsightDialog extends StatelessWidget {
  final MessageUnit message;
  final Function(String) onCorrect;

  const MessageInsightDialog({super.key, required this.message, required this.onCorrect});

  String _formalityToString(Formality f) {
    switch (f) {
      case Formality.informal: return "Samimi";
      case Formality.neutral: return "Nötr";
      case Formality.formal: return "Resmi";
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = message.grammarAnalysis;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        // İYİLEŞTİRME: Diyalog arkaplanı ve kenarlığı estetik olarak güncellendi.
        backgroundColor: Colors.black.withAlpha(191),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.cyan.withAlpha(128))),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.science_outlined, color: Colors.cyanAccent),
                  SizedBox(width: 10),
                  Text("Mesaj DNA'sı", style: TextStyle(color: Colors.cyanAccent, fontSize: 22)),
                ],
              ),
              const SizedBox(height: 10),
              Text('"${message.text}"', style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic)),
              const Divider(color: Colors.cyan, height: 20),

              if (analysis != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    MetricGauge(label: "Zenginlik", value: message.vocabularyRichness, color: Colors.amber),
                    MetricGauge(label: "Duygu", value: (analysis.sentiment + 1) / 2, color: Colors.green),
                    MetricGauge(label: "Karmaşıklık", value: analysis.complexity, color: Colors.purpleAccent),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.access_time, "Zaman", analysis.tense),
                _buildInfoRow(Icons.theater_comedy, "Formallik", _formalityToString(analysis.formality)),
                if (analysis.corrections.isNotEmpty)
                  _buildCorrectionWidget(context, analysis.corrections.entries.first),
              ],

              const SizedBox(height: 10),
              Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat"))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(color: Colors.white70)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildCorrectionWidget(BuildContext context, MapEntry<String, String> correction) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // İYİLEŞTİRME: Düzeltme kutusunun opaklığı ayarlandı.
          color: Colors.orange.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orangeAccent.withAlpha(128))
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(child: RichText(text: TextSpan(
              style: const TextStyle(color: Colors.white, fontSize: 15),
              children: [
                TextSpan(text: "${correction.key} ", style: const TextStyle(decoration: TextDecoration.lineThrough)),
                const TextSpan(text: " yerine "),
                TextSpan(text: correction.value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent))
              ]
          ))),
          IconButton(
            icon: const Icon(Icons.task_alt, color: Colors.greenAccent),
            onPressed: (){
              final newText = message.text.replaceAll(correction.key, correction.value);
              onCorrect(newText);
              Navigator.pop(context);
            },
            tooltip: "Uygula",
          )
        ],
      ),
    );
  }
}

class MetricGauge extends StatefulWidget {
  final String label;
  final double value;
  final Color color;
  const MetricGauge({super.key, required this.label, required this.value, required this.color});

  @override
  State<MetricGauge> createState() => _MetricGaugeState();
}

class _MetricGaugeState extends State<MetricGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _animation = Tween<double>(begin: 0, end: widget.value).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: _animation.value,
                    strokeWidth: 5,
                    color: widget.color,
                    // İYİLEŞTİRME: Arkaplan renginin opaklığı ayarlandı.
                    backgroundColor: widget.color.withAlpha(51),
                  ),
                  Center(child: Text("${(_animation.value * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        );
      },
    );
  }
}

class IntelligentComposer extends StatefulWidget {
  final Function(String) onSend;
  final bool isThinking;
  const IntelligentComposer({super.key, required this.onSend, required this.isThinking});

  @override
  State<IntelligentComposer> createState() => _IntelligentComposerState();
}

class _IntelligentComposerState extends State<IntelligentComposer> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // İYİLEŞTİRME: Yazma alanının opaklığı ayarlandı.
          color: Colors.black.withAlpha(77),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.purpleAccent.withAlpha(128))
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  hintText: "Mesajını buraya yaz...",
                  // İYİLEŞTİRME: İpucu metninin opaklığı ayarlandı.
                  hintStyle: TextStyle(color: Colors.white.withAlpha(128)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10)
              ),
              onSubmitted: widget.isThinking ? null : (value) => _send(),
            ),
          ),
          IconButton(
            icon: Icon(widget.isThinking ? Icons.hourglass_empty : Icons.send, color: Colors.purpleAccent),
            onPressed: widget.isThinking ? null : _send,
          )
        ],
      ),
    );
  }

  void _send() {
    widget.onSend(_controller.text);
    _controller.clear();
  }
}

class MessageEntranceAnimator extends StatefulWidget {
  final Widget child;
  const MessageEntranceAnimator({super.key, required this.child});

  @override
  State<MessageEntranceAnimator> createState() => _MessageEntranceAnimatorState();
}

class _MessageEntranceAnimatorState extends State<MessageEntranceAnimator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

// --- KOZMİK ARKA PLAN (NİHAİ SÜRÜM) ---

class CelestialBackground extends StatefulWidget {
  final Animation<double> controller;
  const CelestialBackground({super.key, required this.controller});

  @override
  State<CelestialBackground> createState() => _CelestialBackgroundState();
}

class _CelestialBackgroundState extends State<CelestialBackground> {
  List<Star> stars = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.size != null) {
        _createStars(context.size!);
      }
    });
  }

  void _createStars(Size size) {
    final random = Random();
    if (mounted) {
      setState(() {
        stars = List.generate(300, (index) {
          return Star(
            position: Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
            radius: random.nextDouble() * 1.2 + 0.4,
            baseOpacity: random.nextDouble() * 0.4 + 0.1,
            twinkleSpeed: random.nextDouble() * 0.4 + 0.1,
            twinkleOffset: random.nextDouble() * 2 * pi,
          );
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        if (stars.isEmpty && MediaQuery.of(context).size.width > 0) {
          _createStars(MediaQuery.of(context).size);
        }
        return CustomPaint(
          size: Size.infinite,
          painter: CelestialPainter(widget.controller.value, stars),
        );
      },
    );
  }
}

class Star {
  final Offset position;
  final double radius;
  final double baseOpacity;
  final double twinkleSpeed;
  final double twinkleOffset;
  Star({required this.position, required this.radius, required this.baseOpacity, required this.twinkleSpeed, required this.twinkleOffset});
}

class CelestialPainter extends CustomPainter {
  final double time;
  final List<Star> stars;
  final Random _random = Random();
  CelestialPainter(this.time, this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    final spacePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.8, -0.6),
        radius: 1.5,
        colors: [Color(0xFF1a0a2a), Color(0xFF0b0213)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), spacePaint);

    final starPaint = Paint();
    for (var star in stars) {
      final sineValue = sin((time * 2 * pi * star.twinkleSpeed) + star.twinkleOffset);
      double currentOpacity = star.baseOpacity + (sineValue + 1) / 2 * 0.3;
      double currentRadius = star.radius;

      if (_random.nextDouble() < 0.001) {
        currentOpacity += 0.5;
        currentRadius += 0.5;
      }

      // İYİLEŞTİRME: withAlpha kullanarak opaklık ayarlandı.
      starPaint.color = Colors.white.withAlpha((currentOpacity.clamp(0.0, 1.0) * 255).round());
      canvas.drawCircle(star.position, currentRadius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CelestialPainter oldDelegate) => true;
}