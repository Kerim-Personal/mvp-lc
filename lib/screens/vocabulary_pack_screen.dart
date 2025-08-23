// lib/screens/vocabulary_pack_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/discover/vocabulary_tab.dart';
import '../data/vocabulary_data.dart';
import '../models/word_model.dart';
import '../services/translation_service.dart';

// Main Screen Widget
class VocabularyPackScreen extends StatefulWidget {
  final VocabularyPack pack;
  const VocabularyPackScreen({super.key, required this.pack});

  @override
  State<VocabularyPackScreen> createState() => _VocabularyPackScreenState();
}

class _VocabularyPackScreenState extends State<VocabularyPackScreen> {
  late final PageController _pageController;
  late final List<Word> _words;
  late final List<GlobalKey<FlipCardState>> _cardKeys;
  late final FlutterTts _flutterTts;

  int _currentIndex = 0;
  final Set<int> _learnedWords = {};
  bool _isGridView = false; // Izgara/Liste görünümü için durum değişkeni
  String? _nativeLanguageCode;
  bool _modelsReady = false;
  bool _loadingUserLang = true;

  @override
  void initState() {
    super.initState();
    _words = vocabularyData[widget.pack.title] ?? [];
    _cardKeys = List.generate(_words.length, (_) => GlobalKey<FlipCardState>());
    _pageController = PageController();

    _initializeTts();

    _pageController.addListener(() {
      final newIndex = _pageController.page?.round() ?? 0;
      if (newIndex != _currentIndex) {
        setState(() {
          _currentIndex = newIndex;
          if (_currentIndex > 0 &&
              _cardKeys[_currentIndex - 1].currentState != null &&
              !_cardKeys[_currentIndex - 1].currentState!.isFront) {
            _cardKeys[_currentIndex - 1].currentState?.toggleCard();
          }
        });
      }
    });
    _fetchUserNativeLanguage();
  }

  void _initializeTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("en-US");
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _fetchUserNativeLanguage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = snap.data();
      final code = (data?['nativeLanguage'] as String?) ?? 'en';
      _nativeLanguageCode = code;
      if (mounted) setState(() {});
      // Modeller hazır mı kontrol et, değilse indir.
      _modelsReady = await TranslationService.instance.isModelReady(code);
      if (!_modelsReady) {
        await TranslationService.instance.preDownloadModels(code);
        _modelsReady = await TranslationService.instance.isModelReady(code);
      }
    } catch (_) {}
    if (mounted) setState(() { _loadingUserLang = false; });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _onWordLearned(int index) {
    setState(() {
      _learnedWords.add(index);
    });
  }

  void _goToNext() {
    if (_currentIndex < _words.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.pack.color1, widget.pack.color2],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: _words.isEmpty
                ? _buildEmptyState()
                : Column(
              children: [
                _buildAppBar(),
                _buildProgressIndicator(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isGridView ? _buildWordList() : _buildWordPager(),
                  ),
                ),
                if (!_isGridView) _buildNavigationControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI BUILDER METHODS ---

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            widget.pack.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_carousel_outlined : Icons.grid_view_outlined,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final double targetProgress = _words.isEmpty ? 0 : (_currentIndex + 1) / _words.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: targetProgress),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          );
        },
      ),
    );
  }

  Widget _buildWordList() {
    return ListView.builder(
      key: const ValueKey('wordList'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      itemCount: _words.length,
      itemBuilder: (context, index) {
        final word = _words[index];
        final isCurrent = index == _currentIndex;
        return GestureDetector(
          onTap: () {
            // HATA DÜZELTMESİ: Önce durumu güncelleyerek PageView'ın görünür olmasını sağlıyoruz,
            // ardından PageController'a istediğimiz sayfaya gitmesini söylüyoruz.
            setState(() {
              _isGridView = false;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(index);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            decoration: BoxDecoration(
              color: isCurrent ? Colors.white : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: isCurrent ? Border.all(color: widget.pack.color2, width: 2.5) : null,
              boxShadow: isCurrent
                  ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ]
                  : [],
            ),
            child: Text(
              word.word,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isCurrent ? widget.pack.color1 : Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWordPager() {
    // Eğer dil kodu yükleniyorsa gösterge
    if (_loadingUserLang) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return PageView.builder(
      key: const ValueKey('wordPager'),
      controller: _pageController,
      itemCount: _words.length,
      itemBuilder: (context, index) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(
            vertical: 24.0,
            horizontal: _currentIndex == index ? 24.0 : 40.0,
          ),
          child: WordCard(
            flipCardKey: _cardKeys[index],
            word: _words[index],
            isLearned: _learnedWords.contains(index),
            onLearned: () => _onWordLearned(index),
            onFlip: () {},
            onSpeakWord: () => _speak(_words[index].word),
            onSpeakExample: () => _speak(_words[index].example),
            nativeLanguageCode: _nativeLanguageCode ?? 'en',
          ),
        );
      },
    );
  }

  Widget _buildNavigationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(Icons.arrow_back_ios_new, _goToPrevious, _currentIndex > 0),
          Text(
            '${_currentIndex + 1} / ${_words.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildNavButton(Icons.arrow_forward_ios, _goToNext, _currentIndex < _words.length - 1),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback? onPressed, bool isEnabled) {
    return IconButton(
      icon: Icon(icon, color: Colors.white.withOpacity(isEnabled ? 1.0 : 0.3)),
      iconSize: 28,
      onPressed: isEnabled ? onPressed : null,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.15),
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined, color: Colors.white, size: 80),
          const SizedBox(height: 20),
          const Text(
            'No words have been added to this pack yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              foregroundColor: widget.pack.color1,
              backgroundColor: Colors.white,
            ),
            child: const Text('Go Back'),
          )
        ],
      ),
    );
  }
}

