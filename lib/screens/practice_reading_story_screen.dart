// lib/screens/practice_reading_story_screen.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vocachat/models/reading_models.dart';
import 'package:vocachat/repositories/reading_repository.dart';
import 'package:vocachat/services/translation_service.dart';
import 'package:vocachat/services/audio_service.dart';

class PracticeReadingStoryScreen extends StatefulWidget {
  final String storyId;
  const PracticeReadingStoryScreen({super.key, required this.storyId});

  @override
  State<PracticeReadingStoryScreen> createState() => _PracticeReadingStoryScreenState();
}

class _PracticeReadingStoryScreenState extends State<PracticeReadingStoryScreen> {
  late ReadingStory story;
  String _nativeLanguageCode = 'en';
  final FlutterTts _tts = FlutterTts();
  bool _playingFull = false;
  int _currentSentenceIndex = 0;
  bool _speakingSingle = false;
  bool _initializingTts = true;
  double _speed = 1.0;
  final List<double> _speedOptions = const [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  Timer? _progressTimer;

  final Map<int, String> _translated = {};
  final Set<int> _showTranslation = {};
  final Set<int> _loadingTranslation = {};

  // Reader settings
  double _fontSize = 16;
  bool _serif = true;
  double _lineHeight = 1.55;
  double _pageWidthFactor = 0.85;
  int _eyeProtectionLevel = 0; // 0: Off, 1: Low, 2: Medium

  @override
  void initState() {
    super.initState();
    story = ReadingRepository.instance.byId(widget.storyId)!;
    // Müziği durdur
    AudioService.instance.pauseMusic();
    _initNativeLang();
    _initTts();
  }

  Future<void> _initNativeLang() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final code = (snap.data()?['nativeLanguage'] as String?)?.trim();
        if (code != null && code.isNotEmpty) {
          setState(() => _nativeLanguageCode = code);
        }
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(_mapSpeedToTts(_speed));
    await _tts.awaitSpeakCompletion(true);
    _tts.setCompletionHandler(_onTtsComplete);
    setState(() => _initializingTts = false);
  }

  double _mapSpeedToTts(double v) {
    if (v <= 0.50) return 0.30;
    if (v <= 0.75) return 0.40;
    if (v <= 1.00) return 0.50;
    if (v <= 1.25) return 0.60;
    if (v <= 1.50) return 0.70;
    if (v <= 1.75) return 0.80;
    return 0.90;
  }

  void _onTtsComplete() {
    if (_playingFull) {
      if (_currentSentenceIndex < story.sentences.length - 1) {
        _currentSentenceIndex++;
        _speakCurrentSentenceInSequence();
      } else {
        setState(() { _playingFull = false; });
      }
    } else {
      setState(() { _speakingSingle = false; });
    }
  }

  Future<void> _speakSentence(int index) async {
    if (_initializingTts) return;
    await _tts.stop();
    setState(() { _speakingSingle = true; _playingFull = false; _currentSentenceIndex = index; });
    await _tts.setSpeechRate(_mapSpeedToTts(_speed));
    _tts.speak(story.sentences[index]);
  }

  Future<void> _toggleFullPlayback() async {
    if (_initializingTts) return;
    if (_playingFull) {
      await _tts.stop();
      _progressTimer?.cancel();
      setState(() { _playingFull = false; });
    } else {
      await _tts.stop();
      setState(() { _speakingSingle = false; _playingFull = true; });
      _speakCurrentSentenceInSequence();
    }
  }

  Future<void> _speakCurrentSentenceInSequence() async {
    await _tts.setSpeechRate(_mapSpeedToTts(_speed));
    _tts.speak(story.sentences[_currentSentenceIndex]);
    setState(() {});
  }

  Future<void> _changeSpeed(double newSpeed) async {
    _speed = newSpeed;
    await _tts.setSpeechRate(_mapSpeedToTts(_speed));
    if (_playingFull) {
      await _tts.stop();
      _speakCurrentSentenceInSequence();
    } else if (_speakingSingle) {
      await _tts.stop();
      _speakSentence(_currentSentenceIndex);
    }
    setState(() {});
  }

