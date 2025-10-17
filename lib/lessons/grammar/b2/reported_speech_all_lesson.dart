// lib/lessons/grammar/b2/reported_speech_all_lesson.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vocachat/services/translation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- MAIN LESSON SCREEN ---

class ReportedSpeechAllLessonScreen extends StatefulWidget {
  const ReportedSpeechAllLessonScreen({super.key});

  @override
  State<ReportedSpeechAllLessonScreen> createState() =>
      _ReportedSpeechAllLessonScreenState();
}

class _ReportedSpeechAllLessonScreenState extends State<ReportedSpeechAllLessonScreen>
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
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final code = (snap.data()?['nativeLanguage'] as String?)?.trim();
      if (code == null || code.isEmpty) return _nativeLangCode = 'en';
      _nativeLangCode = code;
      return _nativeLangCode!;
    } catch (_) {
      return _nativeLangCode = 'en';
    }
  }

  Future<String> _translateToNative(String text) async {
    final target = await _getTargetLangCode();
    final cacheKey = '$target::$text';
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
      await TranslationService.instance.translateFromEnglish(text, target);
      _translationCache[cacheKey] = translated;
      return translated;
    } catch (_) {
      // Fallback to original text if translation fails
      return text;
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
                  Text(source, style: const TextStyle(fontSize: 16)),
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
                              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 8),
                              Text('Translating...'),
                            ],
                          ),
                        );
                      }
                      final translated = snapshot.data ?? source;
                      return Text(translated, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500));
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
    await flutterTts.speak(text.replaceAll('**', ''));
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
            backgroundColor: Colors.blueGrey.shade700,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text('Reported Speech (All)',
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
                      Colors.blueGrey.shade500,
                      Colors.grey.shade600,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.message,
                          size: 70, color: Colors.white24),
                      const SizedBox(height: 8),
                      Text(
                        'Reporting What Others Said',
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
                    icon: Icons.record_voice_over,
                    title: 'Reported Speech: Changes in Tense and Structure',
                    content:
                    "Reported speech is used to tell what someone said without using their exact words. We make changes to pronouns, tenses, time expressions, and sometimes structure. The reporting verb (said/told) is in past tense.",
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.2, 0.8),
                  child: _SimplifiedClickableCard(
                    title: 'Tense Changes in Reported Speech',
                    headers: const ['Direct Speech', 'Reported Speech'],
                    rows: const [
                      ['"I am happy."', 'She said (that) she was happy.'],
                      ['"I will help."', 'He said (that) he would help.'],
                      ['"I have finished."', 'They said (that) they had finished.'],
                      ['"I can swim."', 'She said (that) she could swim.'],
                      ['"I must go."', 'He said (that) he had to go.'],
                      ['"I may come."', 'They said (that) they might come.'],
                    ],
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.3, 0.9),
                  child: _SimplifiedClickableCard(
                    title: 'Time and Place Changes',
                    headers: const ['Direct Speech', 'Reported Speech'],
                    rows: const [
                      ['today', 'that day'],
                      ['yesterday', 'the day before/the previous day'],
                      ['tomorrow', 'the next day/the following day'],
                      ['next week', 'the following week'],
                      ['last week', 'the week before/the previous week'],
                      ['here', 'there'],
                      ['this', 'that'],
                      ['these', 'those'],
                    ],
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.4, 1.0),
                  child: _ExampleCard(
                    title: 'Questions in Reported Speech',
                    examples: const [
                      Example(
                          icon: Icons.question_answer,
                          category: 'Yes/No Questions:',
                          sentence: '"Are you coming?" → He asked if/whether I was coming.'),
                      Example(
                          icon: Icons.help_outline,
                          category: 'Wh- Questions:',
                          sentence: '"Where do you live?" → She asked where I lived.'),
                      Example(
                          icon: Icons.short_text,
                          category: 'Short Answers:',
                          sentence: '"Yes, I do." → He said that he did.'),
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
                    tips: const [
                      '**Said vs Told:** "Said" is followed by "that", "told" is followed by object.',
                      '**No Tense Change:** For general truths, present tenses stay the same.',
                      '**Reporting Verbs:** Said, told, asked, replied, explained, etc.',
                      '**Modal Changes:** Can→could, may→might, will→would, etc.',
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
              'Tap to hear pronunciation, long press for translation.',
              style: TextStyle(color: Colors.blue.shade900, fontSize: 14),
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
                Icon(icon, color: Colors.blueGrey.shade700, size: 28),
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
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                  ),
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
              child: _ExampleListItem(example: e, onSpeak: onSpeak, onTranslate: onTranslate),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(example.icon, color: Colors.blueGrey.shade600, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => onSpeak(example.category),
                onLongPress: () => onTranslate(example.category),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    example.category,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => onSpeak(example.sentence),
                onLongPress: () => onTranslate(example.sentence),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    example.sentence,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: headers.map((h) => DataColumn(
                  label: InkWell(
                    onTap: () => onSpeak(h),
                    onLongPress: () => onTranslate(h),
                    child: Text(h, style: TextStyle(fontWeight: FontWeight.bold, color: onSurface)),
                  ),
                )).toList(),
                rows: rows.map((r) => DataRow(
                  cells: r.map((c) => DataCell(
                    InkWell(
                      onTap: () => onSpeak(c),
                      onLongPress: () => onTranslate(c),
                      child: Text(c, style: TextStyle(color: isDark ? Colors.grey.shade200 : Colors.grey.shade800)),
                    ),
                  )).toList(),
                )).toList(),
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
                  Icon(Icons.lightbulb, color: Colors.blueGrey.shade600, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => onSpeak(tip),
                      onLongPress: () => onTranslate(tip),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          tip,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                          ),
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