// Word Card Widget
class WordCard extends StatefulWidget {
  final GlobalKey<FlipCardState> flipCardKey;
  final Word word;
  final bool isLearned;
  final VoidCallback onLearned;
  final VoidCallback onFlip;
  final VoidCallback onSpeakWord;
  final VoidCallback onSpeakExample;
  final String nativeLanguageCode;
  const WordCard({
    super.key,
    required this.flipCardKey,
    required this.word,
    required this.isLearned,
    required this.onLearned,
    required this.onFlip,
    required this.onSpeakWord,
    required this.onSpeakExample,
    required this.nativeLanguageCode,
  });

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  bool _showTranslationFront = false;
  bool _showTranslationBack = false;
  bool _loadingFront = false;
  bool _loadingBack = false;
  String? _translatedFront;
  String? _translatedDefinition;
  String? _translatedExample;

  Future<void> _toggleTranslation() async {
    final isFront = widget.flipCardKey.currentState?.isFront ?? true;
    if (isFront) {
      if (_translatedFront == null && !_loadingFront) {
        setState(() { _loadingFront = true; });
        final t = await TranslationService.instance.translateFromEnglish(widget.word.word, widget.nativeLanguageCode);
        if (mounted) setState(() { _translatedFront = t; _loadingFront = false; });
      }
      setState(() { _showTranslationFront = !_showTranslationFront; });
    } else {
      if ((_translatedDefinition == null || _translatedExample == null) && !_loadingBack) {
        setState(() { _loadingBack = true; });
        final def = await TranslationService.instance.translateFromEnglish(widget.word.definition, widget.nativeLanguageCode);
        final ex = await TranslationService.instance.translateFromEnglish(widget.word.example, widget.nativeLanguageCode);
        if (mounted) setState(() { _translatedDefinition = def; _translatedExample = ex; _loadingBack = false; });
      }
      setState(() { _showTranslationBack = !_showTranslationBack; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlipCard(
      key: widget.flipCardKey,
      onFlipDone: (_) => widget.onFlip(),
      direction: FlipDirection.HORIZONTAL,
      front: _buildCardFace(
        context: context,
        content: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.word.word,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        isFront: true,
      ),
      back: _buildCardFace(
        context: context,
        content: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.word.definition,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '"${widget.word.example}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        isFront: false,
      ),
    );
  }

  Widget _buildCardFace({required BuildContext context, required Widget content, required bool isFront}) {
    final show = isFront ? _showTranslationFront : _showTranslationBack;
    final loading = isFront ? _loadingFront : _loadingBack;
    return Container(
      decoration: BoxDecoration(
        color: isFront ? Colors.white : const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: content,
              ),
            ),
            if (isFront && !_showTranslationFront)
              const Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_outlined, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Tap for definition',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            Positioned(
              top: 8,
              left: 4,
              child: IconButton(
                tooltip: 'Çevir',
                icon: const Icon(Icons.translate, color: Colors.teal),
                onPressed: _toggleTranslation,
              ),
            ),
            Positioned(
              top: 8,
              right: 4,
              child: IconButton(
                icon: Icon(
                  Icons.volume_up,
                  color: isFront ? Colors.grey.shade500 : Colors.blue.shade700,
                ),
                onPressed: isFront ? widget.onSpeakWord : widget.onSpeakExample,
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              left: 0,
              right: 0,
              bottom: 0,
              height: show ? 120 : 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.black.withOpacity(0.05),
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: isFront
                              ? Text(
                                  _translatedFront ?? '',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_translatedDefinition != null)
                                      Text(
                                        _translatedDefinition!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                    const SizedBox(height: 8),
                                    if (_translatedExample != null)
                                      Text(
                                        _translatedExample!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                                      ),
                                  ],
                                ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
