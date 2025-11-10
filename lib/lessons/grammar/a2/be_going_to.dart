// lib/lessons/grammar/a2/be_going_to.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vocachat/services/translation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Eklendi

// --- MAIN LESSON SCREEN ---

class BeGoingToLessonScreen extends StatefulWidget {
  const BeGoingToLessonScreen({super.key});

  @override
  State<BeGoingToLessonScreen> createState() => _BeGoingToLessonScreenState();
}

class _BeGoingToLessonScreenState extends State<BeGoingToLessonScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late FlutterTts flutterTts;

  String? _nativeLangCode; // native language code cache
  // Simple in-memory translation cache: key => "langCode::source"
  final Map<String, String> _translationCache = {};

  // Get the user's native language code from Firestore and cache it
  Future<String> _getTargetLangCode() async {
    if (_nativeLangCode != null) return _nativeLangCode!;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return _nativeLangCode = 'en';
      final snap =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final code = (snap.data()?['nativeLanguage'] as String?)?.trim();
      if (code == null || code.isEmpty) return _nativeLangCode = 'en';
      _nativeLangCode = code;
      return _nativeLangCode!;
    } catch (_) {
      return _nativeLangCode = 'en';
    }
  }

  String _stripMarkdown(String text) {
    // TTS ve Çeviri için Markdown'ı temizler
    return text.replaceAll(RegExp(r'(\*\*|__|(\*)|_)'), '');
  }

  Future<String> _translateToNative(String text) async {
    final target = await _getTargetLangCode();
    // Markdown'ı temizleyerek çeviri yap ve cache'le
    final cleanText = _stripMarkdown(text);
    final cacheKey = '$target::$cleanText';

    // Return from cache if available
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }
    try {
      await TranslationService.instance.ensureReady(target);
    } catch (_) {
      // ignore ensureReady failures, attempt translation anyway
    }
    try {
      final translated =
      await TranslationService.instance.translateFromEnglish(cleanText, target);
      _translationCache[cacheKey] = translated;
      return translated;
    } catch (_) {
      // Fallback to original text if translation fails
      return cleanText;
    }
  }

  Future<void> _showTranslateSheet(String source) async {
    if (!mounted) return;
    // Create the future ONCE; prevents re-triggering translation on rebuilds/gestures
    final translationFuture = _translateToNative(source);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.translate, color: Colors.teal),
                      SizedBox(width: 8),
                      Text('Translation',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Original',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  // Orijinal metni Markdown'dan temizlenmiş göster
                  Text(_stripMarkdown(source),
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  const Text('Translation',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  FutureBuilder<String>(
                    future: translationFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: const [
                              SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                  CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 8),
                              Text('Translating...'),
                            ],
                          ),
                        );
                      }
                      final translated = snapshot.data ?? _stripMarkdown(source);
                      return Text(translated,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500));
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  void _initializeTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage("en-US");
    flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    // Konuşma için Markdown'ı temizle
    final cleanText = _stripMarkdown(text);
    await flutterTts.speak(cleanText);
  }

  @override
  void dispose() {
    _controller.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            stretch: true,
            pinned: true,
            backgroundColor: Colors.blue.shade700,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text('Be Going To',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 22)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade500,
                      Colors.indigo.shade600,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_outlined,
                          size: 70, color: Colors.white24),
                      const SizedBox(height: 8),
                      Text(
                        'Future Plans & Predictions',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _SpeechHintBox(),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.1, 0.7),
                  child: _LessonBlock(
                    icon: Icons.event_outlined,
                    title: '"Be Going To": Future Plans and Predictions',
                    // Veri Markdown formatına güncellendi
                    content:
                    "**'Be going to'** expresses future plans that are already decided, or predictions based on current evidence. It's formed with **'be' + 'going to' + infinitive**. Great for talking about intentions and expectations!",
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.2, 0.8),
                  child: _ExampleCard(
                    title: 'When to Use "Be Going To"',
                    // Veri Markdown formatına güncellendi
                    examples: const [
                      Example(
                          icon: Icons.schedule,
                          category: '**Future Plans (decided):**',
                          sentence: '*I **am going to study** tonight.*'),
                      Example(
                          icon: Icons.visibility,
                          category: '**Predictions (evidence):**',
                          sentence: '*It **is going to rain**. (dark clouds)*'),
                      Example(
                          icon: Icons.warning,
                          category: '**Warnings:**',
                          sentence: '*You **are going to be** late!*'),
                    ],
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.3, 0.9),
                  child: _SimplifiedClickableCard(
                    title: 'Positive Sentences',
                    // Veri Markdown formatına güncellendi
                    headers: const ['**Subject**', '**Form**', '**Example Sentence**'],
                    rows: const [
                      [
                        'I',
                        '**am going to** + verb',
                        '*I **am going to learn** Spanish.*'
                      ],
                      [
                        'He / She / It',
                        '**is going to** + verb',
                        '*She **is going to buy** a car.*'
                      ],
                      [
                        'You / We / They',
                        '**are going to** + verb',
                        '*We **are going to travel** next year.*'
                      ],
                    ],
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.4, 1.0),
                  child: _SimplifiedClickableCard(
                    title: 'Negative Sentences: Add "not"',
                    // Veri Markdown formatına güncellendi
                    headers: const ['**Full Form**', '**Contraction**'],
                    rows: const [
                      [
                        '*I **am not** going to study.*',
                        '*I**\'m not** going to study.*'
                      ],
                      [
                        '*He **is not** going to come.*',
                        '*He **isn\'t** going to come.*'
                      ],
                      [
                        '*They **are not** going to wait.*',
                        '*They **aren\'t** going to wait.*'
                      ],
                    ],
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.5, 1.0),
                  child: _SimplifiedClickableCard(
                    title: 'Question Sentences: Invert!',
                    // Veri Markdown formatına güncellendi
                    headers: const ['**Question**', '**Short Answer**'],
                    rows: const [
                      ['***Am I** going to win?*', '*Yes, you are.*'],
                      ['***Is she** going to help?*', '*Yes, she is.*'],
                      ['***Are they** going to leave?*', '*No, they aren\'t.*'],
                    ],
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.6, 1.0),
                  child: _TipCard(
                    title: 'Pro Tips & Tricks',
                    // Veri Markdown formatına güncellendi
                    tips: const [
                      '**"Gonna"**: In informal speech, "going to" is often pronounced (and written) as "**gonna**". *I\'m **gonna** call him.*',
                      '**Plans vs Will:** Use **"going to"** for plans you made *before* speaking. Use **"will"** for spontaneous decisions made *at the moment* of speaking.',
                      '**Evidence:** "Going to" is strong for predictions. *Look at those clouds. It **is going to** rain.*',
                      '**Time expressions:** Use with words like *tomorrow, next week, this evening, etc.*',
                    ],
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// --- HELPER WIDGETS ---

class _SpeechHintBox extends StatelessWidget {
  const _SpeechHintBox();

  @override
  Widget build(BuildContext context) {
    // Renkler bu dersin temasına (pembe/kırmızı) uyacak şekilde düzeltildi
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.volume_up, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tap any text to hear it spoken. Long press for translation.',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedLessonBlock extends StatelessWidget {
  final AnimationController controller;
  final Interval interval;
  final Widget child;

  const _AnimatedLessonBlock({
    required this.controller,
    required this.interval,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: interval,
      ),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.2),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class Example {
  final IconData icon;
  final String category;
  final String sentence;

  const Example({
    required this.icon,
    required this.category,
    required this.sentence,
  });
}

class _LessonBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Function(String) onSpeak;
  final Function(String) onTranslate;

  const _LessonBlock({
    required this.icon,
    required this.title,
    required this.content,
    required this.onSpeak,
    required this.onTranslate,
  });

  // Stil metodu eklendi
  MarkdownStyleSheet _getMdStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseText = TextStyle(
      fontSize: 16,
      height: 1.5,
      color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
    );
    final strongText = TextStyle(
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : Colors.black,
      fontSize: 16,
    );

    return MarkdownStyleSheet(
      p: baseText,
      strong: strongText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : null,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => onSpeak(title),
                    onLongPress: () => onTranslate(title),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSpeak(content),
              onLongPress: () => onTranslate(content),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                // Text widget'ı MarkdownBody ile değiştirildi
                child: MarkdownBody(
                  data: content,
                  selectable: false,
                  styleSheet: _getMdStyle(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final String title;
  final List<Example> examples;
  final Function(String) onSpeak;
  final Function(String) onTranslate;

  const _ExampleCard({
    required this.title,
    required this.examples,
    required this.onSpeak,
    required this.onTranslate,
  });

  // Stil metotları eklendi
  MarkdownStyleSheet _getCategoryStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
      ),
      strong: TextStyle(
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
      ),
    );
  }

  MarkdownStyleSheet _getSentenceStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 16,
        height: 1.4,
        color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
      ),
      em: const TextStyle(fontStyle: FontStyle.italic), // '*' için stil
      strong: TextStyle( // '**' için stil
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : null,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => onSpeak(title),
                    onLongPress: () => onTranslate(title),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...examples.map((example) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSpeak('${example.category} ${example.sentence}'),
                onLongPress: () => onTranslate('${example.category} ${example.sentence}'),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(example.icon,
                        color: Colors.blue.shade600, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text, MarkdownBody olarak değiştirildi
                          MarkdownBody(
                            data: example.category,
                            selectable: false,
                            styleSheet: _getCategoryStyle(context),
                          ),
                          const SizedBox(height: 4),
                          // InkWell içindeki Text, MarkdownBody olarak değiştirildi
                          MarkdownBody(
                            data: example.sentence,
                            selectable: false,
                            styleSheet: _getSentenceStyle(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _SimplifiedClickableCard extends StatelessWidget {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  final Function(String) onSpeak;
  final Function(String) onTranslate;

  const _SimplifiedClickableCard({
    required this.title,
    required this.headers,
    required this.rows,
    required this.onSpeak,
    required this.onTranslate,
  });

  // Stil metotları eklendi
  MarkdownStyleSheet _getHeaderStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 14,
        color: onSurface(context),
      ),
      strong: TextStyle(
        fontWeight: FontWeight.bold,
        color: onSurface(context),
      ),
    );
  }

  MarkdownStyleSheet _getCellStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
      ),
      em: const TextStyle(fontStyle: FontStyle.italic),
      strong: TextStyle(
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  // Helper to get onSurface color
  Color onSurface(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : null,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.table_chart_outlined,
                    color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => onSpeak(title),
                    onLongPress: () => onTranslate(title),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: onSurface(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 1,
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  ),
                  children: headers
                      .map((header) => Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => onSpeak(header),
                      onLongPress: () => onTranslate(header),
                      // Text, MarkdownBody olarak değiştirildi
                      child: MarkdownBody(
                        data: header,
                        selectable: false,
                        styleSheet: _getHeaderStyle(context),
                      ),
                    ),
                  ))
                      .toList(),
                ),
                ...rows.map((row) => TableRow(
                  children: row
                      .map((cell) => Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => onSpeak(cell),
                      onLongPress: () => onTranslate(cell),
                      // Text, MarkdownBody olarak değiştirildi
                      child: MarkdownBody(
                        data: cell,
                        selectable: false,
                        styleSheet: _getCellStyle(context),
                      ),
                    ),
                  ))
                      .toList(),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final List<String> tips;
  final Function(String) onSpeak;
  final Function(String) onTranslate;

  const _TipCard({
    required this.title,
    required this.tips,
    required this.onSpeak,
    required this.onTranslate,
  });

  // Stil metodu eklendi
  MarkdownStyleSheet _getMdStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseText = TextStyle(
      fontSize: 16,
      height: 1.5,
      color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
    );
    final strongText = TextStyle(
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : Colors.black,
      fontSize: 16,
    );

    return MarkdownStyleSheet(
      p: baseText,
      strong: strongText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : null,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates_outlined,
                    color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => onSpeak(title),
                    onLongPress: () => onTranslate(title),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => onSpeak(tip),
                      onLongPress: () => onTranslate(tip),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        // Text, MarkdownBody olarak değiştirildi
                        child: MarkdownBody(
                          data: tip,
                          selectable: false,
                          styleSheet: _getMdStyle(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}