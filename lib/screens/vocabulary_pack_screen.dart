// lib/screens/vocabulary_pack_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/discover/vocabulary_tab.dart';
import '../data/vocabulary_data_clean.dart';
import '../models/word_model.dart';
import '../services/translation_service.dart';
import '../repositories/vocabulary_progress_repository.dart';

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
    _words = vocabularyDataClean[widget.pack.title] ?? [];
    _cardKeys = List.generate(_words.length, (_) => GlobalKey<FlipCardState>());
    _pageController = PageController();

    _initializeTts();
    _restoreProgress();

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
    // Emniyet: 10 sn içinde dil yüklenmezse spinnerı kapat.
    Timer(const Duration(seconds: 10), () {
      if (mounted && _loadingUserLang) {
        setState(() { _loadingUserLang = false; });
      }
    });
  }

  void _initializeTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("en-US");
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setPitch(1.0);
    // Tanım ve örneği sırayla okuması için konuşma tamamlanmasını bekle
    _flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _speakDefinitionAndExample(Word w) async {
    try {
      await _flutterTts.stop();
      final def = w.definition.trim();
      final ex = w.example.trim();
      if (def.isNotEmpty) {
        await _flutterTts.speak(def);
      }
      if (ex.isNotEmpty && ex.toLowerCase() != def.toLowerCase()) {
        await _flutterTts.speak(ex);
      }
    } catch (_) {}
  }

  Future<void> _fetchUserNativeLanguage() async {
    String code = 'en';
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final data = snap.data();
        final fetched = (data?['nativeLanguage'] as String?)?.trim();
        if (fetched != null && fetched.isNotEmpty) {
          code = fetched;
        }
      }
      _nativeLanguageCode = code;
      if (mounted) setState(() {});
      // Model hazırlığını UI'yı sonsuza dek bloklamayacak şekilde timeout ile kısıtla.
      Future<void> prepare() async {
        _modelsReady = await TranslationService.instance.isModelReady(code);
        if (!_modelsReady) {
          try {
            await TranslationService.instance.preDownloadModels(code);
            _modelsReady = await TranslationService.instance.isModelReady(code);
          } catch (_) {
            // İndirme başarısızsa sessizce devam; kullanıcı yine kartları görecek.
          }
        }
      }
      await prepare().timeout(const Duration(seconds: 8), onTimeout: () {
        // Timeout durumunda yine de devam edip ekranı açıyoruz.
      });
    } catch (_) {
      // Hata durumunda varsayılan İngilizce ile devam.
    } finally {
      if (mounted) {
        setState(() { _loadingUserLang = false; });
      }
    }
  }

  Future<void> _restoreProgress() async {
    final learnedSet = await VocabularyProgressRepository.instance.fetchLearnedWords(widget.pack.title);
    if (learnedSet.isEmpty) return;
    final indexSet = <int>{};
    for (int i = 0; i < _words.length; i++) {
      if (learnedSet.contains(_words[i].word)) indexSet.add(i);
    }
    if (mounted) {
      setState(() { _learnedWords.addAll(indexSet); });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _toggleWordLearned(int index) async {
    if (index < 0 || index >= _words.length) return;
    final now = await VocabularyProgressRepository.instance.toggleLearned(widget.pack.title, _words[index].word);
    setState(() {
      if (now) {
        _learnedWords.add(index);
      } else {
        _learnedWords.remove(index);
      }
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
    final learned = _learnedWords.length;
    final total = _words.length;
    final progress = total == 0 ? 0.0 : learned / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Learned: $learned / $total',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              if (progress > 0)
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return ListView.builder(
      key: const ValueKey('wordList'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      itemCount: _words.length,
      itemBuilder: (context, index) {
        final word = _words[index];
        final isCurrent = index == _currentIndex;
        final isLearned = _learnedWords.contains(index);
        final baseBg = isDark ? Colors.black : Colors.white;
        final bgColor = isCurrent
            ? baseBg
            : isDark
            ? Colors.black.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.7);

        return GestureDetector(
          onTap: () {
            setState(() {
              _currentIndex = index; // Yeni tıklanan kelimenin indeksini set et
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
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: isLearned
                  ? Border.all(color: isDark ? Colors.tealAccent : Colors.teal.shade700, width: 2.5)
                  : null,
              boxShadow: isCurrent
                  ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
                  : [],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Text(
                    word.word,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCurrent
                          ? (isDark ? Colors.white : widget.pack.color1)
                          : (isDark ? Colors.white70 : onSurface.withValues(alpha: 0.87)),
                    ),
                  ),
                ),
                if (isLearned)
                  Positioned(
                    bottom: -8,
                    right: -8,
                    child: Icon(
                      Icons.check_circle_outlined,
                      color: isDark ? Colors.tealAccent : Colors.teal.shade700,
                      size: 24,
                    ),
                  ),
              ],
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
            onToggleLearned: () => _toggleWordLearned(index),
            onFlip: () {},
            onSpeakWord: () => _speak(_words[index].word),
            onSpeakExample: () => _speak(_words[index].example),
            onSpeakDefinitionAndExample: () => _speakDefinitionAndExample(_words[index]),
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
      icon: Icon(icon, color: Colors.white.withValues(alpha: isEnabled ? 1.0 : 0.3)),
      iconSize: 28,
      onPressed: isEnabled ? onPressed : null,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.15),
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
  final VoidCallback onToggleLearned; // değiştirildi
  final VoidCallback onFlip;
  final VoidCallback onSpeakWord;
  final VoidCallback onSpeakExample;
  final VoidCallback? onSpeakDefinitionAndExample; // yeni parametre
  final String nativeLanguageCode;
  const WordCard({
    super.key,
    required this.flipCardKey,
    required this.word,
    required this.isLearned,
    required this.onToggleLearned,
    required this.onFlip,
    required this.onSpeakWord,
    required this.onSpeakExample,
    this.onSpeakDefinitionAndExample,
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
    try {
      await TranslationService.instance.ensureReady(widget.nativeLanguageCode);
    } catch (_) {
      // Model indirilemezse yine de UI'yi kilitleme; mevcut davranışla devam et
    }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return FlipCard(
      key: widget.flipCardKey,
      onFlipDone: (_) => widget.onFlip(),
      direction: FlipDirection.HORIZONTAL,
      front: _buildCardFace(
        context: context,
        isDark: isDark,
        content: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.word.word,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
        ),
        isFront: true,
      ),
      back: _buildCardFace(
        context: context,
        isDark: isDark,
        content: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.word.definition,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '"${widget.word.example}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        isFront: false,
      ),
    );
  }

  Widget _buildCardFace({required BuildContext context, required Widget content, required bool isFront, required bool isDark}) {
    final show = isFront ? _showTranslationFront : _showTranslationBack;
    final loading = isFront ? _loadingFront : _loadingBack;
    const double iconSize = 30; // küçültüldü (önce 36 idi)

    return Container(
      decoration: BoxDecoration(
        color: isFront ? (isDark ? const Color(0xFF111111) : Colors.white) : (isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F4F8)),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          )
        ],
        border: widget.isLearned ? Border.all(color: Colors.tealAccent, width: 3) : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: content,
            ),
          ),
          // Panel ÖNCE konuluyor ki ikonlar üstte kalsın ve tıklanabilsin
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: show ? 100 : 0,
                  maxHeight: show ? 160 : 0,
                ),
                child: show
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                          child: loading
                              ? const Center(child: SizedBox(height: 40, width: 40, child: CircularProgressIndicator()))
                              : SingleChildScrollView(
                                  child: isFront
                                      ? Text(
                                          _translatedFront ?? '',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white : Colors.black,
                                          ),
                                        )
                                      : Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_translatedDefinition != null)
                                              Text(
                                                _translatedDefinition!,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? Colors.white : Colors.black,
                                                ),
                                              ),
                                            const SizedBox(height: 8),
                                            if (_translatedExample != null)
                                              Text(
                                                _translatedExample!,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontStyle: FontStyle.italic,
                                                  color: isDark ? Colors.white70 : Colors.black87,
                                                ),
                                              ),
                                          ],
                                        ),
                                ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          if (isFront && !_showTranslationFront)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_outlined, color: isDark ? Colors.grey.shade400 : Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tap for definition',
                    style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          Positioned(
            top: 6,
            left: 2,
            child: IconButton(
              tooltip: 'Translate',
              iconSize: iconSize,
              padding: const EdgeInsets.all(6),
              icon: Icon(Icons.translate, size: iconSize, color: isDark ? Colors.tealAccent.shade200 : Colors.tealAccent.shade700),
              onPressed: _toggleTranslation,
            ),
          ),
          Positioned(
            top: 6,
            right: 2,
            child: IconButton(
              tooltip: 'Speak',
              iconSize: iconSize,
              padding: const EdgeInsets.all(6),
              icon: Icon(
                Icons.volume_up,
                size: iconSize,
                color: isFront
                    ? (isDark ? Colors.white : Colors.grey.shade700)
                    : (isDark ? Colors.white : Colors.blue.shade700),
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.20),
                shape: const CircleBorder(),
              ),
              onPressed: isFront
                  ? widget.onSpeakWord
                  : (widget.onSpeakDefinitionAndExample ?? widget.onSpeakExample),
            ),
          ),
          Positioned(
            bottom: 6,
            right: 2,
            child: IconButton(
              tooltip: widget.isLearned ? 'Unmark learned' : 'Mark learned',
              iconSize: iconSize + 2,
              padding: const EdgeInsets.all(6),
              icon: Icon(
                widget.isLearned ? Icons.check_circle : Icons.circle_outlined,
                size: iconSize + 2,
                color: widget.isLearned
                    ? (isDark ? Colors.greenAccent : Colors.lightGreenAccent.shade700)
                    : (isDark ? Colors.white70 : Colors.white),
              ),
              style: IconButton.styleFrom(
                backgroundColor: widget.isLearned
                    ? (isDark ? Colors.green.withValues(alpha: 0.28) : Colors.green.withValues(alpha: 0.3))
                    : Colors.black.withValues(alpha: 0.25),
                shape: const CircleBorder(),
              ),
              onPressed: widget.onToggleLearned,
            ),
          ),
          // Ön yüzde tüm kartı kaplayan GestureDetector kaldırıldı; sadece orta alanı kaplayan ve ikonları engellemeyen bir alan eklendi
          if (isFront && !_showTranslationFront)
            Positioned(
              // İkonlar (üst 56px ve alt learned ikonu ~60px) dışında orta alan
              top: 56,
              left: 16,
              right: 16,
              bottom: 70,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _toggleTranslation,
              ),
            ),
        ],
      ),
    );
  }
}
