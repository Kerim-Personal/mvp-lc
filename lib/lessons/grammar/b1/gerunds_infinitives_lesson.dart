// lib/lessons/grammar/b1/gerunds_infinitives_lesson.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vocachat/services/translation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Eklendi

// --- MAIN LESSON SCREEN ---

class GerundsInfinitivesLessonScreen extends StatefulWidget {
  const GerundsInfinitivesLessonScreen({super.key});

  @override
  State<GerundsInfinitivesLessonScreen> createState() =>
      _GerundsInfinitivesLessonScreenState();
}

class _GerundsInfinitivesLessonScreenState
    extends State<GerundsInfinitivesLessonScreen> with TickerProviderStateMixin {
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
            backgroundColor: Colors.lightGreen.shade700,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text('Gerunds & Infinitives',
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
                      Colors.lightGreen.shade500,
                      Colors.green.shade600,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.format_list_bulleted,
                          size: 70, color: Colors.white24),
                      const SizedBox(height: 8),
                      Text(
                        'Verb Forms After Other Verbs',
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
                    icon: Icons.functions,
                    title: 'Gerunds (-ing) vs Infinitives (to + verb)',
                    // Veri Markdown formatına güncellendi
                    content:
                    "**Gerunds** are verb forms ending in **-ing** that function as nouns. **Infinitives** are **'to + base verb'**. Many verbs are followed by one or the other, and sometimes both are possible with different meanings.",
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.2, 0.8),
                  child: _ExampleCard(
                    title: 'Verbs Followed by Gerunds',
                    // Veri Markdown formatına güncellendi
                    examples: const [
                      Example(
                          icon: Icons.stop,
                          category: '**Stop + Gerund:**',
                          sentence: '*I **stopped smoking**. (quit the habit)*'),
                      Example(
                          icon: Icons.favorite,
                          category: '**Enjoy + Gerund:**',
                          sentence: '*She **enjoys reading** books.*'),
                      Example(
                          icon: Icons.thumbs_up_down,
                          category: '**Mind + Gerund:**',
                          sentence: '*Do you **mind waiting**?*'),
                    ],
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.3, 0.9),
                  child: _SimplifiedClickableCard(
                    title: 'Verbs Followed by Infinitives',
                    // Veri Markdown formatına güncellendi
                    headers: const ['**Verb**', '**Example**', '**Meaning**'],
                    rows: const [
                      ['**decide**', '*I **decided to go**.*', 'Make a choice'],
                      ['**hope**', '*She **hopes to win**.*', 'Wish for something'],
                      ['**promise**', '*He **promised to help**.*', 'Give assurance'],
                      ['**want**', '*They **want to learn**.*', 'Desire'],
                      ['**need**', '*We **need to eat**.*', 'Require'],
                    ],
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.4, 1.0),
                  child: _SimplifiedClickableCard(
                    title: 'Verbs with Both (Different Meanings)',
                    // Veri Markdown formatına güncellendi
                    headers: const ['**Verb**', '**Gerund Example**', '**Infinitive Example**'],
                    rows: const [
                      [
                        '**stop**',
                        '*I **stopped smoking**.* (quit)',
                        '*I **stopped to smoke**.* (pause)'
                      ],
                      [
                        '**remember**',
                        '*I **remember meeting** her.* (past memory)',
                        '*I **remembered to call** her.* (future task)'
                      ],
                      [
                        '**try**',
                        '*Try **pushing** it.* (experiment)',
                        '*Try **to push** it.* (attempt)'
                      ],
                      [
                        '**forget**',
                        '*I **forgot meeting** him.* (no memory)',
                        '*I **forgot to meet** him.* (task)'
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
                    title: 'Prepositions + Gerunds',
                    // Veri Markdown formatına güncellendi
                    headers: const ['**Preposition**', '**Example**', '**Common Use**'],
                    rows: const [
                      [
                        '**interested in**',
                        '*I\'m **interested in learning** Spanish.*',
                        'Hobbies/Topics'
                      ],
                      ['**good at**', '*She\'s **good at painting**.*', 'Skills'],
                      ['**afraid of**', '*He\'s **afraid of flying**.*', 'Fears'],
                      ['**tired of**', '*We\'re **tired of waiting**.*', 'Boredom'],
                      [
                        '**instead of**',
                        '***Instead of watching** TV...*',
                        'Alternatives'
                      ],
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
                      '**"Go" + Gerund:** For activities like "**go** shopping", "**go** swimming".',
                      '**"Like" + Gerund/Infinitive:** *"I **like swimming**"* (general enjoyment) vs. *"I **like to swim** in the morning"* (habit/preference).',
                      '**Verbs of Perception:** *see/hear/feel* + object + bare infinitive: *"I **saw him run**."* (watch the whole action)',
                      '**Make/Let:** Use bare infinitive (no "to"): *"My boss **made me work** late."* / *"She **let him go**."*',
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
    // Renkler bu dersin temasına (yeşil) uyacak şekilde düzeltildi
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightGreen.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.lightGreen.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.volume_up, color: Colors.lightGreen.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tap to hear pronunciation, long press for translation.',
              style: TextStyle(color: Colors.lightGreen.shade900, fontSize: 14),
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
    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: interval),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        )),
        child: child,
      ),
    );
  }
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
                Icon(icon, color: Colors.lightGreen.shade700, size: 28),
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
            InkWell(
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
            const SizedBox(height: 16),
            ...examples.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _ExampleListItem(
                  example: e, onSpeak: onSpeak, onTranslate: onTranslate),
            )),
          ],
        ),
      ),
    );
  }
}

