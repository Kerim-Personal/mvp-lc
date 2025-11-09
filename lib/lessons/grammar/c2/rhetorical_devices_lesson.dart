// lib/lessons/grammar/c2/rhetorical_devices_lesson.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vocachat/services/translation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Eklendi

// --- MAIN LESSON SCREEN ---

class RhetoricalDevicesLessonScreen extends StatefulWidget {
  const RhetoricalDevicesLessonScreen({super.key});

  @override
  State<RhetoricalDevicesLessonScreen> createState() =>
      _RhetoricalDevicesLessonScreenState();
}

class _RhetoricalDevicesLessonScreenState
    extends State<RhetoricalDevicesLessonScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late FlutterTts flutterTts;
  String? _nativeLangCode;
  final Map<String, String> _translationCache = {};

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
    } catch (_) {}
    try {
      final translated =
      await TranslationService.instance.translateFromEnglish(cleanText, target);
      _translationCache[cacheKey] = translated;
      return translated;
    } catch (_) {
      return cleanText;
    }
  }

  Future<void> _showTranslateSheet(String source) async {
    if (!mounted) return;
    final future = _translateToNative(source);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: const [
                  Icon(Icons.translate, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text('Translation',
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                ]),
                const SizedBox(height: 12),
                const Text('Original',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                // Orijinal metni Markdown'dan temizlenmiş göster
                Text(_stripMarkdown(source), style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                const Text('Translation',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                FutureBuilder<String>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Row(children: const [
                        SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('Translating...'),
                      ]);
                    }
                    return Text(snapshot.data ?? _stripMarkdown(source),
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 16));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
  }

  void _initializeTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage('en-US');
    flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    // Konuşma için Markdown'ı temizle
    await flutterTts.speak(_stripMarkdown(text));
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
            expandedHeight: 250,
            stretch: true,
            pinned: true,
            backgroundColor: Colors.deepPurple.shade700,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text('Rhetorical Devices',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.deepPurple.shade500, Colors.purple.shade600],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome_outlined,
                          size: 70, color: Colors.white24),
                      const SizedBox(height: 8),
                      Text('Persuasive language techniques',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8), fontSize: 18)),
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
                    accent: Colors.deepPurple,
                    title: 'What are rhetorical devices?',
                    content:
                    'Rhetorical devices are **persuasive techniques** that use language patterns to make arguments more compelling, memorable, or emotionally resonant. They include **repetition**, **parallelism**, **metaphor**, **rhetorical questions**, and many others.',
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.2, 0.8),
                  child: _ExampleCard(
                    title: 'Common rhetorical devices',
                    accent: Colors.deepPurple,
                    examples: const [
                      Example(
                          icon: Icons.repeat,
                          category: '**Anaphora (repetition):**',
                          sentence: '*We shall fight on the beaches, we shall fight on the landing grounds...*'),
                      Example(
                          icon: Icons.question_mark,
                          category: '**Rhetorical question:**',
                          sentence: '*Are we really going to stand by and do nothing?*'),
                      Example(
                          icon: Icons.compare_arrows,
                          category: '**Antithesis (contrast):**',
                          sentence: '*Not that I loved Caesar less, but that I loved Rome more.*'),
                    ],
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.3, 0.9),
                  child: _SimplifiedClickableCard(
                    title: 'Device examples in context',
                    accent: Colors.deepPurple,
                    headers: const ['**Device**', '**Example**', '**Effect**'],
                    rows: const [
                      [
                        '**Metaphor**',
                        '*Time is money*',
                        'Creates vivid comparison'
                      ],
                      [
                        '**Hyperbole**',
                        '*I\'ve told you a million times*',
                        'Emphasizes point dramatically'
                      ],
                      [
                        '**Alliteration**',
                        '*Peter Piper picked*',
                        'Makes phrase memorable'
                      ],
                    ],
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.4, 1.0),
                  child: _LessonBlock(
                    icon: Icons.rule_outlined,
                    accent: Colors.deepPurple,
                    title: 'Purpose and application',
                    content:
                    'Rhetorical devices serve multiple purposes:\n\n* **Persuasion:** Make arguments more convincing\n* **Emphasis:** Highlight key points\n* **Memory:** Make ideas stick\n* **Emotion:** Connect with audience feelings\n\nUse them **strategically** in speeches, essays, and formal writing.',
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.5, 1.0),
                  child: _TipCard(
                    title: 'Pro Tips & Pitfalls',
                    tips: const [
                      '**Don\'t overuse:** Too many devices can sound forced or manipulative.',
                      '**Match your audience:** Formal devices for academic writing, simpler ones for casual contexts.',
                      '**Practice identification:** Read famous speeches to spot devices in action.',
                      '**Balance substance and style:** Devices enhance good content but can\'t replace it.',
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

class _SpeechHintBox extends StatelessWidget {
  // accent (color) kaldırıldı, içeride sabitlendi
  const _SpeechHintBox();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const color = Colors.deepPurple; // Tema rengi
    return Card(
      elevation: 0,
      color: isDark ? color.shade900.withOpacity(0.25) : color.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.volume_up,
                color: isDark ? color.shade300 : color.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tap text to listen; long-press to translate.',
                style: TextStyle(
                    color: isDark ? color.shade200 : color.shade900,
                    fontSize: 14),
              ),
            ),
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

class _LessonBlock extends StatelessWidget {
  final IconData icon;
  final MaterialColor accent;
  final String title;
  final String content;
  final Function(String) onSpeak;
  final Function(String) onTranslate;
  const _LessonBlock(
      {required this.icon,
        required this.accent,
        required this.title,
        required this.content,
        required this.onSpeak,
        required this.onTranslate});

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
    final italicText = TextStyle(
      fontStyle: FontStyle.italic,
      color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
    );

    return MarkdownStyleSheet(
      p: baseText,
      strong: strongText,
      em: italicText,
      // HATA 2 DÜZELTMESİ: 'li' 'listBullet' olarak değiştirildi
      listBullet: baseText,
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: accent.shade700, size: 28),
            const SizedBox(width: 14),
            Expanded(
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
                          color: onSurface)),
                ),
              ),
            ),
          ]),
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
        ]),
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

