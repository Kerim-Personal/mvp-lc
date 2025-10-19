// lib/screens/practice_listening_detail_screen.dart
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vocachat/models/listening_models.dart';
import 'package:vocachat/repositories/listening_repository.dart';
import 'package:vocachat/services/audio_service.dart';
import 'package:vocachat/services/listening_progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PracticeListeningDetailScreen extends StatefulWidget {
  final String exerciseId;
  const PracticeListeningDetailScreen({super.key, required this.exerciseId});

  @override
  State<PracticeListeningDetailScreen> createState() => _PracticeListeningDetailScreenState();
}

class _PracticeListeningDetailScreenState extends State<PracticeListeningDetailScreen> {
  late ListeningExercise exercise;
  // Audio
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _posSub;
  // TTS
  final FlutterTts _tts = FlutterTts();
  bool _isTts = false;
  bool _ttsPlaying = false;
  Timer? _tickTimer;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false; // combined state
  double _speed = 1.0;
  final List<double> _speedOptions = const [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  bool _showTranscript = false; // now off by default
  final Map<String, String> _answers = {}; // questionId -> answer/optionId
  bool _submitted = false;
  int _score = 0;

  // TTS word synchronization
  List<_WordBoundary> _wordBoundaries = [];
  int _activeWordIndex = -1; // only used in TTS mode
  bool _ttsProgressSupported = false;

  // --- VOICE / ACCENT SELECTION ---
  List<dynamic> _voices = [];
  Map<String, dynamic>? _selectedVoice;
  String? _selectedLanguage; // fallback
  static const _prefsVoiceKey = 'listening_tts_voice';
  static const _prefsLangKey = 'listening_tts_lang';
  bool _loadingVoices = false;

  @override
  void initState() {
    super.initState();
    exercise = ListeningRepository.instance.byId(widget.exerciseId)!;
    // Stop background music
    AudioService.instance.pauseMusic();
    _initMedia();
  }

  Future<void> _initMedia() async {
    _isTts = exercise.audioUrl.startsWith('tts:');
    if (_isTts) {
      // Duration: from timings if available, otherwise estimate ~0.55s per word from transcript
      if (exercise.timings.isNotEmpty) {
        _duration = Duration(milliseconds: exercise.timings.last.endMs + 200);
      } else {
        final estMs = (exercise.transcript.split(' ').length * 550).toInt();
        _duration = Duration(milliseconds: estMs);
      }
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(_mapSpeedToTts(_speed));
      await _tts.awaitSpeakCompletion(true);
      await _loadPersistedVoice();
      await _loadVoices();
      _applySelectedVoice();
      _prepareWordBoundaries();
      _configureProgressHandler();
      _tts.setCompletionHandler(() {
        _stopTtsTick();
        setState(() {
          _ttsPlaying = false;
          _playing = false;
          _position = _duration;
          _activeWordIndex = -1;
        });
      });
    } else {
      final source = exercise.audioUrl.startsWith('asset:')
          ? AssetSource(exercise.audioUrl.replaceFirst('asset:', ''))
          : UrlSource(exercise.audioUrl);
      await _player.setSource(source);
      _duration = Duration(milliseconds: exercise.durationMs);
      _posSub = _player.onPositionChanged.listen((d) {
        setState(() => _position = d);
      });
      _player.onPlayerStateChanged.listen((s) {
        setState(() => _playing = s == PlayerState.playing);
      });
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _player.dispose();
    _stopTtsTick();
    _tts.stop();
    // Let the music start again
    if (AudioService.instance.isMusicEnabled) {
      AudioService.instance.playMusic();
    }
    super.dispose();
  }

  void _toggle() async {
    if (_isTts) {
      if (_ttsPlaying) {
        await _tts.stop();
        _stopTtsTick();
        setState(() { _ttsPlaying = false; _playing = false; });
      } else {
        _startTts();
      }
    } else {
      if (_playing) {
        await _player.pause();
      } else {
        await _player.setPlaybackRate(_speed);
        await _player.resume();
      }
    }
  }

  void _startTts() async {
    await _tts.setSpeechRate(_mapSpeedToTts(_speed));
    _position = Duration.zero;
    setState(() { _ttsPlaying = true; _playing = true; _activeWordIndex = -1; });
    _tts.speak(exercise.transcript);
    if (!_ttsProgressSupported) {
      // Fallback: if no progress handler, use a rough timer
      _startTtsTick();
    }
  }

  void _startTtsTick() {
    _stopTtsTick();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (!_ttsPlaying) { t.cancel(); return; }
      final inc = (120 * _speed).toInt();
      final nextMs = _position.inMilliseconds + inc;
      if (nextMs >= _duration.inMilliseconds) {
        _stopTtsTick();
        setState(() { _position = _duration; _ttsPlaying = false; _playing = false; });
      } else {
        setState(() { _position = Duration(milliseconds: nextMs); });
      }
    });
  }

