// lib/lessons/grammar/b1/present_perfect_continuous_lesson.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vocachat/services/translation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- MAIN LESSON SCREEN ---

class PresentPerfectContinuousLessonScreen extends StatefulWidget {
  const PresentPerfectContinuousLessonScreen({super.key});

  @override
  State<PresentPerfectContinuousLessonScreen> createState() => _PresentPerfectContinuousLessonScreenState();
}

class _PresentPerfectContinuousLessonScreenState extends State<PresentPerfectContinuousLessonScreen>
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
    if (_translationCache.containsKey(cacheKey)) return _translationCache[cacheKey]!;
    try {
      await TranslationService.instance.ensureReady(target);
    } catch (_) {
      // ignore ensureReady failures, attempt translation anyway
    }
    try {
      final translated = await TranslationService.instance.translateFromEnglish(text, target);
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
                      Text('Translation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Original', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(source, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  const Text('Translation', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
            backgroundColor: Colors.green.shade700,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text('Present Perfect Continuous',
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
                      Colors.green.shade500,
                      Colors.teal.shade600,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time_filled,
                          size: 70, color: Colors.white24),
                      const SizedBox(height: 8),
                      Text(
                        'Ongoing Actions and Duration',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
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
                    icon: Icons.timeline,
                    title: 'Present Perfect Continuous: Have/Has Been + Verb-ing',
                    content:
                    "The Present Perfect Continuous tense shows actions that started in the past and are still continuing, or have recently stopped. It's formed with 'have/has been' + verb-ing. It emphasizes duration and continuity!",
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.2, 0.8),
                  child: _ExampleCard(
                    title: 'When to Use Present Perfect Continuous',
                    examples: const [
                      Example(
                          icon: Icons.access_time,
                          category: 'Ongoing Actions:',
                          sentence: 'I have been studying for 3 hours.'),
                      Example(
                          icon: Icons.wb_sunny,
                          category: 'Recent Activities:',
                          sentence: 'It has been raining all day.'),
                      Example(
                          icon: Icons.face,
                          category: 'Experiences:',
                          sentence: 'She has been living here for 5 years.'),
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
                    headers: const ['Subject', 'Have/Has Been + Verb-ing', 'Example'],
                    rows: const [
                      ['I', 'have been studying', 'I have been studying English.'],
                      ['You', 'have been working', 'You have been working hard.'],
                      ['He/She/It', 'has been raining', 'It has been raining.'],
                      ['We', 'have been living', 'We have been living here.'],
                      ['They', 'have been playing', 'They have been playing football.'],
                    ],
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.4, 1.0),
                  child: _SimplifiedClickableCard(
                    title: 'Negative Sentences: Have/Has Not Been + Verb-ing',
                    headers: const ['Full Form', 'Contraction', 'Example'],
                    rows: const [
                      ['I have not been studying.', "I haven\'t been studying.", "I haven\'t been studying."],
                      ['You have not been working.', "You haven\'t been working.", "You haven\'t been working."],
                      ['She has not been raining.', "She hasn\'t been raining.", "It hasn\'t been raining."],
                      ['We have not been living.', "We haven\'t been living.", "We haven\'t been living."],
                      ['They have not been playing.', "They haven\'t been playing.", "They haven\'t been playing."],
                    ],
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.5, 1.0),
                  child: _SimplifiedClickableCard(
                    title: 'Question Sentences: Have/Has + Subject + Been + Verb-ing?',
                    headers: const ['Question', 'Short Answer', 'Full Answer'],
                    rows: const [
                      ['Have I been studying?', 'Yes, you have.', 'Yes, you have been studying.'],
                      ['Have you been working?', 'No, I haven\'t.', 'No, I haven\'t been working.'],
                      ['Has it been raining?', 'Yes, it has.', 'Yes, it has been raining.'],
                      ['Have we been living?', 'No, we haven\'t.', 'No, we haven\'t been living.'],
                      ['Have they been playing?', 'Yes, they have.', 'Yes, they have been playing.'],
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
                    tips: const [
                      '**Duration Words:** Use with "for" (period) and "since" (starting point). E.g., "for 2 hours", "since morning".',
                      '**Vs Present Perfect Simple:** Use continuous for ongoing actions, simple for completed actions.',
                      '**Stative Verbs:** Don\'t use with verbs like "know", "like", "believe" – use Present Perfect Simple instead.',
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
      shadowColor: Colors.black.withValues(alpha: 0.08),
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
                Icon(icon, color: Colors.teal.shade700, size: 28),
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
      shadowColor: Colors.black.withValues(alpha: 0.08),
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

  const _ExampleListItem({required this.example, required this.onSpeak, required this.onTranslate});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? Colors.teal.shade900.withValues(alpha: 0.25) : Colors.teal.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onSpeak('${example.category} ${example.sentence}'),
        onLongPress: () => onTranslate('${example.category} ${example.sentence}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(example.icon, size: 22, color: Colors.teal.shade600),
              const SizedBox(width: 12),
              Text(
                example.category,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  example.sentence,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                  ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
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
                  children: headers.map((h) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () => onSpeak(h),
                      onLongPress: () => onTranslate(h),
                      child: Text(
                        h,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
                ...rows.map((row) => TableRow(
                  children: row.map((cell) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () => onSpeak(cell),
                      onLongPress: () => onTranslate(cell),
                      child: Text(
                        cell,
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  )).toList(),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
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
                Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 28),
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
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                    ),
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
