// lib/screens/practice_speaking_detail_screen.dart
// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:lingua_chat/models/speaking_models.dart';
import 'package:lingua_chat/repositories/speaking_repository.dart';

class PracticeSpeakingDetailScreen extends StatefulWidget {
  final String promptId;
  const PracticeSpeakingDetailScreen({super.key, required this.promptId});

  @override
  State<PracticeSpeakingDetailScreen> createState() => _PracticeSpeakingDetailScreenState();
}

class _PracticeSpeakingDetailScreenState extends State<PracticeSpeakingDetailScreen> {
  late SpeakingPrompt prompt;
  final _tts = FlutterTts();
  late final stt.SpeechToText _speech;
  bool _sttAvailable = false;
  bool _recording = false;
  String _recognized = '';
  int _currentIndex = 0;
  final List<SpeakingEvaluation> _results = [];
  DateTime? _recordStart;
  String? _enLocaleId; // English locale selection
  // New: live metrics & sound level & auto next
  double _soundLevel = 0.0;
  double _liveSimilarity = 0.0;
  double _liveWpm = 0.0;
  int _liveFillers = 0;
  bool _autoNext = true;
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    prompt = SpeakingRepository.instance.byId(widget.promptId)!;
    _speech = stt.SpeechToText();
    _initEngines();
  }

  Future<void> _initEngines() async {
    _sttAvailable = await _speech.initialize();
    // Find English locales on the device
    try {
      final locales = await _speech.locales();
      // We look for en_US first, otherwise we take any en_*
      _enLocaleId = locales.firstWhere((l) => l.localeId == 'en_US', orElse: () => locales.firstWhere((l)=> l.localeId.startsWith('en'))).localeId;
    } catch (_) {
      _enLocaleId = 'en_US';
    }
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(.9);
    if (mounted) setState(() {});
  }

  Future<void> _playTarget() async {
    final text = prompt.targets[_currentIndex];
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _toggleRecord() async {
    if(!_sttAvailable){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speech recognition is not available.')));
      return;
    }
    if(_recording){
      await _speech.stop();
      _liveTimer?.cancel();
      _recording = false;
      _finalizeEvaluation();
      setState(() {});
    } else {
      _recognized='';
      _liveSimilarity=0; _liveWpm=0; _liveFillers=0; _soundLevel=0;
      _recordStart = DateTime.now();
      _recording = true;
      setState(() {});
      _liveTimer?.cancel();
      _liveTimer = Timer.periodic(const Duration(seconds:1), (_){ _updateLiveMetrics(); });
      await _speech.listen(
        onResult: (r){
          setState(()=> _recognized = r.recognizedWords);
          _updateLiveMetrics(finalResult: r.finalResult);
        },
        listenMode: stt.ListenMode.dictation,
        pauseFor: const Duration(seconds:2),
        partialResults: true,
        localeId: _enLocaleId ?? 'en_US',
        onSoundLevelChange: (level){ setState(()=> _soundLevel = level.clamp(0, 60)); },
      );
    }
  }

  void _updateLiveMetrics({bool finalResult=false}){
    if(_recordStart==null) return;
    final dur = DateTime.now().difference(_recordStart!);
    final totalWords = _recognized.trim().isEmpty? 0 : _recognized.trim().split(RegExp(r'\s+')).length;
    _liveWpm = dur.inSeconds==0? 0.0 : totalWords * 60.0 / dur.inSeconds;
    var target = prompt.targets[_currentIndex];
    var compareRecognized = _recognized;
    if(finalResult) compareRecognized = _postProcessRecognized(target, compareRecognized);
    _liveSimilarity = _similarityRatio(target, compareRecognized)*100;
    _liveFillers = _detectFillers(_recognized).length;
    if(finalResult && _autoNext && _liveSimilarity>=85){
      // auto next with a short delay
      Future.delayed(const Duration(milliseconds:700), (){
        if(mounted && _recording){ _toggleRecord(); _next(); }
      });
    }
  }

  void _finalizeEvaluation(){
    if(_recordStart==null) return;
    final dur = DateTime.now().difference(_recordStart!);
    final target = prompt.targets[_currentIndex];
    final cleaned = _postProcessRecognized(target, _recognized);
    final totalWords = cleaned.trim().isEmpty? 0 : cleaned.trim().split(RegExp(r'\s+')).length;
    final wpm = dur.inSeconds==0? 0.0 : totalWords * 60.0 / dur.inSeconds;
    final similarity = _similarityRatio(target, cleaned) * 100;
    final fillers = _detectFillers(cleaned);
    final eval = SpeakingEvaluation(
      similarity: similarity,
      totalWords: totalWords,
      wordsPerMinute: wpm,
      fillerCount: fillers.length,
      detectedFillers: fillers,
      suggestions: _buildSuggestions(similarity, fillers, target, cleaned),
    );
    if(_results.length <= _currentIndex){ _results.add(eval); } else { _results[_currentIndex] = eval; }
  }

  List<String> _detectFillers(String text){
    final fillers = ['uh','um','erm','like','you know'];
    final lower = text.toLowerCase();
    final found = <String>[];
    for(final f in fillers){
      final reg = RegExp('\\b${RegExp.escape(f)}\\b');
      if(reg.hasMatch(lower)) found.add(f);
    }
    return found;
  }

  List<String> _buildSuggestions(double sim, List<String> fillers, String target, String spoken){
    final tips = <String>[];
    if(sim < 60) tips.add('Try to catch the main words in the target sentence more clearly.');
    if(fillers.isNotEmpty) tips.add('Reduce filler words: ${fillers.join(', ')}');
    if(spoken.split(' ').length < target.split(' ').length*0.6) tips.add('Try to complete the sentence, some parts are missing.');
    if(sim >= 85) tips.add('Great fluency! Focus on rhythm/stress for minor pronunciation differences.');
    if(tips.isEmpty) tips.add('Good job! Try again to be more fluent.');
    return tips;
  }

  double _similarityRatio(String a, String b){
    // Advanced: normalization + token Levenshtein + sequence-based bigram bonus
    final na = _normalizeForCompare(a);
    final nb = _normalizeForCompare(b);
    if(na.isEmpty && nb.isEmpty) return 1;
    if(na == nb) return 1; // exactly the same
    final ta = _tokenize(na);
    final tb = _tokenize(nb);
    if(ta.isEmpty || tb.isEmpty) return 0;

    final lev = _levenshteinTokens(ta, tb);
    final maxLen = ta.length > tb.length ? ta.length : tb.length;
    double base = 1 - (lev / maxLen); // 0..1

    // Bigram (sequence) comparison
    final bigA = _bigrams(ta).toSet();
    final bigB = _bigrams(tb).toSet();
    double orderScore = 0;
    if(bigA.isNotEmpty || bigB.isNotEmpty){
      final inter = bigA.intersection(bigB).length;
      final union = bigA.union(bigB).length;
      orderScore = union==0?0: inter/union; // 0..1
    }

    // Micro-penalty smoothing for very small differences (e.g., single letter / plural s)
    if(base < 1){
      // Last token plural difference (cat vs cats)
      if(ta.length==tb.length){
        int smallEdits=0; for(int i=0;i<ta.length;i++){ if(ta[i]!=tb[i]) smallEdits++; }
        if(smallEdits==1){ base = base + 0.04; }
      }
    }

    double score = (base*0.75 + orderScore*0.25).clamp(0,1);
    if(score >= 0.995) score = 1; // tolerance: accept very small differences as 100
    return score;
  }

  String _normalizeForCompare(String s){
    s = s.toLowerCase();
    const contractions = {
      "i'm":"i am","you're":"you are","it's":"it is","don't":"do not","can't":"can not","won't":"will not","let's":"let us","that's":"that is","what's":"what is","there's":"there is","i've":"i have","we're":"we are","they're":"they are","didn't":"did not","isn't":"is not","aren't":"are not","wasn't":"was not","weren't":"were not","hasn't":"has not","haven't":"have not","shouldn't":"should not","couldn't":"could not","wouldn't":"would not"
    };
    contractions.forEach((k,v){ s = s.replaceAll(k, v); });
    // Additional normalization
    s = s.replaceAll('cannot', 'can not');
    s = s.replaceAll(RegExp(r'\bok\b'), 'okay');
    s = s.replaceAll(RegExp(r"[^a-z\s]"), " ");
    s = s.replaceAll(RegExp(r"\s+"), " ").trim();
    return s;
  }

  // Small post-speech cleanup function
  String _postProcessRecognized(String target, String spoken){
    final tSet = _tokenize(_normalizeForCompare(target)).toSet();
    final toks = _tokenize(_normalizeForCompare(spoken));
    if(toks.isEmpty) return spoken;
    if(toks.length>=2 && toks.last == toks[toks.length-2]){ toks.removeLast(); }
    if(toks.isNotEmpty && toks.last.length<=2 && !tSet.contains(toks.last)){ toks.removeLast(); }
    if(toks.isNotEmpty && !tSet.contains(toks.last) && toks.length>3){ toks.removeLast(); }
    return toks.join(' ');
  }
  List<String> _tokenize(String s)=> s.split(' ').where((e)=>e.isNotEmpty).toList();
  List<String> _bigrams(List<String> t){
    final res=<String>[]; for(int i=0;i<t.length-1;i++){ res.add("${t[i]}\u0001${t[i+1]}"); } return res;
  }
  int _levenshteinTokens(List<String> a, List<String> b){
    final m=a.length, n=b.length; if(m==0) return n; if(n==0) return m;
    final dp = List.generate(m+1, (_)=> List<int>.filled(n+1,0));
    for(int i=0;i<=m;i++) dp[i][0]=i; for(int j=0;j<=n;j++) dp[0][j]=j;
    for(int i=1;i<=m;i++){
      for(int j=1;j<=n;j++){
        final cost = a[i-1]==b[j-1]?0:1;
        dp[i][j] = [
          dp[i-1][j]+1, // delete
          dp[i][j-1]+1, // insert
          dp[i-1][j-1]+cost // substitute
        ].reduce((v,e)=> v<e? v:e);
      }
    }
    return dp[m][n];
  }

  List<_DiffOp> _alignDiff(String target, String spoken){
    final ta = _tokenize(_normalizeForCompare(target));
    final tb = _tokenize(_normalizeForCompare(spoken));
    final m=ta.length, n=tb.length;
    final dp = List.generate(m+1, (_)=> List<int>.filled(n+1,0));
    for(int i=0;i<=m;i++) dp[i][0]=i; for(int j=0;j<=n;j++) dp[0][j]=j;
    for(int i=1;i<=m;i++){
      for(int j=1;j<=n;j++){
        if(ta[i-1]==tb[j-1]){
          dp[i][j]=dp[i-1][j-1];
        } else {
          final del = dp[i-1][j]+1;
          final ins = dp[i][j-1]+1;
          final sub = dp[i-1][j-1]+1;
          dp[i][j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
        }
      }
    }
    int i=m, j=n; final ops=<_DiffOp>[];
    while(i>0 || j>0){
      if(i>0 && j>0 && ta[i-1]==tb[j-1]){ ops.add(_DiffOp('match', ta[i-1])); i--; j--; }
      else if(i>0 && j>0 && dp[i][j]==dp[i-1][j-1]+1){ ops.add(_DiffOp('sub', ta[i-1], repl: tb[j-1])); i--; j--; }
      else if(i>0 && dp[i][j]==dp[i-1][j]+1){ ops.add(_DiffOp('del', ta[i-1])); i--; }
      else if(j>0 && dp[i][j]==dp[i][j-1]+1){ ops.add(_DiffOp('ins', tb[j-1])); j--; }
      else { // safety
        if(i>0){ ops.add(_DiffOp('del', ta[i-1])); i--; } else if(j>0){ ops.add(_DiffOp('ins', tb[j-1])); j--; }
      }
    }
    return ops.reversed.toList();
  }

  InlineSpan _buildWordDiff(){
    final ops = _alignDiff(prompt.targets[_currentIndex], _recognized);
    final spans = <TextSpan>[];
    for(final op in ops){
      switch(op.type){
        case 'match': spans.add(TextSpan(text: '${op.token} ', style: const TextStyle(color: Colors.greenAccent))); break;
        case 'sub': spans.add(TextSpan(text: '${op.token} ', style: const TextStyle(color: Colors.orangeAccent, decoration: TextDecoration.underline))); break;
        case 'del': spans.add(TextSpan(text: '${op.token} ', style: const TextStyle(color: Colors.orangeAccent, decoration: TextDecoration.lineThrough))); break;
        case 'ins': spans.add(TextSpan(text: '${op.token} ', style: const TextStyle(color: Colors.redAccent))); break;
      }
    }
    return TextSpan(children: spans);
  }

  void _next(){
    _finalizeEvaluation();
    if(_currentIndex < prompt.targets.length -1){
      setState((){ _currentIndex++; _recognized=''; _recording=false; });
    } else {
      _showSummary();
    }
  }

  void _prev(){
    if(_currentIndex>0){
      setState(()=> _currentIndex--); }
  }

  void _showSummary(){
    final avgSim = _results.isEmpty? 0 : _results.map((e)=>e.similarity).reduce((a,b)=>a+b)/_results.length;
    showModalBottomSheet(context: context, showDragHandle: true, isScrollControlled: true, builder: (c){
      return Padding(
        padding: const EdgeInsets.fromLTRB(16,12,16,24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height:12),
            Text('Number of Targets: ${prompt.targets.length}'),
            Text('Average Similarity: ${avgSim.toStringAsFixed(1)}%'),
            const Divider(height:24),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (c,i){
                  final r = _results[i];
                  return ListTile(
                    dense: true,
                    title: Text('Sentence ${i+1}・${r.similarity.toStringAsFixed(1)}%'),
                    subtitle: Text(r.suggestions.join(' \n')),
                  );
                },
              ),
            ),
            const SizedBox(height:12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: ()=> Navigator.pop(context),
                child: const Text('Close'),
              ),
            )
          ],
        ),
      );
    });
  }

  @override
  void dispose(){
    _liveTimer?.cancel();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = prompt.targets[_currentIndex];
    final eval = _results.length>_currentIndex? _results[_currentIndex] : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(prompt.title),
        actions: [
          IconButton(onPressed: _playTarget, icon: const Icon(Icons.volume_up_rounded), tooltip: 'Listen'),
          Switch(
            value: _autoNext,
            onChanged: (v)=> setState(()=> _autoNext=v),
            thumbIcon: MaterialStateProperty.resolveWith((s)=> const Icon(Icons.fast_forward, size:16)),
          )
        ],
      ),
      body: Stack(
          children:[
            const _DetailBackdrop(),
            Column(
              children:[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16,12,16,4),
                  child: Row(children:[
                    if(prompt.partnerLine!=null && prompt.mode==SpeakingMode.roleplay)...[
                      const Icon(Icons.person_outline, size:18), const SizedBox(width:6),
                      Expanded(child: Text(prompt.partnerLine!, style: const TextStyle(fontStyle: FontStyle.italic)))
                    ] else
                      Expanded(child: Text(prompt.context, style: const TextStyle(fontStyle: FontStyle.italic)))
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal:16),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          Row(children:[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal:10, vertical:4),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withAlpha(38),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('Target ${_currentIndex+1}/${prompt.targets.length}', style: const TextStyle(color: Colors.blueAccent,fontWeight: FontWeight.w600)),
                            ),
                            const Spacer(),
                            if(eval!=null) Text('${eval.similarity.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, color: eval.similarity>=85? Colors.green: eval.similarity>=60? Colors.orange: Colors.red)),
                          ]),
                          const SizedBox(height:12),
                          Text(target, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height:12),
                          // Sound level visualization
                          SizedBox(
                            height: 28,
                            child: Row(
                              children: List.generate(20, (i){
                                final normalized = _soundLevel/60.0;
                                final activeBars = (normalized*20).clamp(0,20).toInt();
                                final on = i < activeBars;
                                return Expanded(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds:120),
                                    margin: const EdgeInsets.symmetric(horizontal:1),
                                    height: on? (10 + (i%5)*6).toDouble():8,
                                    decoration: BoxDecoration(
                                      color: on? Colors.tealAccent : Colors.grey.withAlpha(64),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height:10),
                          AnimatedContainer(
                            duration: const Duration(milliseconds:300),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _recording? Colors.red.withAlpha(20): Colors.grey.withAlpha(15),
                              border: Border.all(color: _recording? Colors.redAccent: Colors.grey.shade600, width: 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            constraints: const BoxConstraints(minHeight:80),
                            child: _recognized.isEmpty
                                ? Text(_recording? 'Speak and the system will measure in real time...' : 'Start recording and say the sentence.', style: TextStyle(color: Colors.grey.shade400))
                                : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:[
                                Text(_recognized, style: const TextStyle(fontSize:15)),
                                const SizedBox(height:8),
                                RichText(text: _buildWordDiff()),
                              ],
                            ),
                          ),
                          const SizedBox(height:14),
                          // Live metrics
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children:[
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: (_liveSimilarity/100).clamp(0,1),
                                      backgroundColor: Colors.grey.withAlpha(64),
                                      valueColor: AlwaysStoppedAnimation(_liveSimilarity>=85? Colors.greenAccent: _liveSimilarity>=60? Colors.orangeAccent: Colors.redAccent),
                                      minHeight: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width:8),
                                Text('${_liveSimilarity.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ]),
                              const SizedBox(height:6),
                              Wrap(spacing:12, runSpacing:4, children: [
                                _MetricChip(label:'WPM', value: _liveWpm.toStringAsFixed(0)),
                                _MetricChip(label:'Fillers', value: _liveFillers.toString()),
                                _MetricChip(label:'Words', value: (_recognized.trim().isEmpty?0:_recognized.trim().split(RegExp(r'\\s+')).length).toString()),
                              ]),
                            ],
                          ),
                          const SizedBox(height:8),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16,8,16,16),
                  child: Row(
                    children:[
                      IconButton(onPressed: _currentIndex==0? null : _prev, icon: const Icon(Icons.chevron_left_rounded)),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _toggleRecord,
                          style: FilledButton.styleFrom(backgroundColor: _recording? Colors.redAccent: null),
                          icon: Icon(_recording? Icons.stop: Icons.mic),
                          label: Text(_recording? 'Stop' : 'Start Recording'),
                        ),
                      ),
                      const SizedBox(width:12),
                      FilledButton(
                        onPressed: _currentIndex == prompt.targets.length-1? _showSummary : _next,
                        child: Text(_currentIndex == prompt.targets.length-1? 'Summary' : 'Next'),
                      )
                    ],
                  ),
                )
              ],
            ),
          ]
      ),
    );
  }
}