  void _stopTtsTick() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  void _prepareWordBoundaries() {
    final text = exercise.transcript;
    final regex = RegExp(r"[A-Za-z']+");
    final matches = regex.allMatches(text);
    _wordBoundaries = matches.map((m) => _WordBoundary(word: m.group(0)!, start: m.start, end: m.end)).toList();
  }

  void _configureProgressHandler() {
    try {
      _tts.setProgressHandler((String text, int start, int end, String word) {
        // start offset -> find word index
        if (_wordBoundaries.isNotEmpty) {
          int idx = _binarySearchWord(start);
          if (idx != _activeWordIndex) {
            setState(() { _activeWordIndex = idx; });
          }
        }
        // Approximate position: character ratio
        final ratio = text.isEmpty ? 0.0 : start / text.length;
        final posMs = (ratio * _duration.inMilliseconds).clamp(0, _duration.inMilliseconds).toInt();
        setState(() { _position = Duration(milliseconds: posMs); });
      });
      _ttsProgressSupported = true;
    } catch (_) {
      _ttsProgressSupported = false;
    }
  }

  int _binarySearchWord(int charIndex) {
    int lo = 0, hi = _wordBoundaries.length - 1, ans = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final wb = _wordBoundaries[mid];
      if (charIndex < wb.start) {
        hi = mid - 1;
      } else if (charIndex >= wb.end) {
        lo = mid + 1;
      } else {
        return mid;
      }
      ans = hi;
    }
    return ans;
  }

  void _seekRelative(int ms) {
    if (_isTts) return; // no TTS seek for now
    final target = _position + Duration(milliseconds: ms);
    _player.seek(Duration(milliseconds: target.inMilliseconds.clamp(0, _duration.inMilliseconds)));
  }

  Future<void> _setSpeed(double s) async {
    setState(() => _speed = s);
    if (_isTts) {
      if (_ttsPlaying) {
        await _tts.stop();
        _startTts();
      } else {
        await _tts.setSpeechRate(_mapSpeedToTts(_speed));
      }
    } else {
      if (_playing) await _player.setPlaybackRate(_speed.clamp(0.5, 2.0));
    }
  }

  // --- VOICE / ACCENT SELECTION ---
  Future<void> _loadPersistedVoice() async {
    final prefs = await SharedPreferences.getInstance();
    final voiceJson = prefs.getString(_prefsVoiceKey);
    final lang = prefs.getString(_prefsLangKey);
    if (voiceJson != null) {
      try {
        _selectedVoice = Map<String, dynamic>.from(Uri.splitQueryString(voiceJson));
      } catch (_) {}
    }
    _selectedLanguage = lang;
  }

  Future<void> _persistVoice() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedVoice != null) {
      // Simple serialization (query string form)
      final map = _selectedVoice!;
      final serialized = map.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent('${e.value}')}').join('&');
      await prefs.setString(_prefsVoiceKey, serialized);
      await prefs.setString(_prefsLangKey, _selectedLanguage ?? '');
    }
  }

  Future<void> _loadVoices() async {
    if (_loadingVoices) return;
    setState(() => _loadingVoices = true);
    try {
      final voices = await _tts.getVoices; // All platform voices
      if (!mounted) return;
      voices.sort((a, b) {
        final la = (a['locale'] ?? a['language'] ?? '').toString();
        final lb = (b['locale'] ?? b['language'] ?? '').toString();
        final na = (a['name'] ?? '').toString();
        final nb = (b['name'] ?? '').toString();
        final c = la.compareTo(lb);
        return c != 0 ? c : na.compareTo(nb);
      });
      // Yalnızca Amerikan ve Britanya İngilizcesi (en-US, en-GB) aksanlarını bırak
      final filtered = voices.where((v) {
        final raw = (v['locale'] ?? v['language'] ?? '').toString();
        final loc = raw.replaceAll('_', '-').toLowerCase();
        return loc.startsWith('en-us') || loc.startsWith('en-gb');
      }).toList();

      setState(() { _voices = filtered; });
      if (_voices.isNotEmpty) {
        if (_selectedVoice == null) {
          _selectedVoice = Map<String,dynamic>.from(_voices.first.map((k,v)=>MapEntry(k.toString(), v)));
          _applySelectedVoice();
          await _persistVoice();
        } else {
          final selName = (_selectedVoice!['name'] ?? '').toString();
          final selLocale = (_selectedVoice!['locale'] ?? _selectedVoice!['language'] ?? '').toString();
          final stillExists = _voices.any((v) => (v['name'] ?? '').toString() == selName && ((v['locale'] ?? v['language'] ?? '').toString() == selLocale));
          if (!stillExists) {
            _selectedVoice = Map<String,dynamic>.from(_voices.first.map((k,v)=>MapEntry(k.toString(), v)));
            _applySelectedVoice();
            await _persistVoice();
          }
        }
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingVoices = false);
    }
  }

  void _applySelectedVoice() {
    if (_selectedVoice != null) {
      final locale = _selectedVoice!['locale'] ?? _selectedVoice!['language'] ?? _selectedLanguage;
      if (locale is String) {
        _tts.setLanguage(locale);
        _selectedLanguage = locale;
      }
      try {
        final name = _selectedVoice!['name'];
        if (name is String && _selectedLanguage != null) {
          _tts.setVoice({'name': name, 'locale': _selectedLanguage ?? 'en-US'});
        }
      } catch (_) {}
      _tts.setPitch(1.0); // default pitch
    } else if (_selectedLanguage != null) {
      _tts.setLanguage(_selectedLanguage!);
      _tts.setPitch(1.0);
    }
  }

  void _openVoicePicker() async {
    if (_voices.isEmpty && !_loadingVoices) {
      await _loadVoices();
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final currentName = _selectedVoice?['name'];
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over),
                    const SizedBox(width: 8),
                    const Text('Select Accent / Voice'),
                    const Spacer(),
                    if (_loadingVoices) const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
              ),
              Expanded(
                child: _voices.isEmpty
                    ? const Center(child: Text('Could not retrieve voice list.'))
                    : ListView.builder(
                  itemCount: _voices.length,
                  itemBuilder: (c, i) {
                    final v = _voices[i] as Map;
                    final name = (v['name'] ?? 'Unknown').toString();
                    final locale = (v['locale'] ?? v['language'] ?? '').toString();
                    final selected = name == currentName;
                    return ListTile(
                      title: Text(name),
                      subtitle: Text(locale),
                      trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
                      onTap: () async {
                        setState(() {
                          _selectedVoice = Map<String, dynamic>.from(v.map((k, val) => MapEntry(k.toString(), val)));
                        });
                        _applySelectedVoice();
                        await _persistVoice();
                        Navigator.pop(context);
                        if (_ttsPlaying) {
                          await _tts.stop();
                          _startTts();
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
              const Text('Playback Speed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _speedOptions.length,
                  itemBuilder: (c, i) {
                    final s = _speedOptions[i];
                    final selected = s == _speed;
                    return ListTile(
                      leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? Theme.of(context).colorScheme.primary : null),
                      title: Text('${s}x'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _setSpeed(s);
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

  void _submit() async {
    int correct = 0;
    for (final q in exercise.questions) {
      switch (q.type) {
        case ListeningQuestionType.multipleChoice:
          if (_answers[q.id] == q.correctOptionId) correct++;
          break;
        case ListeningQuestionType.gapFill:
        case ListeningQuestionType.dictation:
          final user = (_answers[q.id] ?? '').trim().toLowerCase();
          final exp = (q.answer ?? '').trim().toLowerCase();
          if (user == exp) correct++;
          break;
      }
    }
    setState(() {
      _submitted = true;
      _score = correct;
    });
    await ListeningProgressService.instance.recordAttempt(
      id: exercise.id,
      score: correct,
      total: exercise.questions.length,
    );
  }

  int get _answeredCount => _answers.length;

  Color _levelColor(ListeningLevel l) => switch (l) {
    ListeningLevel.beginner => Colors.green,
    ListeningLevel.intermediate => Colors.orange,
    ListeningLevel.advanced => Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = exercise.questions.length;
    final answered = _answeredCount.clamp(0, total);
    final progress = total == 0 ? 0.0 : answered / total;
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(exercise.title),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary.withValues(alpha: 0.25), theme.colorScheme.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          InkWell(
            onTap: _openSpeedSheet,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text('${_speed}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          if (_isTts)
            IconButton(
              tooltip: 'Accent / Voice',
              onPressed: _openVoicePicker,
              icon: const Icon(Icons.record_voice_over),
            ),
          IconButton(
            tooltip: _showTranscript ? 'Hide transcript' : 'Show transcript',
            onPressed: _toggleTranscript,
            icon: Icon(_showTranscript ? Icons.visibility_off : Icons.visibility),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _submitted ? 1.0 : progress,
                minHeight: 6,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(_submitted ? Colors.green : theme.colorScheme.primary),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                    theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Column(
            children: [
              _buildPlayerBar(theme),
              Expanded(
                child: _TranscriptAndQuestionsList(
                  exercise: exercise,
                  showTranscript: _showTranscript,
                  position: _position.inMilliseconds,
                  activeWordIndex: _isTts ? _activeWordIndex : null,
                  ttsMode: _isTts,
                  answers: _answers,
                  submitted: _submitted,
                  onAnswer: (qId, val) {
                    if (_submitted) return;
                    setState(() => _answers[qId] = val);
                  },
                ),
              ),
              _buildBottom(theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _levelColor(exercise.level).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(exercise.level.label, style: TextStyle(color: _levelColor(exercise.level), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Text(exercise.accent, style: theme.textTheme.bodySmall),
              const Spacer(),
              Text(_fmt(_position)),
              const Text(' / '),
              Text(_fmt(_duration)),
            ],
          ),
          Slider(
            min: 0,
            max: _duration.inMilliseconds.toDouble(),
            value: (_position.inMilliseconds).clamp(0, _duration.inMilliseconds).toDouble(),
            onChanged: (v) {
              if (_isTts) return; // TTS seek disabled
              _player.seek(Duration(milliseconds: v.toInt()));
            },
          ),
          Row(
            children: [
              if (!_isTts) IconButton(onPressed: () => _seekRelative(-5000), icon: const Icon(Icons.replay_5)),
              IconButton(
                onPressed: _toggle,
                icon: Icon(_playing ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 40),
              ),
              if (!_isTts) IconButton(onPressed: () => _seekRelative(5000), icon: const Icon(Icons.forward_5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottom(ThemeData theme) {
    final total = exercise.questions.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: _submitted
                ? Text('Score: $_score / $total', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))
                : Text('Questions: $total', style: theme.textTheme.bodyMedium),
          ),
          ElevatedButton.icon(
            onPressed: _submitted ? null : _submit,
            icon: const Icon(Icons.check),
            label: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _toggleTranscript() => setState(() => _showTranscript = !_showTranscript);
  double _mapSpeedToTts(double s) {
    // Same scale for listening TTS (0.5–2.0 visible -> 0.30–0.90 actual)
    if (s <= 0.50) return 0.30;
    if (s <= 0.75) return 0.40;
    if (s <= 1.00) return 0.50;
    if (s <= 1.25) return 0.60;
    if (s <= 1.50) return 0.70;
    if (s <= 1.75) return 0.80;
    return 0.90;
  }
  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _TranscriptAndQuestionsList extends StatelessWidget {
  final ListeningExercise exercise;
  final bool showTranscript;
  final int position;
  final int? activeWordIndex;
  final bool ttsMode;
  final Map<String,String> answers;
  final bool submitted;
  final void Function(String qId, String value) onAnswer;
  const _TranscriptAndQuestionsList({
    required this.exercise,
    required this.showTranscript,
    required this.position,
    required this.activeWordIndex,
    required this.ttsMode,
    required this.answers,
    required this.submitted,
    required this.onAnswer,
  });
  @override
  Widget build(BuildContext context) {
    final total = exercise.questions.length;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), // Adjusted bottom padding
      itemCount: exercise.questions.length + (showTranscript ? 1 : 0) + 1,
      itemBuilder: (c, index) {
        if (index == 0) {
          return _HeaderInfo(exercise: exercise);
        }
        if (showTranscript) {
          if (index == 1) {
            return _GlassCard(
              child: _TranscriptView(
                exercise: exercise,
                position: position,
                activeWordIndex: activeWordIndex,
                ttsMode: ttsMode,
              ),
            );
          }
          final qIndex = index - 2;
          final q = exercise.questions[qIndex];
          return _QuestionCard(
            index: qIndex,
            total: total,
            question: q,
            answer: answers[q.id],
            onAnswer: (val) => onAnswer(q.id, val),
            submitted: submitted,
          );
        } else {
          final qIndex = index - 1;
          final q = exercise.questions[qIndex];
          return _QuestionCard(
            index: qIndex,
            total: total,
            question: q,
            answer: answers[q.id],
            onAnswer: (val) => onAnswer(q.id, val),
            submitted: submitted,
          );
        }
      },
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15), width: 1.2),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface.withValues(alpha: 0.85),
            theme.colorScheme.surface.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: child,
        ),
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  final ListeningExercise exercise;
  const _HeaderInfo({required this.exercise});
  Color _levelColor(ListeningLevel l){
    return switch(l){
      ListeningLevel.beginner => Colors.green,
      ListeningLevel.intermediate => Colors.orange,
      ListeningLevel.advanced => Colors.red,
    };}
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.headphones, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(exercise.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(label: exercise.category, icon: Icons.category),
              _Tag(label: exercise.accent, icon: Icons.public),
              _Tag(label: exercise.level.label, color: _levelColor(exercise.level), icon: Icons.flag),
            ],
          ),
          if (exercise.description != null) ...[
            const SizedBox(height: 12),
            Text(exercise.description!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label; final IconData icon; final Color? color;
  const _Tag({required this.label, required this.icon, this.color});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16, color: c), const SizedBox(width: 4), Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w600))],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final ListeningQuestion question;
  final String? answer;
  final bool submitted;
  final ValueChanged<String> onAnswer;
  final int index; final int total;
  const _QuestionCard({
    required this.index,
    required this.total,
    required this.question,
    required this.answer,
    required this.onAnswer,
    required this.submitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qNumber = index + 1;
    final answered = (answer != null && answer!.trim().isNotEmpty);
    IconData typeIcon; Color accent;
    switch (question.type) {
      case ListeningQuestionType.multipleChoice:
        typeIcon = Icons.list_alt; accent = theme.colorScheme.primary;
        break;
      case ListeningQuestionType.gapFill:
        typeIcon = Icons.edit_note; accent = Colors.teal;
        break;
      case ListeningQuestionType.dictation:
        typeIcon = Icons.keyboard; accent = Colors.purple;
        break;
    }
    Widget content;
    switch (question.type) {
      case ListeningQuestionType.multipleChoice:
        content = Column(
          children: question.options.map((o) {
            final selected = answer == o.id;
            final correct = submitted && o.id == question.correctOptionId;
            final wrong = submitted && selected && !correct;
            Color base = correct ? Colors.green : wrong ? Colors.red : accent;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: base.withValues(alpha: selected ? 0.9 : 0.3), width: 1.4),
                color: selected ? base.withValues(alpha: 0.12) : theme.colorScheme.surface.withValues(alpha: 0.6),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: submitted ? null : () => onAnswer(o.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: base),
                      const SizedBox(width: 10),
                      Expanded(child: Text(o.text, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: selected ? FontWeight.w600 : FontWeight.w400))),
                      if (correct) const Icon(Icons.check_circle, color: Colors.green),
                      if (wrong) const Icon(Icons.cancel, color: Colors.red),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
        break;
      case ListeningQuestionType.gapFill:
      case ListeningQuestionType.dictation:
        final correct = submitted && (answer ?? '').trim().toLowerCase() == (question.answer ?? '').toLowerCase();
        content = TextField(
          enabled: !submitted,
          decoration: InputDecoration(
            filled: true,
            fillColor: accent.withValues(alpha: 0.06),
            labelText: question.type == ListeningQuestionType.gapFill ? 'Answer' : 'Dictation',
            prefixIcon: Icon(typeIcon, color: accent),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            suffixIcon: submitted
                ? Icon(correct ? Icons.check_circle : Icons.cancel, color: correct ? Colors.green : Colors.red)
                : (answered ? Icon(Icons.check, color: accent) : null),
          ),
          onChanged: onAnswer,
          controller: TextEditingController(text: answer ?? ''),
        );
        break;
    }
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [accent.withValues(alpha: 0.85), accent.withValues(alpha: 0.55)]),
                ),
                child: Icon(typeIcon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Question $qNumber / $total', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: submitted
                    ? Icon(Icons.lock, key: const ValueKey('locked'), color: theme.colorScheme.outline)
                    : answered
                    ? Icon(Icons.check_circle, key: const ValueKey('done'), color: Colors.green)
                    : Icon(Icons.circle_outlined, key: const ValueKey('pending'), color: theme.colorScheme.outline),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(question.prompt, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }
}

class _TranscriptView extends StatelessWidget {
  final ListeningExercise exercise;
  final int position; // ms
  final int? activeWordIndex; // TTS word index
  final bool ttsMode;
  const _TranscriptView({required this.exercise, required this.position, this.activeWordIndex, required this.ttsMode});
  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;
    if (ttsMode) {
      final spans = <InlineSpan>[];
      final regex = RegExp(r"[A-Za-z']+|[^A-Za-z']+");
      int wordCounter = 0;
      for (final m in regex.allMatches(exercise.transcript)) {
        final segment = m.group(0)!;
        final isWord = RegExp(r"[A-Za-z']+").hasMatch(segment);
        bool active = false;
        if (isWord) {
          active = (wordCounter == activeWordIndex);
          wordCounter++;
        }
        spans.add(TextSpan(
          text: segment,
          style: TextStyle(
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Theme.of(context).colorScheme.primary : textStyle?.color,
            backgroundColor: active ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12) : null,
          ),
        ));
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(4),
        child: RichText(text: TextSpan(style: textStyle, children: spans)),
      );
    } else {
      final children = <InlineSpan>[];
      for (final w in exercise.timings) {
        final active = position >= w.startMs && position <= w.endMs;
        children.add(TextSpan(
          text: w.word + ' ',
          style: TextStyle(
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Theme.of(context).colorScheme.primary : textStyle?.color,
          ),
        ));
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(4),
        child: RichText(text: TextSpan(style: textStyle, children: children)),
      );
    }
  }
}

class _WordBoundary {
  final String word;
  final int start;
  final int end;
  _WordBoundary({required this.word, required this.start, required this.end});
}