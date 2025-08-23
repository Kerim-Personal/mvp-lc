// lib/screens/linguabot_chat_screen.dart
// Bu bir sohbet ekranı değil, bir dil evreni simülatörüdür.
// v2.4.0: Yıldız animasyonları sakinleştirildi ve doğallaştırıldı. Ortam artık otantik ve dikkat dağıtıcı değil.

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lingua_chat/services/linguabot_service.dart';
import 'package:lingua_chat/models/grammar_analysis.dart';

// --- DEVRİM 1: VERİ MODELLERİNİN YENİDEN DOĞUŞU ---

enum MessageSender { user, bot }

class MessageUnit {
  final String id;
  String text;
  final MessageSender sender;
  final DateTime timestamp;
  GrammarAnalysis? grammarAnalysis; // artık mutable ve nullable
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

// --- ANA EKRAN: SİMÜLATÖRÜN KALBİ ---

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

    // Premium ise gramer analizi isteğini şimdiden başlat (eşzamanlı çalışsın)
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
      grammarAnalysis: null, // premium değilse null kalacak, premiumsa sonra doldurulacak
      vocabularyRichness: _computeVocabRichness(text),
    );

    setState(() {
      _messages.add(userMessage);
      _isBotThinking = true;
    });
    _scrollToBottom();

    // Analiz hazır olduğunda mesajı güncelle
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
      grammarAnalysis: null, // Bot mesajları analiz edilmez (gereksinim: sadece kullanıcının kendi mesajı)
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

  TextSpan _buildAnalyzedSpan(String text, GrammarAnalysis ga) {
    final List<InlineSpan> spans = [];
    // Tokenları (kelime/punkt + whitespace) koru
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
        spans.add(TextSpan(text: token, style: const TextStyle(decoration: TextDecoration.underline, decorationColor: Colors.redAccent, color: Colors.redAccent)));
      } else if (cleaned.isNotEmpty && errorTokens.contains(cleaned)) {
        spans.add(TextSpan(text: token, style: const TextStyle(color: Colors.orangeAccent, decoration: TextDecoration.underline)));
      } else {
        spans.add(TextSpan(text: token, style: const TextStyle(color: Colors.white)));
      }
    }
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    bool isUser = message.sender == MessageSender.user;
    final ga = message.grammarAnalysis;
    Widget textWidget;
    if (isUser && ga != null) {
      textWidget = RichText(text: _buildAnalyzedSpan(message.text, ga));
    } else {
      textWidget = Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5));
    }
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          showDialog(
            context: context,
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
            border: Border.all(color: isUser ? Colors.tealAccent.withAlpha(128) : Colors.purpleAccent.withAlpha(128)),
            gradient: LinearGradient(
              colors: isUser
                  ? [Colors.teal.withAlpha(51), Colors.cyan.withAlpha(26)]
                  : [Colors.purple.withAlpha(51), Colors.deepPurple.withAlpha(26)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
                        child: Text('Skor ${(ga.grammarScore*100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w600)),
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
                )
            ],
          ),
        ),
      ),
    );
  }
}

class MessageInsightDialog extends StatelessWidget {
  final MessageUnit message;
  final Function(String) onCorrect;

  const MessageInsightDialog({super.key, required this.message, required this.onCorrect});

