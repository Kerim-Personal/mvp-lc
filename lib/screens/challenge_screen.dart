// lib/screens/challenge_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingua_chat/models/challenge_model.dart';
import 'package:lingua_chat/widgets/store_screen/glassmorphism.dart'; // FIX: Added missing import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class ChallengeScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeScreen({super.key, required this.challenge});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;

  // Translation helpers
  static final Map<String, OnDeviceTranslator> _translatorCache = {}; // key: src>tgt
  final Map<String, String?> _translationCache = {}; // sentence|tgt -> translated (null=fail)
  String? _nativeLangCode; // cached user native language
  bool _fetchingLang = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
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
      // küçük bekleme döngüsü
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

  Future<String?> _translate(String sentence) async {
    final tgt = await _getNativeLang();
    final src = _guessLangCode(sentence);
    final cacheKey = '$sentence|$tgt';
    if (_translationCache.containsKey(cacheKey)) return _translationCache[cacheKey];
    if (src == tgt) {
      _translationCache[cacheKey] = sentence; // no translation needed
      return sentence;
    }
    try {
      await _ensureTranslator(src, tgt);
      final translator = _translatorCache['$src>$tgt']!;
      final translated = await translator.translateText(sentence);
      _translationCache[cacheKey] = translated;
      return translated;
    } catch (_) {
      _translationCache[cacheKey] = null;
      return null;
    }
  }

  void _showTranslationSheet(String sentence) {
    final future = _translate(sentence);
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
                      SelectableText(sentence),
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
                              Clipboard.setData(ClipboardData(text: sentence));
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
                          color: theme.colorScheme.surfaceVariant.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SelectableText(sentence),
                      ),
                      const SizedBox(height: 16),
                      if (!failed && result != null && result != sentence) ...[
                        Text('Translated', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withAlpha(28),
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
      backgroundColor: const Color(0xff2a2a2a), // A dark and modern background
      body: Stack(
        children: [
          // Background effects
          const _GlowyBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 300.0,
                backgroundColor: Colors.transparent,
                elevation: 0,
                stretch: true,
                pinned: true,
                automaticallyImplyLeading: false, // Remove automatic back button
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(),
                  stretchModes: const [StretchMode.zoomBackground],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Info note for translation feature
                    _AnimatedContent(
                      animationController: _animationController,
                      interval: const Interval(0.3, 0.9),
                      child: Text(
                        'Tip: Long press any sentence to translate it into your native language.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(190)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _AnimatedContent(
                      animationController: _animationController,
                      interval: const Interval(0.4, 1.0),
                      child: const Text(
                        'Example Sentences',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(widget.challenge.exampleSentences.length,
                            (index) {
                          return _AnimatedContent(
                            animationController: _animationController,
                            interval: Interval(0.5 + (index * 0.1), 1.0,
                                curve: Curves.easeOut),
                            child: _buildExampleCard(
                                widget.challenge.exampleSentences[index]),
                          );
                        }),
                  ]),
                ),
              ),
            ],
          ),
          // Custom Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: BackButton(color: Colors.white.withAlpha(204)),
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
          colors: [Colors.transparent, Colors.black26],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            const Icon(Icons.flag_circle_outlined,
                size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            Text(
              widget.challenge.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 10, color: Colors.black38)],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.challenge.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, color: Colors.white.withAlpha(204)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCard(String sentence) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassmorphicContainer(
        width: double.infinity,
        blur: 12,
        borderRadius: 16,
        border: Border.all(color: Colors.white.withAlpha(26)),
        gradient: LinearGradient(
          colors: [
            Colors.white.withAlpha(38),
            Colors.white.withAlpha(13),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onLongPress: () => _showTranslationSheet(sentence),
                  child: Text(
                    sentence,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withAlpha(230),
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(Icons.copy_all_outlined,
                    color: Colors.white.withAlpha(179)),
                tooltip: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: sentence));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.teal,
                      content: const Text('Sentence copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for the background
class _GlowyBackground extends StatelessWidget {
  const _GlowyBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -150,
          child: CircleAvatar(
              radius: 200, backgroundColor: Colors.amber.withAlpha(64)),
        ),
        Positioned(
          bottom: -180,
          left: -150,
          child: CircleAvatar(
              radius: 220, backgroundColor: Colors.orange.withAlpha(64)),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }
}

// Helper widget for animations
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
            .animate(
            CurvedAnimation(parent: animationController, curve: interval)),
        child: child,
      ),
    );
  }
}