class _ExampleCard extends StatelessWidget {
  final String title;
  final MaterialColor accent;
  final List<Example> examples;
  final Function(String) onSpeak;
  final Function(String) onTranslate;
  const _ExampleCard(
      {required this.title,
        required this.accent,
        required this.examples,
        required this.onSpeak,
        required this.onTranslate});
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => onSpeak(title),
            onLongPress: () => onTranslate(title),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text(title,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: onSurface)),
            ),
          ),
          const SizedBox(height: 16),
          ...examples.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _ExampleListItem(
                example: e,
                accent: accent,
                onSpeak: onSpeak,
                onTranslate: onTranslate),
          )),
        ]),
      ),
    );
  }
}

class _ExampleListItem extends StatelessWidget {
  final Example example;
  final MaterialColor accent;
  final Function(String) onSpeak;
  final Function(String) onTranslate;
  const _ExampleListItem(
      {required this.example,
        required this.accent,
        required this.onSpeak,
        required this.onTranslate});

  // Stil metotları eklendi
  MarkdownStyleSheet _getCategoryStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MarkdownStyleSheet(
      p: TextStyle(
        fontWeight: FontWeight.bold,
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
      em: const TextStyle(fontStyle: FontStyle.italic),
      strong: TextStyle(
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? accent.shade900.withOpacity(0.25) : accent.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onSpeak('${example.category} ${example.sentence}'),
        onLongPress: () =>
            onTranslate('${example.category} ${example.sentence}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Icon(example.icon, size: 22, color: accent.shade600),
            const SizedBox(width: 12),
            Expanded(
              child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Text, MarkdownBody olarak değiştirildi
                MarkdownBody(
                  data: example.category,
                  selectable: false,
                  styleSheet: _getCategoryStyle(context),
                ),
                // Text, MarkdownBody olarak değiştirildi
                MarkdownBody(
                  data: example.sentence,
                  selectable: false,
                  styleSheet: _getSentenceStyle(context),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SimplifiedClickableCard extends StatelessWidget {
  final String title;
  final MaterialColor accent;
  final List<String> headers;
  final List<List<String>> rows;
  final Function(String) onSpeak;
  final Function(String) onTranslate;
  const _SimplifiedClickableCard(
      {required this.title,
        required this.accent,
        required this.headers,
        required this.rows,
        required this.onSpeak,
        required this.onTranslate});

  // Stil metotları eklendi
  MarkdownStyleSheet _getHeaderStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MarkdownStyleSheet(
      p: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDark ? accent.shade200 : accent.shade800,
        fontSize: 15,
      ),
      strong: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDark ? accent.shade200 : accent.shade800,
      ),
    );
  }

  MarkdownStyleSheet _getCellStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MarkdownStyleSheet(
      p: TextStyle(
        color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
        fontSize: 16,
      ),
      em: const TextStyle(fontStyle: FontStyle.italic),
      strong: TextStyle(
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

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
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                      color: onSurface(context))),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            // Orijinal stiller kaldırıldı
            columns: headers
                .map((h) => DataColumn(
              // Text, MarkdownBody olarak değiştirildi
              label: MarkdownBody(
                data: h,
                selectable: false,
                styleSheet: _getHeaderStyle(context),
              ),
            ))
                .toList(),
            rows: rows.map((row) {
              final textJoined = row.join('. ');
              return DataRow(
                onSelectChanged: (isSelected) {
                  if (isSelected != null) onSpeak(textJoined);
                },
                cells: row
                    .map((cell) => DataCell(
                  GestureDetector(
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
        const SizedBox(height: 10),
      ]),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final List<String> tips;
  final Function(String) onSpeak;
  final Function(String) onTranslate;
  // HATA 3 DÜZELTMESİ: 'accent' parametreleri kaldırıldı
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
    final italicText = TextStyle(
      fontStyle: FontStyle.italic,
      color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
    );

    return MarkdownStyleSheet(
      p: baseText,
      strong: strongText,
      em: italicText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Standart _TipCard görünümüne dönüştürüldü (Amber temalı)
    return Card(
      elevation: 2,
      shadowColor: Colors.amber.withOpacity(0.1), // Standart amber
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : null,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.tips_and_updates_outlined,
                color: Colors.amber.shade700, size: 28), // Standart amber
            const SizedBox(width: 12),
            Expanded(
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
                          color: isDark
                              ? Colors.amber.shade200
                              : Colors.amber.shade900)), // Standart amber
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ...tips.map((tip) => Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSpeak(tip),
              onLongPress: () => onTranslate(tip),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('💡 ', style: TextStyle(fontSize: 16)),
                  // Text, MarkdownBody olarak değiştirildi
                  Expanded(
                    child: MarkdownBody(
                      data: tip,
                      selectable: false,
                      styleSheet: _getMdStyle(context),
                    ),
                  ),
                ]),
              ),
            ),
          )),
        ]),
      ),
    );
  }
}