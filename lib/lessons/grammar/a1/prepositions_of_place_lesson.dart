// lib/lessons/grammar/a1/prepositions_of_place_lesson.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vocachat/services/translation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Eklendi

// --- MAIN LESSON SCREEN ---

class PrepositionsOfPlaceLessonScreen extends StatefulWidget {
  const PrepositionsOfPlaceLessonScreen({super.key});

  @override
  State<PrepositionsOfPlaceLessonScreen> createState() =>
      _PrepositionsOfPlaceLessonScreenState();
}

class _PrepositionsOfPlaceLessonScreenState
    extends State<PrepositionsOfPlaceLessonScreen>
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
            backgroundColor: Colors.brown.shade700,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text('Prepositions of Place',
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
                      Colors.brown.shade500,
                      Colors.orange.shade600,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 70, color: Colors.white24),
                      const SizedBox(height: 8),
                      Text(
                        'Where Is It?',
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
                    icon: Icons.lightbulb_outline,
                    title: 'What are Prepositions of Place?',
                    // Veri zaten Markdown formatındaydı
                    content:
                    "Prepositions of place are words that tell us the location of something. They answer the question 'Where?'. The three most common are **in, on,** and **at**.",
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.2, 0.8),
                  child: _SimplifiedClickableCard(
                    title: 'The Big Three: IN, ON, AT',
                    // Veri Markdown formatına güncellendi
                    headers: const ['**Preposition**', '**Use**', '**Example**'],
                    rows: const [
                      [
                        '**in**',
                        'For larger areas (countries, cities, rooms)',
                        'I am **in** London.'
                      ],
                      [
                        '**on**',
                        'For surfaces (streets, tables, walls)',
                        'The book is **on** the table.'
                      ],
                      [
                        '**at**',
                        'For specific points (addresses, buildings)',
                        'She is **at** the bus stop.'
                      ],
                    ],
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.3, 0.9),
                  child: _LessonBlock(
                    icon: Icons.star_border,
                    title: 'Common Prepositions',
                    // Veri zaten Markdown formatındaydı
                    content:
                    "While **in, on,** and **at** are the most fundamental, many other prepositions are used to describe location. Here are some of the most common ones.",
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.4, 1.0),
                  child: _ExampleCard(
                    title: 'More Prepositions in Action',
                    // Veri Markdown formatına güncellendi
                    examples: const [
                      Example(
                          icon: Icons.arrow_upward,
                          category: '**above:**',
                          sentence: '*The clock is **above** the window.*'),
                      Example(
                          icon: Icons.arrow_downward,
                          category: '**below/under:**',
                          sentence: '*The cat is sleeping **under** the bed.*'),
                      Example(
                          icon: Icons.arrow_forward,
                          category: '**next to:**',
                          sentence: '*The car is parked **next to** the tree.*'),
                      Example(
                          icon: Icons.swap_horiz,
                          category: '**between:**',
                          sentence: '*The ball is **between** the chairs.*'),
                      Example(
                          icon: Icons.directions,
                          category: '**in front of:**',
                          sentence:
                          '*He is waiting **in front of** the store.*'),
                    ],
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.5, 1.0),
                  child: _TipCard(
                    title: 'Pro Tips & Tricks',
                    // Veri zaten Markdown formatındaydı
                    tips: const [
                      "**Think of a hierarchy:** 'in' for the largest areas (continents, countries), 'on' for a middle level (streets, floors), and 'at' for the most specific point (an address).",
                      "**Context is everything:** Sometimes a preposition can change its meaning. For example, 'in the street' means inside a street, while 'on the street' means on the surface of it.",
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
                Icon(icon, color: Colors.brown.shade700, size: 28),
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
          ? Colors.brown.shade900.withOpacity(0.25)
          : Colors.brown.shade50,
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
              Icon(example.icon, size: 22, color: Colors.brown.shade600),
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
        fontSize: 15,
        color: isDark ? Colors.brown.shade100 : Colors.brown.shade800,
      ),
      strong: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.brown.shade100 : Colors.brown.shade800,
      ),
    );
  }

  MarkdownStyleSheet _getCellStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 16,
        color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
      ),
      strong: TextStyle(
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
      clipBehavior: Clip.antiAlias,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => onSpeak(title),
              onLongPress: () => onTranslate(title),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    )),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: false,
              // Stil özellikleri kaldırıldı
              // headingTextStyle: ...,
              // dataTextStyle: ...,
              columns: headers.map((h) {
                // DataColumn label'ı MarkdownBody olarak güncellendi
                return DataColumn(
                  label: MarkdownBody(
                    data: h,
                    selectable: false,
                    styleSheet: _getHeaderStyle(context),
                  ),
                );
              }).toList(),
              rows: rows.map((row) {
                final String textJoined = row.join('. ');
                return DataRow(
                  onSelectChanged: (isSelected) {
                    if (isSelected != null) onSpeak(textJoined);
                  },
                  cells: row.map((cell) {
                    // DataCell çocuğu MarkdownBody olarak güncellendi
                    return DataCell(
                      GestureDetector(
                        onLongPress: () => onTranslate(textJoined),
                        behavior: HitTestBehavior.opaque,
                        child: MarkdownBody(
                          data: cell,
                          selectable: false,
                          styleSheet: _getCellStyle(context),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
        ],
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
    return Card(
      elevation: 2,
      shadowColor: Colors.amber.withOpacity(0.1),
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
                const Icon(Icons.lightbulb_outline,
                    color: Colors.amber, size: 28),
                const SizedBox(width: 12),
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
                          color: isDark
                              ? Colors.amber.shade200
                              : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.map((tip) {
              // RichText ve split logic'i kaldırıldı
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSpeak(tip),
                  onLongPress: () => onTranslate(tip),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡 ', style: TextStyle(fontSize: 16)),
                        // RichText, MarkdownBody ile değiştirildi
                        Expanded(
                          child: MarkdownBody(
                            data: tip,
                            selectable: false,
                            styleSheet: _getMdStyle(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AnimatedLessonBlock extends StatelessWidget {
  final AnimationController controller;
  final Interval interval;
  final Widget child;
  const _AnimatedLessonBlock(
      {required this.controller, required this.interval, required this.child});
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: controller, curve: interval),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
            .animate(CurvedAnimation(parent: controller, curve: interval)),
        child: child,
      ),
    );
  }
}

class Example {
  final IconData icon;
  final String category;
  final String sentence;
  const Example(
      {required this.icon, required this.category, required this.sentence});
}

class _SpeechHintBox extends StatelessWidget {
  const _SpeechHintBox();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark
          ? Colors.brown.shade900.withOpacity(0.3)
          : Colors.brown.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.volume_up_outlined,
                color: Colors.brown.shade400, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You can listen by tapping on the titles and lines, and see the translation by pressing and holding.',
                style: TextStyle(
                    fontSize: 14, color: isDark ? Colors.white70 : null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}