  void _openSpeedSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              const Text('Reading Speed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _speedOptions.length,
                  itemBuilder: (c, i) {
                    final s = _speedOptions[i];
                    final selected = s == _speed;
                    return ListTile(
                      leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off),
                      title: Text('${s}x'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _changeSpeed(s);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onLongPressSentence(int index) async {
    if (_nativeLanguageCode == 'en') {
      setState(() { _showTranslation.contains(index) ? _showTranslation.remove(index) : _showTranslation.add(index); });
      return;
    }
    if (_translated.containsKey(index)) {
      setState(() { _showTranslation.contains(index) ? _showTranslation.remove(index) : _showTranslation.add(index); });
      return;
    }
    if (_loadingTranslation.contains(index)) return;
    setState(() { _loadingTranslation.add(index); });
    try {
      try { await TranslationService.instance.ensureReady(_nativeLanguageCode); } catch (_) {}
      final sent = story.sentences[index];
      final tr = await TranslationService.instance.translateFromEnglish(sent, _nativeLanguageCode);
      _translated[index] = tr;
      _showTranslation.add(index);
    } finally {
      if (mounted) setState(() { _loadingTranslation.remove(index); });
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _tts.stop();
    // Müziği tekrar başlat
    if (AudioService.instance.isMusicEnabled) {
      AudioService.instance.playMusic();
    }
    super.dispose();
  }

  // Sepia colors
  Color get _backgroundColor => const Color(0xFFEEE8DD);
  Color get _pageColor => const Color(0xFFF8F3EA);
  Color get _foregroundColor => const Color(0xFF3E3428);
  Color get _accentColor => const Color(0xFF8D5B2E);
  Color get _borderColor => const Color(0xFFE1D5C5);

  // Eye protection overlay
  Color? get _eyeProtectionOverlay {
    switch (_eyeProtectionLevel) {
      case 1: return const Color(0xFFFFF4E0).withValues(alpha: 0.3);
      case 2: return const Color(0xFFFFE8C0).withValues(alpha: 0.5);
      default: return null;
    }
  }

  TextStyle _sentenceTextStyle(bool highlight) {
    final baseFamily = _serif ? 'Georgia' : null;
    return TextStyle(
      fontSize: _fontSize,
      height: _lineHeight,
      fontFamily: baseFamily,
      fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
      color: _foregroundColor,
      decoration: highlight ? TextDecoration.underline : TextDecoration.none,
      decorationColor: _accentColor.withValues(alpha: 0.7),
      decorationThickness: 2,
    );
  }

  TextStyle _translationTextStyle() => TextStyle(
    fontSize: (_fontSize - 2).clamp(10, 40),
    height: 1.4,
    fontStyle: FontStyle.italic,
    color: _accentColor.withValues(alpha: 0.9),
    fontFamily: _serif ? 'Georgia' : null,
  );

  void _openReaderSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          void refresh(VoidCallback fn){ setSheet(fn); setState(fn); }
          Widget sectionTitle(String txt) => Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
            child: Text(txt.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          );
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded),
                      const SizedBox(width: 12),
                      const Text('Reader Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),

                  // Typography Section
                  sectionTitle('Typography'),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: _pageColor,
                          borderRadius: BorderRadius.circular(16)
                      ),
                      child: Column(
                        children: [
                          _SettingRow(
                            label: 'Font',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _FontChip(label: 'Serif', isSelected: _serif, onTap: () => refresh(()=> _serif = true)),
                                const SizedBox(width: 8),
                                _FontChip(label: 'Sans', isSelected: !_serif, onTap: () => refresh(()=> _serif = false)),
                              ],
                            ),
                          ),
                          _SettingRow(
                            label: 'Size',
                            icon: Icons.format_size,
                            child: Slider(
                              value: _fontSize, min: 12, max: 26, divisions: 14,
                              onChanged: (v)=>refresh(()=>_fontSize = v),
                            ),
                          ),
                          _SettingRow(
                            label: 'Line Spacing',
                            icon: Icons.format_line_spacing,
                            child: Slider(
                              value: _lineHeight, min: 1.25, max: 2.0, divisions: 15,
                              onChanged: (v)=>refresh(()=>_lineHeight = double.parse(v.toStringAsFixed(2))),
                            ),
                          ),
                        ],
                      )
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSentences = story.sentences.length;
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: _foregroundColor,
        elevation: 0,
        title: Text(story.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          // Eye Protection button
          IconButton(
            onPressed: () {
              setState(() {
                _eyeProtectionLevel = (_eyeProtectionLevel + 1) % 3;
              });
            },
            icon: Icon(
              _eyeProtectionLevel == 0 ? Icons.remove_red_eye_outlined : Icons.remove_red_eye,
              color: _eyeProtectionLevel > 0 ? _accentColor : _foregroundColor,
            ),
            tooltip: _eyeProtectionLevel == 0 ? 'Eye Protection: Off' : 'Eye Protection: Level $_eyeProtectionLevel',
          ),
          IconButton(onPressed: _openReaderSettings, icon: const Icon(Icons.tune_rounded)),
        ],
      ),
      body: Column(
        children: [
          if (story.description != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Text(story.description!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: _foregroundColor.withValues(alpha: 0.7))),
            ),
          Expanded(
            child: Stack(
              children: [
                _BookView(
                  story: story,
                  playingFull: _playingFull,
                  currentSentenceIndex: _currentSentenceIndex,
                  translated: _translated,
                  showTranslation: _showTranslation,
                  loadingTranslation: _loadingTranslation,
                  onTapSentence: (i) => _speakSentence(i),
                  onLongPressSentence: (i) => _onLongPressSentence(i),
                  sentenceStyleBuilder: (highlight)=>_sentenceTextStyle(highlight),
                  translationStyle: _translationTextStyle(),
                  backgroundColor: _backgroundColor,
                  pageColor: _pageColor,
                  borderColor: _borderColor,
                  pageWidthFactor: _pageWidthFactor,
                ),
                if (_eyeProtectionOverlay != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: _eyeProtectionOverlay,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(totalSentences),
    );
  }

  Widget _buildBottomBar(int totalSentences) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: _pageColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2)),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _toggleFullPlayback,
                  icon: Icon(
                    _playingFull ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                    size: 40,
                    color: _accentColor,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: _accentColor,
                          thumbColor: _accentColor,
                          inactiveTrackColor: _accentColor.withValues(alpha: 0.25),
                        ),
                        child: Slider(
                          value: _currentSentenceIndex.toDouble().clamp(0, (totalSentences - 1).toDouble()),
                          min: 0,
                          max: (totalSentences - 1).toDouble().clamp(0, double.infinity),
                          divisions: totalSentences > 1 ? totalSentences - 1 : null,
                          label: 'Sentence ${_currentSentenceIndex + 1}/$totalSentences',
                          onChanged: totalSentences <= 1 ? null : (v) {
                            setState(() { _currentSentenceIndex = v.round(); });
                          },
                          onChangeEnd: totalSentences <= 1 ? null : (v) {
                            if (_playingFull) {
                              _tts.stop();
                              _speakCurrentSentenceInSequence();
                            }
                          },
                        ),
                      ),
                      Text('Sentence ${_currentSentenceIndex + 1} / $totalSentences', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _foregroundColor)),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _openSpeedSheet,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text('${_speed}x', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: _foregroundColor)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.touch_app, size: 16, color: _foregroundColor.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Tap: Read aloud  •  Long press: Translate (${_nativeLanguageCode.toUpperCase()})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _foregroundColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookView extends StatelessWidget {
  final ReadingStory story;
  final bool playingFull;
  final int currentSentenceIndex;
  final Map<int,String> translated;
  final Set<int> showTranslation;
  final Set<int> loadingTranslation;
  final ValueChanged<int> onTapSentence;
  final ValueChanged<int> onLongPressSentence;
  final TextStyle Function(bool highlight) sentenceStyleBuilder;
  final TextStyle translationStyle;
  final Color backgroundColor;
  final Color pageColor;
  final Color borderColor;
  final double pageWidthFactor;

  const _BookView({
    required this.story,
    required this.playingFull,
    required this.currentSentenceIndex,
    required this.translated,
    required this.showTranslation,
    required this.loadingTranslation,
    required this.onTapSentence,
    required this.onLongPressSentence,
    required this.sentenceStyleBuilder,
    required this.translationStyle,
    required this.backgroundColor,
    required this.pageColor,
    required this.borderColor,
    required this.pageWidthFactor,
  });

  @override
  Widget build(BuildContext context) {
    final paragraphs = story.content.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    final allSentences = story.sentences;
    int sentenceCursor = 0;
    final spans = <InlineSpan>[];

    for (var pIndex = 0; pIndex < paragraphs.length; pIndex++) {
      final paragraph = paragraphs[pIndex];
      final sentList = paragraph.replaceAll('\n', ' ').split(RegExp(r'(?<=[.!?])\s+')).where((e) => e.trim().isNotEmpty).toList();
      bool firstSentence = true;
      for (final sent in sentList) {
        final globalIndex = sentenceCursor;
        final highlight = playingFull && currentSentenceIndex == globalIndex;
        final sentenceText = sent.trim() + ' ';

        final textWidget = GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => onTapSentence(globalIndex),
          onLongPress: () => onLongPressSentence(globalIndex),
          child: Padding(
            padding: EdgeInsets.only(left: firstSentence ? 18 : 0),
            child: Text(
              sentenceText,
              style: sentenceStyleBuilder(highlight),
              softWrap: true,
            ),
          ),
        );
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: textWidget,
        ));
        if (loadingTranslation.contains(globalIndex)) {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 18),
              child: Text('… (translating)', style: translationStyle),
            ),
          ));
        } else if (showTranslation.contains(globalIndex)) {
          final tr = translated[globalIndex] ?? allSentences[globalIndex];
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 18),
              child: Text(tr, style: translationStyle),
            ),
          ));
        }
        sentenceCursor++;
        firstSentence = false;
      }
      if (pIndex < paragraphs.length - 1) {
        spans.add(const WidgetSpan(
          child: SizedBox(height: 20),
        ));
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 680 * pageWidthFactor + 0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 140),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: pageColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0,8)),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0,1)),
                ],
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 32, 30, 60),
                child: RichText(
                  text: TextSpan(style: sentenceStyleBuilder(false), children: spans),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper widgets for Reader Settings
class _SettingRow extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Widget child;
  const _SettingRow({required this.label, this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 8)
        ],
        Text(label),
        Expanded(child: child),
      ],
    );
  }
}

class _FontChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FontChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor.withValues(alpha: 0.5))
        ),
        child: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}

