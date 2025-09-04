// lib/screens/vocabulary_treasure_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lingua_chat/models/vocabulary_model.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lingua_chat/widgets/store_screen/glassmorphism.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:flutter/services.dart';

class VocabularyTreasureScreen extends StatefulWidget {
  final VocabularyWord word;

  const VocabularyTreasureScreen({super.key, required this.word});

  @override
  State<VocabularyTreasureScreen> createState() =>
      _VocabularyTreasureScreenState();
}

class _VocabularyTreasureScreenState extends State<VocabularyTreasureScreen> with TickerProviderStateMixin {
  late FlutterTts flutterTts;
  late final AnimationController _animationController;

  // Translation helpers
  static final Map<String, OnDeviceTranslator> _translatorCache = {}; // key: src>tgt
  final Map<String, String?> _translationCache = {}; // text|tgt -> translated (null=fail)
  String? _nativeLangCode;
  bool _fetchingLang = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  void _initializeTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage("en-US");
    flutterTts.setSpeechRate(0.5);
    flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    flutterTts.stop();
    _animationController.dispose();
    super.dispose();
  }

  String _guessLangCode(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'[ğüşıçö]').hasMatch(lower)) return 'tr';
    if (RegExp(r'[àâçéèêëîïôûùüÿœ]').hasMatch(lower)) return 'fr';
    if (RegExp(r'[áéíñóúü]').hasMatch(lower)) return 'es';
    if (RegExp(r'[äöüß]').hasMatch(lower)) return 'de';
    if (RegExp(r'[ãõáâàéêíóôúç]').hasMatch(lower)) return 'pt';
    if (RegExp(r'[а-яё]').hasMatch(lower)) return 'ru';
    return 'en';
  }

  TranslateLanguage? _mapCode(String code) {
    switch (code) {
      case 'en': return TranslateLanguage.english;
      case 'tr': return TranslateLanguage.turkish;
      case 'es': return TranslateLanguage.spanish;
      case 'fr': return TranslateLanguage.french;
      case 'de': return TranslateLanguage.german;
      case 'it': return TranslateLanguage.italian;
      case 'pt': return TranslateLanguage.portuguese;
      case 'ru': return TranslateLanguage.russian;
      default: return null;
    }
  }

  Future<void> _ensureTranslator(String srcCode, String tgtCode) async {
    final key = '$srcCode>$tgtCode';
    if (_translatorCache.containsKey(key)) return;
    final src = _mapCode(srcCode);
    final tgt = _mapCode(tgtCode);
    if (src == null || tgt == null) throw Exception('Unsupported language');
    final manager = OnDeviceTranslatorModelManager();
    if (!await manager.isModelDownloaded(tgt.bcpCode)) {
      await manager.downloadModel(tgt.bcpCode);
    }
    if (!await manager.isModelDownloaded(src.bcpCode)) {
      await manager.downloadModel(src.bcpCode);
    }
    _translatorCache[key] = OnDeviceTranslator(sourceLanguage: src, targetLanguage: tgt);
  }

  Future<String> _getNativeLang() async {
    if (_nativeLangCode != null) return _nativeLangCode!;
    if (_fetchingLang) {
      while (_fetchingLang) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _nativeLangCode ?? 'en';
    }
    _fetchingLang = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final data = snap.data();
        _nativeLangCode = (data?['nativeLanguage'] as String?)?.toLowerCase() ?? 'en';
      } else {
        _nativeLangCode = 'en';
      }
    } catch (_) {
      _nativeLangCode = 'en';
    }
    _fetchingLang = false;
    return _nativeLangCode!;
  }

  Future<String?> _translate(String text) async {
    final tgt = await _getNativeLang();
    final src = _guessLangCode(text);
    final cacheKey = '$text|$tgt';
    if (_translationCache.containsKey(cacheKey)) return _translationCache[cacheKey];
    if (src == tgt) {
      _translationCache[cacheKey] = text;
      return text;
    }
    try {
      await _ensureTranslator(src, tgt);
      final translator = _translatorCache['$src>$tgt']!;
      final translated = await translator.translateText(text);
      _translationCache[cacheKey] = translated;
      return translated;
    } catch (_) {
      _translationCache[cacheKey] = null;
      return null;
    }
  }

  void _showTranslationSheet(String original) {
    final future = _translate(original);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16,12,16,16),
            child: FutureBuilder<String?>(
              future: future,
              builder: (c, snap) {
                final theme = Theme.of(c);
                if (snap.connectionState == ConnectionState.waiting) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Translating...', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(minHeight: 4),
                      const SizedBox(height: 16),
                      Text('Original', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 4),
                      SelectableText(original),
                    ],
                  );
                }
                final result = snap.data;
                final failed = !snap.hasData;
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Translation', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Copy original',
                            icon: const Icon(Icons.copy_outlined),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: original));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Original copied')));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Original', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SelectableText(original),
                      ),
                      const SizedBox(height: 16),
                      if (!failed && result != null && result != original) ...[
                        Text('Translated', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SelectableText(result),
                        ),
                      ] else if (failed) ...[
                        Text('Translation failed', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                      ] else ...[
                        Text('No translation needed (already your language).', style: theme.textTheme.bodySmall),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1d2630),
      body: Stack(
        children: [
          const _GlowyBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 350.0,
                backgroundColor: Colors.transparent,
                elevation: 0,
                stretch: true,
                // FIX: Disabling the automatic back button.
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(),
                  stretchModes: const [StretchMode.zoomBackground],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), // Adjusted top padding
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _AnimatedContent(
                      animationController: _animationController,
                      interval: const Interval(0.45, 0.95),
                      child: Text(
                        'Tip: Long press the example sentence to translate it into your native language.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _AnimatedContent(
                      animationController: _animationController,
                      interval: const Interval(0.6, 1.0),
                      child: _buildInfoCard(
                        icon: Icons.format_quote_rounded,
                        title: 'Example Sentence',
                        content: widget.word.exampleSentence,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: BackButton(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black12],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            GestureDetector(
              onTap: () => _speak(widget.word.word),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      widget.word.word,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 20, color: Colors.black54)
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.volume_up_rounded, color: Colors.white70, size: 36),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.word.phonetic,
              style: TextStyle(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String content, required Color color}) {
    return GlassmorphicContainer(
      width: double.infinity,
      blur: 12,
      borderRadius: 20,
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onLongPress: () => _showTranslationSheet(content),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowyBackground extends StatelessWidget {
  const _GlowyBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -150,
          left: -200,
          child: CircleAvatar(radius: 250, backgroundColor: Colors.green.withValues(alpha: 0.3)),
        ),
        Positioned(
          bottom: -200,
          right: -180,
          child: CircleAvatar(radius: 220, backgroundColor: Colors.teal.withValues(alpha: 0.3)),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }
}

class _AnimatedContent extends StatelessWidget {
  final AnimationController animationController;
  final Interval interval;
  final Widget child;

  const _AnimatedContent({
    required this.animationController,
    required this.interval,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animationController, curve: interval),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
            .animate(CurvedAnimation(parent: animationController, curve: interval)),
        child: child,
      ),
    );
  }
}