class _ExampleListItem extends StatelessWidget {
  final Example example;
  final Function(String) onSpeak;
  final Function(String) onTranslate;

  const _ExampleListItem(
      {required this.example,
        required this.onSpeak,
        required this.onTranslate});

  // Stil metotları eklendi
  MarkdownStyleSheet _getCategoryStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 16,
        color: isDark ? Colors.white : Colors.black,
      ),
      strong: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  MarkdownStyleSheet _getSentenceStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 16,
        fontStyle: FontStyle.italic,
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
    return Material(
      color: isDark
          ? Colors.lightGreen.shade900.withOpacity(0.25)
          : Colors.lightGreen.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onSpeak('${example.category} ${example.sentence}'),
        onLongPress: () =>
            onTranslate('${example.category} ${example.sentence}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(example.icon, size: 22, color: Colors.lightGreen.shade600),
              const SizedBox(width: 12),
              // Layout, Column olarak güncellendi (diğer dosyalarla uyum için)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarkdownBody(
                      data: example.category,
                      selectable: false,
                      styleSheet: _getCategoryStyle(context),
                    ),
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
        fontWeight: FontWeight.bold,
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
            InkWell(
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
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 1,
              ),
              // Sütun genişliklerini ayarlamak için eklendi
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  ),
                  children: headers
                      .map((h) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () => onSpeak(h),
                      onLongPress: () => onTranslate(h),
                      // Text, MarkdownBody olarak değiştirildi
                      child: MarkdownBody(
                        data: h,
                        selectable: false,
                        styleSheet: _getHeaderStyle(context),
                      ),
                    ),
                  ))
                      .toList(),
                ),
                ...rows.map((row) {
                  final String textJoined = row.join('. ');
                  return TableRow(
                    children: row
                        .map((cell) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () => onSpeak(textJoined),
                        onLongPress: () => onTranslate(textJoined),
                        // Text, MarkdownBody olarak değiştirildi
                        child: MarkdownBody(
                          data: cell,
                          selectable: false,
                          styleSheet: _getCellStyle(context),
                        ),
                      ),
                    ))
                        .toList(),
                  );
                }),
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
                Icon(Icons.lightbulb_outline,
                    color: Colors.amber.shade700, size: 28),
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
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSpeak(tip),
                onLongPress: () => onTranslate(tip),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  // Text, MarkdownBody olarak değiştirildi
                  child: MarkdownBody(
                    data: tip,
                    selectable: false,
                    styleSheet: _getMdStyle(context),
                  ),
                ),
              ),
            )),
          ],
        ),
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