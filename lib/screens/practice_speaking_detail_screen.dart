// lib/screens/practice_speaking_detail_screen.dart
// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:vocachat/models/speaking_models.dart';
import 'package:vocachat/repositories/speaking_repository.dart';

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
  String? _enLocaleId;
  double _liveSimilarity = 0.0;
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
    try {
      final locales = await _speech.locales();
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
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition is not available.'))
        );
      }
      return;
    }

    if(_recording){
      // Kaydı durdur
      setState(() => _recording = false);
      _liveTimer?.cancel();
      await _speech.stop();
      _finalizeEvaluation();
      if(mounted) setState(() {});
    } else {
      // Kaydı başlat
      setState(() {
        _recognized = '';
        _liveSimilarity = 0;
        _recordStart = DateTime.now();
        _recording = true;
      });

      _liveTimer?.cancel();
      _liveTimer = Timer.periodic(const Duration(seconds:1), (_) {
        if(mounted) _updateLiveMetrics();
      });

      await _speech.listen(
        onResult: (r){
          if(mounted) {
            setState(() => _recognized = r.recognizedWords);
            _updateLiveMetrics(finalResult: r.finalResult);
          }
        },
        listenMode: stt.ListenMode.dictation,
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: _enLocaleId ?? 'en_US',
        cancelOnError: true,
        listenFor: const Duration(seconds: 30),
      );
    }
  }

  void _updateLiveMetrics({bool finalResult=false}){
    if(_recordStart == null || !mounted) return;
    var target = prompt.targets[_currentIndex];
    var compareRecognized = _recognized;
    if(finalResult) compareRecognized = _postProcessRecognized(target, compareRecognized);
    final newSimilarity = _similarityRatio(target, compareRecognized) * 100;
    if(mounted) {
      setState(() => _liveSimilarity = newSimilarity);
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
    if(sim < 60) tips.add('Try to catch the main words more clearly.');
    if(fillers.isNotEmpty) tips.add('Reduce filler words: ${fillers.join(', ')}');
    if(spoken.split(' ').length < target.split(' ').length*0.6) tips.add('Try to complete the sentence.');
    if(sim >= 85) tips.add('Great fluency!');
    if(tips.isEmpty) tips.add('Good job! Try again to be more fluent.');
    return tips;
  }

  double _similarityRatio(String a, String b){
    final na = _normalizeForCompare(a);
    final nb = _normalizeForCompare(b);
    if(na.isEmpty && nb.isEmpty) return 1;
    if(na == nb) return 1;
    final ta = _tokenize(na);
    final tb = _tokenize(nb);
    if(ta.isEmpty || tb.isEmpty) return 0;

    final lev = _levenshteinTokens(ta, tb);
    final maxLen = ta.length > tb.length ? ta.length : tb.length;
    double base = 1 - (lev / maxLen);

    final bigA = _bigrams(ta).toSet();
    final bigB = _bigrams(tb).toSet();
    double orderScore = 0;
    if(bigA.isNotEmpty || bigB.isNotEmpty){
      final inter = bigA.intersection(bigB).length;
      final union = bigA.union(bigB).length;
      orderScore = union==0?0: inter/union;
    }

    if(base < 1){
      if(ta.length==tb.length){
        int smallEdits=0;
        for(int i=0;i<ta.length;i++){
          if(ta[i]!=tb[i]) smallEdits++;
        }
        if(smallEdits==1){ base = base + 0.04; }
      }
    }

    double score = (base*0.75 + orderScore*0.25).clamp(0,1);
    if(score >= 0.995) score = 1;
    return score;
  }

  String _normalizeForCompare(String s){
    s = s.toLowerCase();
    const contractions = {
      "i'm":"i am","you're":"you are","it's":"it is","don't":"do not","can't":"can not","won't":"will not","let's":"let us","that's":"that is","what's":"what is","there's":"there is","i've":"i have","we're":"we are","they're":"they are","didn't":"did not","isn't":"is not","aren't":"are not","wasn't":"was not","weren't":"were not","hasn't":"has not","haven't":"have not","shouldn't":"should not","couldn't":"could not","wouldn't":"would not"
    };
    contractions.forEach((k,v){ s = s.replaceAll(k, v); });
    s = s.replaceAll('cannot', 'can not');
    s = s.replaceAll(RegExp(r'\bok\b'), 'okay');
    s = s.replaceAll(RegExp(r"[^a-z\s]"), " ");
    s = s.replaceAll(RegExp(r"\s+"), " ").trim();
    return s;
  }

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
    final res=<String>[];
    for(int i=0;i<t.length-1;i++){
      res.add("${t[i]}\u0001${t[i+1]}");
    }
    return res;
  }

  int _levenshteinTokens(List<String> a, List<String> b){
    final m=a.length, n=b.length;
    if(m==0) return n;
    if(n==0) return m;
    final dp = List.generate(m+1, (_)=> List<int>.filled(n+1,0));
    for(int i=0;i<=m;i++) dp[i][0]=i;
    for(int j=0;j<=n;j++) dp[0][j]=j;
    for(int i=1;i<=m;i++){
      for(int j=1;j<=n;j++){
        final cost = a[i-1]==b[j-1]?0:1;
        dp[i][j] = [
          dp[i-1][j]+1,
          dp[i][j-1]+1,
          dp[i-1][j-1]+cost
        ].reduce((v,e)=> v<e? v:e);
      }
    }
    return dp[m][n];
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
      setState(()=> _currentIndex--);
    }
  }

  void _showSummary(){
    final avgSim = _results.isEmpty? 0 : _results.map((e)=>e.similarity).reduce((a,b)=>a+b)/_results.length;

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Practice Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: avgSim >= 85 ? Colors.green.shade50 : avgSim >= 60 ? Colors.orange.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    avgSim >= 85 ? Icons.star : avgSim >= 60 ? Icons.thumb_up : Icons.info_outline,
                    color: avgSim >= 85 ? Colors.green : avgSim >= 60 ? Colors.orange : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Average Score', style: TextStyle(fontSize: 12)),
                      Text(
                        '${avgSim.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: avgSim >= 85 ? Colors.green : avgSim >= 60 ? Colors.orange : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height:16),
            Text('${prompt.targets.length} sentences completed'),
            if(_results.isNotEmpty) ...[
              const SizedBox(height:8),
              Text(
                avgSim >= 85
                  ? 'Excellent work! Your pronunciation is great.'
                  : avgSim >= 60
                    ? 'Good job! Keep practicing to improve.'
                    : 'Keep trying! Practice makes perfect.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose(){
    _liveTimer?.cancel();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = prompt.targets[_currentIndex];
    final eval = _results.length>_currentIndex? _results[_currentIndex] : null;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(prompt.title),
        actions: [
          IconButton(
            onPressed: _playTarget,
            icon: const Icon(Icons.volume_up_rounded),
            tooltip: 'Listen',
          ),
        ],
      ),
      body: Column(
        children:[
          // Context bilgisi
          if(prompt.context.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                prompt.context,
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Target cümlesi kartı
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Text(
                        'Sentence ${_currentIndex+1}/${prompt.targets.length}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      if(eval!=null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal:8, vertical:4),
                          decoration: BoxDecoration(
                            color: eval.similarity>=85? Colors.green : eval.similarity>=60? Colors.orange : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${eval.similarity.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height:12),
                  Text(
                    target,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height:16),

          // Kayıt alanı
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Row(
                    children: [
                      Icon(
                        _recording ? Icons.mic : Icons.mic_none,
                        color: _recording ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _recording ? 'Recording...' : 'Your speech',
                        style: TextStyle(
                          color: _recording ? Colors.red : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height:12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    constraints: const BoxConstraints(minHeight:80),
                    child: _recognized.isEmpty
                      ? Text(
                          _recording
                            ? 'Speak now...'
                            : 'Press record and say the sentence',
                          style: TextStyle(color: Colors.grey.shade400),
                        )
                      : Text(
                          _recognized,
                          style: const TextStyle(fontSize:16),
                        ),
                  ),
                  if(_liveSimilarity > 0) ...[
                    const SizedBox(height:12),
                    LinearProgressIndicator(
                      value: (_liveSimilarity/100).clamp(0,1),
                      backgroundColor: Colors.grey.shade200,
                      color: _liveSimilarity>=85? Colors.green : _liveSimilarity>=60? Colors.orange : Colors.red,
                    ),
                    const SizedBox(height:4),
                    Text(
                      'Similarity: ${_liveSimilarity.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Spacer(),

          // Butonlar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children:[
                if(_currentIndex > 0)
                  OutlinedButton(
                    onPressed: _prev,
                    child: const Icon(Icons.arrow_back),
                  ),
                if(_currentIndex > 0) const SizedBox(width:8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _toggleRecord,
                    style: FilledButton.styleFrom(
                      backgroundColor: _recording? Colors.red : null,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(_recording? Icons.stop: Icons.mic),
                    label: Text(_recording? 'Stop' : 'Record'),
                  ),
                ),
                const SizedBox(width:8),
                FilledButton(
                  onPressed: _currentIndex == prompt.targets.length-1? _showSummary : _next,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                  child: Text(_currentIndex == prompt.targets.length-1? 'Finish' : 'Next'),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

