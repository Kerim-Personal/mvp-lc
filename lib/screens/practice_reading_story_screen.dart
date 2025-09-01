// lib/screens/practice_reading_story_screen.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lingua_chat/models/reading_models.dart';
import 'package:lingua_chat/repositories/reading_repository.dart';
import 'package:lingua_chat/services/translation_service.dart';

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
  int _currentSentenceIndex = 0; // full playback ilerlemesi
  bool _speakingSingle = false; // tek cümle modu
  bool _initializingTts = true;
  double _speed = 1.0; // varsayılan görünür hız
  final List<double> _speedOptions = const [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  Timer? _progressTimer; // cümle süresi tahmini için (fallback)

  final Map<int, String> _translated = {}; // cümle index -> çeviri
  final Set<int> _showTranslation = {}; // görüntülenen çeviri cümle index seti
  final Set<int> _loadingTranslation = {}; // çeviri yükleniyor

  double _fontSize = 16; // kitap font boyutu
  bool _serif = true;
  _ReaderTheme _readerTheme = _ReaderTheme.sepia;
  double _lineHeight = 1.55; // yeni: satır aralığı
  double _pageWidthFactor = 0.85; // yeni: sayfa genişliği 0.6 - 1.0

  @override
  void initState() {
    super.initState();
    story = ReadingRepository.instance.byId(widget.storyId)!;
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
      // yoksay
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
    // Kullanıcı hızlarını daha doğal TTS hızlarına eşle.
    // Büyük hızlarda bile aşırı robotik okunmayı engellemek için tavan 0.9.
    if (v <= 0.50) return 0.30;   // 0.5x: Çok yavaş
    if (v <= 0.75) return 0.40;   // 0.75x: Yavaş
    if (v <= 1.00) return 0.50;   // 1.0x: Doğal
    if (v <= 1.25) return 0.60;   // 1.25x: Orta hızlı
    if (v <= 1.50) return 0.70;   // 1.5x: Hızlı
    if (v <= 1.75) return 0.80;   // 1.75x: Çok hızlı
    return 0.90;                  // 2.0x: Maks (kısıtlı)
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
    // devam eden oynatma yeniden başlat
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
      backgroundColor: _readerTheme.pageColor,
      barrierColor: Colors.black.withValues(alpha: .35),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Theme(
          data: _buildReaderTheme(context),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                Text('Okuma Hızı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _readerTheme.foreground)),
                const SizedBox(height: 4),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _speedOptions.length,
                    itemBuilder: (c, i) {
                      final s = _speedOptions[i];
                      final selected = s == _speed;
                      return ListTile(
                        leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? _readerTheme.accent : _readerTheme.foreground.withValues(alpha: .6)),
                        title: Text('${s}x', style: TextStyle(color: _readerTheme.foreground)),
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
    super.dispose();
  }

  Color _levelColor(ReadingLevel l) => switch (l) {
        ReadingLevel.beginner => Colors.green,
        ReadingLevel.intermediate => Colors.orange,
        ReadingLevel.advanced => Colors.red,
      };

  TextStyle _sentenceTextStyle(bool highlight) {
    final baseFamily = _serif ? 'Georgia' : null;
    return TextStyle(
      fontSize: _fontSize,
      height: _lineHeight,
      fontFamily: baseFamily,
      fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
      color: _readerTheme.foreground,
      decoration: highlight ? TextDecoration.underline : TextDecoration.none,
      decorationColor: _readerTheme.accent.withValues(alpha: .7),
      decorationThickness: 2,
    );
  }
  TextStyle _translationTextStyle() => TextStyle(
    fontSize: (_fontSize - 2).clamp(10, 40),
    height: 1.4,
    fontStyle: FontStyle.italic,
    color: _readerTheme.accent.withValues(alpha: .9),
    fontFamily: _serif ? 'Georgia' : null,
  );

  void _openReaderSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _readerTheme.pageColor,
      barrierColor: Colors.black.withValues(alpha: .35),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return Theme(
          data: _buildReaderTheme(context),
          child: StatefulBuilder(builder: (ctx, setSheet) {
            void refresh(VoidCallback fn){ setSheet(fn); setState(fn); }
            Widget sectionTitle(String txt) => Padding(
              padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
              child: Text(txt, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: .4, color: _readerTheme.accent)),
            );
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: LayoutBuilder(builder: (ctx, cons) {
                  final themeBoxWidth = (cons.maxWidth - 20) / 4; // 4 sütun
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.menu_book_outlined, color: _readerTheme.accent),
                            const SizedBox(width: 8),
                            Text('Okuyucu Ayarları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _readerTheme.foreground)),
                            const Spacer(),
                            IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: _readerTheme.foreground)),
                          ],
                        ),
                        sectionTitle('TEMA'),
                        Wrap(
                          spacing: 5,
                          runSpacing: 8,
                          children: _ReaderTheme.values.map((t){
                            final sel = t == _readerTheme;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: themeBoxWidth.clamp(72, 120),
                              height: 70,
                              decoration: BoxDecoration(
                                color: t.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: sel ? t.accent : Colors.grey.withValues(alpha:.35), width: sel?2:1),
                                boxShadow: [if(sel) BoxShadow(color: t.accent.withValues(alpha:.25), blurRadius: 10, offset: const Offset(0,4))],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: ()=>refresh(()=>_readerTheme = t),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children:[
                                        CircleAvatar(radius: 6, backgroundColor: t.accent),
                                        const SizedBox(height:6),
                                        FittedBox(child: Text(t.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.foreground))),
                                        if(sel) const Icon(Icons.check_circle, size: 14)
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        sectionTitle('YAZI TİPİ'),
                        ToggleButtons(
                          isSelected: [_serif, !_serif],
                          borderRadius: BorderRadius.circular(12),
                          onPressed: (i)=>refresh(()=>_serif = (i==0)),
                          children: const [
                            Padding(padding: EdgeInsets.symmetric(horizontal:16, vertical:8), child: Text('Serif')),
                            Padding(padding: EdgeInsets.symmetric(horizontal:16, vertical:8), child: Text('Sans')),
                          ],
                        ),
                        sectionTitle('BOYUT'),
                        Row(
                          children: [
                            Text('${_fontSize.toStringAsFixed(0)} pt', style: TextStyle(color:_readerTheme.foreground,fontWeight: FontWeight.w600)),
                            Expanded(
                              child: Slider(
                                value: _fontSize,
                                min: 12,
                                max: 26,
                                divisions: 14,
                                label: _fontSize.toStringAsFixed(0),
                                onChanged: (v)=>refresh(()=>_fontSize = v),
                              ),
                            ),
                          ],
                        ),
                        sectionTitle('SATIR ARALIĞI'),
                        Row(
                          children: [
                            Text(_lineHeight.toStringAsFixed(2), style: TextStyle(color:_readerTheme.foreground,fontWeight: FontWeight.w600)),
                            Expanded(
                              child: Slider(
                                value: _lineHeight,
                                min: 1.25,
                                max: 2.0,
                                divisions: 15,
                                label: _lineHeight.toStringAsFixed(2),
                                onChanged: (v)=>refresh(()=>_lineHeight = double.parse(v.toStringAsFixed(2))),
                              ),
                            ),
                          ],
                        ),
                        sectionTitle('SAYFA GENİŞLİĞİ'),
                        Row(
                          children: [
                            Text('${(_pageWidthFactor*100).round()}%', style: TextStyle(color:_readerTheme.foreground,fontWeight: FontWeight.w600)),
                            Expanded(
                              child: Slider(
                                value: _pageWidthFactor,
                                min: 0.6,
                                max: 1.0,
                                divisions: 8,
                                label: '${(_pageWidthFactor*100).round()}%',
                                onChanged: (v)=>refresh(()=>_pageWidthFactor = double.parse(v.toStringAsFixed(2))),
                              ),
                            ),
                          ],
                        ),
                        sectionTitle('ÖNİZLEME'),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _readerTheme.pageColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _readerTheme.borderColor),
                          ),
                          child: Text(
                            'The morning light filtered softly through the curtains, painting quiet golden shapes across the wooden floor. Long basılı tut: çeviri.',
                            style: _sentenceTextStyle(false),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }

  bool get _isDarkTheme => _readerTheme == _ReaderTheme.dark;

  ThemeData _buildReaderTheme(BuildContext context) {
    final base = Theme.of(context);
    final fg = _readerTheme.foreground;
    final bg = _readerTheme.background;
    final page = _readerTheme.pageColor;
    final accent = _readerTheme.accent;
    return base.copyWith(
      brightness: _isDarkTheme ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        brightness: _isDarkTheme ? Brightness.dark : Brightness.light,
        primary: accent,
        secondary: accent,
        surface: page,
        onSurface: fg,
        onPrimary: Colors.white,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: accent,
        thumbColor: accent,
        inactiveTrackColor: accent.withValues(alpha: .25),
      ),
      iconTheme: base.iconTheme.copyWith(color: fg),
      textTheme: base.textTheme.apply(
        bodyColor: fg,
        displayColor: fg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSentences = story.sentences.length;
    final progress = totalSentences <= 1 ? 0.0 : _currentSentenceIndex / (totalSentences - 1);
    return Theme(
      data: _buildReaderTheme(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(story.title),
          actions: [
            IconButton(onPressed: _openReaderSettings, icon: const Icon(Icons.tune)),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _levelColor(story.level).withValues(alpha: .18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  story.level.label,
                  style: TextStyle(color: _levelColor(story.level), fontWeight: FontWeight.w600),
                ),
              ),
            )
          ],
        ),
        body: Column(
          children: [
            if (story.description != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Text(story.description!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
              ),
            Expanded(
              child: _BookView(
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
                readerTheme: _readerTheme,
                pageWidthFactor: _pageWidthFactor,
              ),
            ),
          ],
        ),
        bottomSheet: _buildBottomBar(progress, totalSentences),
      ),
    );
  }

  Widget _buildBottomBar(double progress, int totalSentences) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 12, offset: const Offset(0, -2)),
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
                    color: Colors.deepPurple,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Slider(
                        value: _currentSentenceIndex.toDouble().clamp(0, (totalSentences - 1).toDouble()),
                        min: 0,
                        max: (totalSentences - 1).toDouble().clamp(0, double.infinity),
                        divisions: totalSentences > 1 ? totalSentences - 1 : null,
                        label: 'Cümle ${_currentSentenceIndex + 1}/$totalSentences',
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
                      Text('Cümle ${_currentSentenceIndex + 1} / $totalSentences', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _openSpeedSheet,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text('${_speed}x', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.touch_app, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('Tek dokun: Sesli oku  •  Uzun bas: Çeviri (${_nativeLanguageCode.toUpperCase()})',
                      style: Theme.of(context).textTheme.bodySmall),
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
  final _ReaderTheme readerTheme;
  final double pageWidthFactor; // yeni
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
    required this.readerTheme,
    required this.pageWidthFactor,
  });

  @override
  Widget build(BuildContext context) {
    final paragraphs = story.paragraphs;
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
              child: Text('… (çeviri)', style: translationStyle),
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
        color: readerTheme.background,
        image: readerTheme == _ReaderTheme.paper ? const DecorationImage(
          image: AssetImage('assets/practice/reading_bg.jpg'),
          fit: BoxFit.cover,
          opacity: .04,
        ) : null,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 680 * pageWidthFactor + 0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 140),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: readerTheme.pageColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 24, offset: const Offset(0,8)),
                  BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 4, offset: const Offset(0,1)),
                ],
                border: Border.all(color: readerTheme.borderColor, width: 1),
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

enum _ReaderTheme { light, sepia, dark, paper }
extension _ReaderThemeX on _ReaderTheme {
  String get label => switch (this) {
    _ReaderTheme.light => 'Açık',
    _ReaderTheme.sepia => 'Sepya',
    _ReaderTheme.dark => 'Koyu',
    _ReaderTheme.paper => 'Kağıt',
  };
  Color get background => switch (this) {
    _ReaderTheme.light => const Color(0xFFF5F6F8),
    _ReaderTheme.sepia => const Color(0xFFEEE8DD),
    _ReaderTheme.dark => const Color(0xFF111315),
    _ReaderTheme.paper => const Color(0xFFEDE9E3),
  };
  Color get pageColor => switch (this) {
    _ReaderTheme.light => const Color(0xFFFFFFFF),
    _ReaderTheme.sepia => const Color(0xFFF8F3EA),
    _ReaderTheme.dark => const Color(0xFF1B1E21),
    _ReaderTheme.paper => const Color(0xFFFDFBF7),
  };
  Color get foreground => switch (this) {
    _ReaderTheme.light => const Color(0xFF1E1F21),
    _ReaderTheme.sepia => const Color(0xFF3E3428),
    _ReaderTheme.dark => const Color(0xFFE4E6E8),
    _ReaderTheme.paper => const Color(0xFF242424),
  };
  Color get accent => switch (this) {
    _ReaderTheme.light => const Color(0xFF3F51B5),
    _ReaderTheme.sepia => const Color(0xFF8D5B2E),
    _ReaderTheme.dark => const Color(0xFF90CAF9),
    _ReaderTheme.paper => const Color(0xFF4E6E5D),
  };
  Color get borderColor => switch (this) {
    _ReaderTheme.light => const Color(0xFFE2E5EA),
    _ReaderTheme.sepia => const Color(0xFFE1D5C5),
    _ReaderTheme.dark => const Color(0xFF2A2F33),
    _ReaderTheme.paper => const Color(0xFFE3DDD3),
  };
}
