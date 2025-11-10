// lib/lessons/grammar/b2/mixed_conditionals_lesson.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vocachat/services/translation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Eklendi

// --- MAIN LESSON SCREEN ---

class MixedConditionalsLessonScreen extends StatefulWidget {
  const MixedConditionalsLessonScreen({super.key});

  @override
  State<MixedConditionalsLessonScreen> createState() =>
      _MixedConditionalsLessonScreenState();
}

class _MixedConditionalsLessonScreenState
    extends State<MixedConditionalsLessonScreen> with TickerProviderStateMixin {
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
            backgroundColor: Colors.deepOrange.shade700,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text('Mixed Conditionals',
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
                      Colors.orange.shade500,
                      Colors.deepOrange.shade600,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shuffle,
                          size: 70, color: Colors.white24),
                      const SizedBox(height: 8),
                      Text(
                        'Mixing Past and Present Hypotheticals',
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
                    icon: Icons.call_split,
                    title: 'Mixed Conditionals: Combining Tenses',
                    // Veri Markdown formatına güncellendi
                    content:
                    "Mixed Conditionals combine the **Second** and **Third** Conditionals. They talk about hypothetical situations where a **past action affects the present**, or a **present state affects a hypothetical past**.",
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.2, 0.8),
                  child: _ExampleCard(
                    title: 'Types of Mixed Conditionals',
                    // Veri Markdown formatına güncellendi
                    examples: const [
                      Example(
                          icon: Icons.history,
                          category: '**Past Action → Present Result:**',
                          sentence:
                          '*If I **had studied** harder (Past Perfect), I **would be** a doctor now (would + verb).*'),
                      Example(
                          icon: Icons.update,
                          category: '**Present State → Past Result:**',
                          sentence:
                          '*If I **were** rich (Past Simple), I **would have bought** that car (would have + PP).*'),
                      Example(
                          icon: Icons.timeline,
                          category: '**Present State → Past Result:**',
                          sentence:
                          '*If she **weren\'t** so busy, she **would have called** you.*'),
                    ],
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.3, 0.9),
                  child: _SimplifiedClickableCard(
                    title: 'Structure: Past Condition → Present Result',
                    // Veri Markdown formatına güncellendi
                    headers: const [
                      '**If Clause (Past Perfect)**',
                      '**Result Clause (Would + Verb)**',
                      '**Full Sentence**'
                    ],
                    rows: const [
                      [
                        '*If I **had won**...*',
                        '*...I **would be** rich now.*',
                        '*If I had won the lottery, I would be rich now.*'
                      ],
                      [
                        '*If she **had studied**...*',
                        '*...she **would be** a doctor.*',
                        '*If she had studied medicine, she would be a doctor.*'
                      ],
                      [
                        '*If we **had left** earlier...*',
                        '*...we **would be** there by now.*',
                        '*If we had left earlier, we would be there by now.*'
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
                    title: 'Structure: Present Condition → Past Result',
                    // Veri Markdown formatına güncellendi
                    headers: const [
                      '**If Clause (Past Simple)**',
                      '**Result Clause (Would Have + PP)**',
                      '**Full Sentence**'
                    ],
                    rows: const [
                      [
                        '*If I **were** taller...*',
                        '*...I **would have played** basketball.*',
                        '*If I were taller, I would have played basketball.*'
                      ],
                      [
                        '*If she **spoke** French...*',
                        '*...she **would have gotten** the job.*',
                        '*If she spoke French, she would have gotten the job.*'
                      ],
                      [
                        '*If we **lived** in Paris...*',
                        '*...we **would have visited** the Louvre.*',
                        '*If we lived in Paris, we would have visited the Louvre.*'
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
                    title: 'Negative Forms',
                    // Veri Markdown formatına güncellendi
                    headers: const ['**Negative If Clause**', '**Negative Result**', '**Example**'],
                    rows: const [
                      [
                        '*If I **hadn\'t failed**...*',
                        '*...I **wouldn\'t be** retaking it.*',
                        '*If I hadn\'t failed the exam, I wouldn\'t be retaking it.*'
                      ],
                      [
                        '*If she **weren\'t** allergic...*',
                        '*...she **would have eaten** it.*',
                        '*If she weren\'t allergic, she would have eaten the cake.*'
                      ],
                      [
                        '*If we **hadn\'t missed**...*',
                        '*...we **wouldn\'t be** late.*',
                        '*If we hadn\'t missed the flight, we wouldn\'t be late.*'
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
                      '**Type 1 (Common):** Past action, present result. (If + Past Perfect, ...would + Verb)',
                      '**Type 2 (Less Common):** Present state, past result. (If + Past Simple, ...would have + PP)',
                      '**Always Hypothetical:** These are *always* for unreal situations, regrets, or dreams.',
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
    // Renkler bu dersin temasına (deepOrange) uyacak şekilde düzeltildi
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepOrange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.volume_up, color: Colors.deepOrange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tap to hear pronunciation, long press for translation.',
              style: TextStyle(color: Colors.deepOrange.shade900, fontSize: 14),
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
                Icon(icon, color: Colors.deepOrange.shade700, size: 28),
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

  const _ExampleListItem({
    required this.example,
    required this.onSpeak,
    required this.onTranslate,
  });

  // Stil metotları eklendi
  MarkdownStyleSheet _getCategoryStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
      ),
      strong: TextStyle(
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
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
    // Bu widget'taki Row yapısı korundu, sadece Text'ler MarkdownBody'ye dönüştürüldü
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onSpeak('${example.category} ${example.sentence}'),
      onLongPress: () => onTranslate('${example.category} ${example.sentence}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(example.icon, color: Colors.deepOrange.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownBody(
                  data: example.category,
                  selectable: false,
                  styleSheet: _getCategoryStyle(context),
                ),
                const SizedBox(height: 4),
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: headers
                    .map((h) => DataColumn(
                  label: InkWell(
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
                rows: rows.map((row) {
                  final String textJoined = row.join('. ');
                  return DataRow(
                    // Satır tıklaması eklendi
                    onSelectChanged: (isSelected) {
                      if (isSelected != null) onSpeak(textJoined);
                    },
                    cells: row
                        .map((cell) => DataCell(
                      GestureDetector(
                        // Hücre uzun basma eklendi
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
                }).toList(),
              ),
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
      height: 1.4,
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
            ...tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb,
                      color: Colors.deepOrange.shade600, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
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