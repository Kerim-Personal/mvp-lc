// lib/lessons/grammar/c2/lexical_density_lesson.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vocachat/services/translation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LexicalDensityLessonScreen extends StatefulWidget {
  const LexicalDensityLessonScreen({super.key});

  @override
  State<LexicalDensityLessonScreen> createState() => _LexicalDensityLessonScreenState();
}

class _LexicalDensityLessonScreenState extends State<LexicalDensityLessonScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late FlutterTts flutterTts;
  String? _nativeLangCode;
  final Map<String, String> _translationCache = {};

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
    if (_translationCache.containsKey(cacheKey)) return _translationCache[cacheKey]!;
    try { await TranslationService.instance.ensureReady(target); } catch (_) {}
    try {
      final translated = await TranslationService.instance.translateFromEnglish(text, target);
      _translationCache[cacheKey] = translated;
      return translated;
    } catch (_) {
      return text;
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
                Row(children: const [Icon(Icons.translate, color: Colors.green), SizedBox(width: 8), Text('Translation', style: TextStyle(fontWeight: FontWeight.bold))]),
                const SizedBox(height: 12),
                const Text('Original', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(source),
                const SizedBox(height: 12),
                const Text('Translation', style: TextStyle(fontSize: 12, color: Colors.grey)),
                FutureBuilder<String>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Row(children: const [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('Translating...'),
                      ]);
                    }
                    return Text(snapshot.data ?? source, style: const TextStyle(fontWeight: FontWeight.w500));
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  }

  void _initializeTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage('en-US');
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
            expandedHeight: 250,
            stretch: true,
            pinned: true,
            backgroundColor: Colors.green.shade800,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text('Lexical Density', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green.shade600, Colors.teal.shade600],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.analytics_outlined, size: 70, color: Colors.white24),
                      const SizedBox(height: 8),
                      Text('Measuring information density', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 18)),
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
                const _SpeechHintBox(color: Colors.green),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.1, 0.7),
                  child: _LessonBlock(
                    icon: Icons.lightbulb_outline,
                    accent: Colors.green,
                    title: 'What is lexical density?',
                    content:
                        'Lexical density is the proportion of content words (nouns, verbs, adjectives, adverbs) to the total number of words. Higher density often signals more information-dense, academic style.',
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.2, 0.8),
                  child: _ExampleCard(
                    title: 'Identify content vs. function words',
                    accent: Colors.green,
                    examples: const [
                      Example(icon: Icons.filter_alt_outlined, category: 'Content words:', sentence: 'policy, accelerate, sustainable, rapidly'),
                      Example(icon: Icons.filter_alt_off_outlined, category: 'Function words:', sentence: 'the, and, of, to, is, that, which'),
                      Example(icon: Icons.text_fields, category: 'Mixed sentence:', sentence: 'The new policy will rapidly accelerate sustainable growth.'),
                    ],
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.3, 0.9),
                  child: _SimplifiedClickableCard(
                    title: 'Manual estimation (toy example)',
                    accent: Colors.green,
                    headers: const ['Text', 'Content words', 'Total words', 'Density'],
                    rows: const [
                      ['We will go to the park.', 'go, park (2)', '6', '≈ 0.33'],
                      ['Rapid technological progress transforms industries.', 'Rapid, technological, progress, transforms, industries (5)', '5', '1.00'],
                      ['The report was carefully reviewed by experts.', 'report, carefully, reviewed, experts (4)', '7', '≈ 0.57'],
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
                    accent: Colors.green,
                    title: 'Formula & interpretation',
                    content:
                        'Density = content words / total words.\nTypical ranges: conversation ~0.30–0.45; academic prose ~0.50–0.65. Use density as an indicator, not an absolute goal—clarity first.',
                    onSpeak: _speak,
                    onTranslate: _showTranslateSheet,
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.5, 1.0),
                  child: _TipCard(
                    accent: Colors.green,
                    title: 'Pro Tips & Pitfalls',
                    tips: const [
                      '**Avoid overpacking:** Extremely dense sentences can be hard to parse. Use punctuation and paragraphing.',
                      '**Balance style and audience:** Reports can be denser; instructions to end-users should be simpler.',
                      '**Nominalization increases density:** Converting verbs to nouns raises density but may reduce readability.',
                      '**Revise for clarity:** Prefer concrete verbs over abstract nouns when possible.',
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
  final MaterialColor color;
  const _SpeechHintBox({required this.color});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? color.shade900.withValues(alpha: 0.25) : color.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 24),
      child: const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('Tap text to listen; long-press to translate.'),
      ),
    );
  }
}

class _AnimatedLessonBlock extends StatelessWidget {
  final AnimationController controller;
  final Interval interval;
  final Widget child;
  const _AnimatedLessonBlock({required this.controller, required this.interval, required this.child});
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
  const _LessonBlock({required this.icon, required this.accent, required this.title, required this.content, required this.onSpeak, required this.onTranslate});
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
                  child: Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
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
              child: Text(content, style: TextStyle(fontSize: 16, height: 1.5, color: isDark ? Colors.grey.shade200 : Colors.grey.shade800)),
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
  const Example({required this.icon, required this.category, required this.sentence});
}

class _ExampleCard extends StatelessWidget {
  final String title;
  final MaterialColor accent;
  final List<Example> examples;
  final Function(String) onSpeak;
  final Function(String) onTranslate;
  const _ExampleCard({required this.title, required this.accent, required this.examples, required this.onSpeak, required this.onTranslate});
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => onSpeak(title),
            onLongPress: () => onTranslate(title),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
            ),
          ),
          const SizedBox(height: 16),
          ...examples.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _ExampleListItem(example: e, accent: accent, onSpeak: onSpeak, onTranslate: onTranslate),
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
  const _ExampleListItem({required this.example, required this.accent, required this.onSpeak, required this.onTranslate});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? accent.shade900.withValues(alpha: 0.25) : accent.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onSpeak('${example.category} ${example.sentence}'),
        onLongPress: () => onTranslate('${example.category} ${example.sentence}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Icon(example.icon, size: 22, color: accent.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(example.category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                Text(example.sentence, style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: isDark ? Colors.grey.shade200 : Colors.grey.shade800)),
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
  const _SimplifiedClickableCard({required this.title, required this.accent, required this.headers, required this.rows, required this.onSpeak, required this.onTranslate});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
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
              child: Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: isDark ? accent.shade200 : accent.shade800, fontSize: 15),
            dataTextStyle: TextStyle(color: isDark ? Colors.grey.shade200 : Colors.grey.shade800, fontSize: 16),
            columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
            rows: rows.map((row) {
              final textJoined = row.join('. ');
              return DataRow(
                onSelectChanged: (isSelected) { if (isSelected != null) onSpeak(textJoined); },
                cells: row.map((cell) => DataCell(GestureDetector(onLongPress: () => onTranslate(textJoined), child: Text(cell)))).toList(),
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
  final MaterialColor accent;
  const _TipCard({required this.title, required this.tips, required this.onSpeak, required this.onTranslate, required this.accent});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseText = TextStyle(fontSize: 16, height: 1.5, color: isDark ? Colors.grey.shade200 : Colors.grey.shade800);
    return Card(
      elevation: 2,
      shadowColor: accent.withValues(alpha: 0.1),
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : null,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.tips_and_updates_outlined, color: accent, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => onSpeak(title),
                onLongPress: () => onTranslate(title),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? accent.shade200 : accent.shade900)),
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
                      Expanded(child: Text(tip, style: baseText)),
                    ]),
                  ),
                ),
              )),
        ]),
      ),
    );
  }
}