// New helper metric chip widget
class _MetricChip extends StatelessWidget {
  final String label; final String value; const _MetricChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal:10, vertical:6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        border: Border.all(color: Colors.white.withAlpha(30)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(text: TextSpan(style: const TextStyle(fontSize:12), children:[
        TextSpan(text: '$label: ', style: TextStyle(color: Colors.grey.shade400)),
        TextSpan(text: value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ])),
    );
  }
}

// Backdrop: light particles + gradient (kept, performance is low)
class _DetailBackdrop extends StatefulWidget { const _DetailBackdrop(); @override State<_DetailBackdrop> createState()=> _DetailBackdropState(); }
class _DetailBackdropState extends State<_DetailBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c; final _dots = List.generate(28, (i)=> _Dot());
  @override void initState(){super.initState(); _c = AnimationController(vsync:this, duration: const Duration(seconds:14))..repeat();}
  @override void dispose(){_c.dispose(); super.dispose();}
  @override Widget build(BuildContext context){
    return Positioned.fill(
      child: AnimatedBuilder(
        animation:_c,
        builder:(c,_){ return CustomPaint(
          painter: _DotsPainter(_dots, _c.value),
          child: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(colors:[Color(0xFF0D111A), Color(0xFF1C2738)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            ),
          ),
        ); },
      ),
    );
  }
}
class _Dot { final double r = 2 + math.Random().nextDouble()*1.6; final double speed = .25 + math.Random().nextDouble()* .5; final double phase = math.Random().nextDouble()* math.pi*2; final Offset seed = Offset(math.Random().nextDouble(), math.Random().nextDouble()); }
class _DotsPainter extends CustomPainter { final List<_Dot> dots; final double t; _DotsPainter(this.dots, this.t);
@override void paint(Canvas canvas, Size size){ final paint = Paint()..color=Colors.white.withAlpha(25); for(final d in dots){ final dx = (d.seed.dx + math.sin(t*2*math.pi * d.speed + d.phase)*0.015)%1; final dy = (d.seed.dy + math.cos(t*2*math.pi * d.speed + d.phase)*0.015)%1; canvas.drawCircle(Offset(dx*size.width, dy*size.height), d.r, paint); } }
@override bool shouldRepaint(_DotsPainter old)=> old.t!=t; }

class _DiffOp { final String type; final String token; final String? repl; _DiffOp(this.type, this.token, {this.repl}); }