  String _scoreLabel(double v){
    if(v>=0.9) return 'Neredeyse kusursuz';
    if(v>=0.75) return 'Çok iyi';
    if(v>=0.6) return 'İyi';
    if(v>=0.45) return 'Gelişiyor';
    if(v>=0.3) return 'Temel';
    return 'Başlangıç';
  }
  String _cefrExplain(String c){
    switch(c){
      case 'A1': return 'Temel başlangıç';
      case 'A2': return 'Genişleyen temel';
      case 'B1': return 'Orta seviye';
      case 'B2': return 'Üst orta';
      case 'C1': return 'İleri';
      case 'C2': return 'Yetkin';
      default: return c; }
  }
  String _formalityToString(Formality f){
    switch(f){
      case Formality.informal: return 'Gündelik';
      case Formality.neutral: return 'Nötr';
      case Formality.formal: return 'Resmi';
    }
  }
  String _sentimentLabel(double s){
    if(s>0.35) return 'olumlu';
    if(s<-0.35) return 'olumsuz';
    return 'nötr';
  }
  // Eklenen fonksiyon: Zaman (tense) açıklaması
  String _tenseExplain(String t){
    final l = t.toLowerCase();
    // En uzun / bileşik yapıları önce kontrol et
    if(l.contains('present perfect continuous')) return 'Şimdiki zamana kadar süregelen geçmişten beri devam eden';
    if(l.contains('past perfect continuous')) return 'Geçmişte bir ana kadar süregelen uzun eylem';
    if(l.contains('future perfect continuous')) return 'Gelecekte belirli bir ana kadar devam ediyor olacak';
    if(l.contains('present perfect')) return 'Geçmişte başladı; sonucu/etkisi şimdi';
    if(l.contains('past perfect')) return 'Geçmişte başka bir eylemden önce tamamlandı';
    if(l.contains('future perfect')) return 'Gelecekte belirli bir ana kadar tamamlanmış olacak';
    if(l.contains('present continuous') || l.contains('present progressive')) return 'Şu anda devam eden';
    if(l.contains('past continuous') || l.contains('past progressive')) return 'Geçmişte belirli bir anda devam eden';
    if(l.contains('future continuous') || l.contains('future progressive')) return 'Gelecekte belirli bir anda devam ediyor olacak';
    if(l.contains('simple present') || l== 'present simple' || (l.contains('present') && l.contains('simple'))) return 'Genel gerçek / alışkanlık';
    if(l.contains('simple past') || l== 'past simple' || (l.contains('past') && l.contains('simple'))) return 'Geçmişte tamamlandı';
    if(l.contains('simple future') || l== 'future simple' || (l.contains('future') && l.contains('simple'))) return 'Gelecekte gerçekleşecek';
    if(l.contains('infinitive')) return 'Mastar form';
    if(l.contains('imperative')) return 'Emir kipi';
    if(l.contains('conditional')) return 'Koşula bağlı yapı';
    // Varsayılan
    return t; // Bilinmeyen ise olduğu gibi döndür
  }
  String _summaryText(GrammarAnalysis a){
    final percent = (a.grammarScore*100).round();
    final errorCount = a.errors.length;
    final errorPart = errorCount==0? 'Hata yok.' : errorCount==1? '1 hata.' : '$errorCount hata.';
    final complexityPct = (a.complexity*100).round();
    final tenseShort = _tenseExplain(a.tense);
    final form = _formalityToString(a.formality);
    final cefrExp = _cefrExplain(a.cefr);
    final sentiment = _sentimentLabel(a.sentiment);
    // İlk cümle: Seviye + doğruluk + hata
    // İkinci cümle: Zaman, formallik, yapı, duygu
    return 'Seviye ${a.cefr} (${cefrExp}), gramer doğruluğu %$percent. $errorPart\nZaman: $tenseShort; form: $form; yapı karmaşıklığı %$complexityPct; duygu: $sentiment.';
  }
  Widget _statLine({required IconData icon, required Color color, required String title, required String value, String? subtitle}){
    return Container(
      margin: const EdgeInsets.symmetric(vertical:4),
      padding: const EdgeInsets.symmetric(horizontal:14, vertical:10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(120)),
        gradient: LinearGradient(
          colors: [color.withAlpha(30), Colors.transparent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size:18, color: color),
              const SizedBox(width:10),
              Expanded(child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize:13))),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize:13)),
            ],
          ),
          if(subtitle!=null) Padding(
            padding: const EdgeInsets.only(top:4, left:28),
            child: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize:11, height:1.2)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analysis = message.grammarAnalysis;
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    // errorLabel kaldırıldı (kullanılmıyor)
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
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight, minWidth: 280),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                    // ÖZET BLOKU
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((255*0.05).round()),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.cyan.withAlpha((255*0.3).round())),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Genel Değerlendirme', style: TextStyle(color: Colors.cyanAccent.shade100, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height:6),
                          Text(
                            _summaryText(analysis),
                            style: const TextStyle(color: Colors.white70, height:1.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height:14),
                    // METRİK SATIRLARI
                    StatsSection(
                      analysis: analysis,
                      vocabRichness: message.vocabularyRichness,
                      scoreLabel: _scoreLabel,
                      cefrExplain: _cefrExplain,
                      tenseExplain: _tenseExplain,
                      formalityToString: _formalityToString,
                      statLineBuilder: ({required icon, required color, required title, required value, subtitle}) => _statLine(icon: icon, color: color, title: title, value: value, subtitle: subtitle),
                    ),
                    const SizedBox(height:18),
                    // TEMEL METRİK GÖSTERGELERİ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: MetricGauge(label: "Kelime Çeşitliliği", value: message.vocabularyRichness, color: Colors.amber)),
                        const SizedBox(width:12),
                        Expanded(child: MetricGauge(label: "Duygu Tonu", value: (analysis.sentiment + 1) / 2, color: Colors.green)),
                        const SizedBox(width:12),
                        Expanded(child: MetricGauge(label: "Yapı Karmaşıklığı", value: analysis.complexity, color: Colors.purpleAccent)),
                      ],
                    ),
                    const SizedBox(height:16),
                    if (analysis.corrections.isNotEmpty)
                      _buildCorrectionWidget(context, analysis.corrections.entries.first),
                    if (analysis.errors.isNotEmpty)
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.white24),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          iconColor: Colors.orangeAccent,
                          collapsedIconColor: Colors.orangeAccent,
                          title: const Text("Hata Detayları", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                          children: analysis.errors.take(6).map((e) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                children: [
                                  TextSpan(text: "${e.type}: ", style: const TextStyle(color: Colors.cyanAccent)),
                                  TextSpan(text: e.original, style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.redAccent)),
                                  const TextSpan(text: " → "),
                                  TextSpan(text: e.correction, style: const TextStyle(color: Colors.greenAccent)),
                                  TextSpan(text: " (${e.severity})\n", style: const TextStyle(fontSize: 10, color: Colors.white38)),
                                  TextSpan(text: e.explanation, style: const TextStyle(fontSize: 10, color: Colors.white54)),
                                ],
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                    if (analysis.suggestions.isNotEmpty)
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.white24),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          iconColor: Colors.lightBlueAccent,
                          collapsedIconColor: Colors.lightBlueAccent,
                          title: const Text("Öneriler", style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold)),
                          children: analysis.suggestions.take(6).map((s) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Text("•", style: TextStyle(color: Colors.lightBlueAccent)),
                            title: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          )).toList(),
                        ),
                      ),
                  ],

                  const SizedBox(height: 10),
                  Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat"))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildCorrectionWidget(BuildContext context, MapEntry<String, String> correction) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
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
              onPressed: () {
                final wrong = correction.key.trim();
                if (wrong.isEmpty) return;
                final pattern = RegExp(r'\\b' + RegExp.escape(wrong) + r'\\b');
                final newText = message.text.replaceAll(pattern, correction.value);
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

class StatsSection extends StatefulWidget {
  final GrammarAnalysis analysis;
  final double vocabRichness;
  final String Function(double) scoreLabel;
  final String Function(String) cefrExplain;
  final String Function(String) tenseExplain;
  final String Function(Formality) formalityToString;
  final Widget Function({required IconData icon, required Color color, required String title, required String value, String? subtitle}) statLineBuilder;
  const StatsSection({super.key, required this.analysis, required this.vocabRichness, required this.scoreLabel, required this.cefrExplain, required this.tenseExplain, required this.formalityToString, required this.statLineBuilder});
  @override
  State<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<StatsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.analysis;
    return Container(
      margin: const EdgeInsets.only(top:4),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(()=> _expanded = !_expanded),
            child: Row(
              children: [
                Icon(_expanded? Icons.expand_less : Icons.expand_more, color: Colors.cyanAccent, size:20),
                const SizedBox(width:6),
                Text(_expanded? 'Metrikleri Gizle' : 'Metrikleri Göster', style: const TextStyle(color: Colors.cyanAccent, fontSize:12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const SizedBox(height:6),
                widget.statLineBuilder(icon: Icons.score, color: Colors.cyanAccent, title:'Gramer Skoru', value:'${(a.grammarScore*100).toStringAsFixed(0)}%', subtitle: widget.scoreLabel(a.grammarScore)),
                widget.statLineBuilder(icon: Icons.school, color: Colors.amber, title:'CEFR', value: a.cefr, subtitle: widget.cefrExplain(a.cefr)),
                widget.statLineBuilder(icon: Icons.access_time, color: Colors.lightBlueAccent, title:'Zaman', value: a.tense, subtitle: widget.tenseExplain(a.tense)),
                widget.statLineBuilder(icon: Icons.theater_comedy, color: Colors.purpleAccent, title:'Formallik', value: widget.formalityToString(a.formality)),
                widget.statLineBuilder(icon: Icons.article_outlined, color: Colors.greenAccent, title:'Kelime Türleri', value:'${a.nounCount}/${a.verbCount}/${a.adjectiveCount}', subtitle: 'İsim / Fiil / Sıfat'),
              ],
            ),
            crossFadeState: _expanded? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds:300),
          )
        ],
      ),
    );
  }
}
