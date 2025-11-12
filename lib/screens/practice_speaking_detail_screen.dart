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

    // 1. Yaygın yazım varyasyonlarını normalize et
    s = _normalizeSpellingVariations(s);

    // 2. Sayıları, zamanı, yüzdeleri normalize et
    s = _normalizeNumbers(s);
    s = _normalizeTime(s);
    s = _normalizePercentages(s);
    s = _normalizeOrdinals(s);
    s = _normalizeCurrency(s);

    // 3. Tüm kısaltmaları genişlet
    s = _expandContractions(s);

    // 4. Yaygın alternatif ifadeleri normalize et
    s = _normalizeCommonPhrases(s);

    // 5. Noktalama ve özel karakterleri temizle
    s = s.replaceAll(RegExp(r"[^a-z\s]"), " ");
    s = s.replaceAll(RegExp(r"\s+"), " ").trim();

    return s;
  }

  String _normalizeSpellingVariations(String s) {
    // İngilizce-Amerikan yazım farklılıkları
    const spellingMap = {
      'colour': 'color', 'favourite': 'favorite', 'centre': 'center',
      'theatre': 'theater', 'metres': 'meters', 'kilometres': 'kilometers',
      'realise': 'realize', 'organise': 'organize', 'analyse': 'analyze',
      'programme': 'program', 'catalogue': 'catalog', 'dialogue': 'dialog',
    };

    spellingMap.forEach((uk, us) {
      s = s.replaceAll(RegExp('\\b$uk\\b'), us);
    });

    return s;
  }

  String _expandContractions(String s) {
    // Kapsamlı kısaltma listesi
    const contractions = {
      // Temel kısaltmalar
      "i'm": "i am", "you're": "you are", "he's": "he is", "she's": "she is",
      "it's": "it is", "we're": "we are", "they're": "they are",
      "that's": "that is", "what's": "what is", "who's": "who is",
      "where's": "where is", "when's": "when is", "why's": "why is",
      "how's": "how is", "there's": "there is", "here's": "here is",

      // Would/Had kısaltmaları
      "i'd": "i would", "you'd": "you would", "he'd": "he would",
      "she'd": "she would", "we'd": "we would", "they'd": "they would",
      "that'd": "that would", "what'd": "what would", "who'd": "who would",

      // Will kısaltmaları
      "i'll": "i will", "you'll": "you will", "he'll": "he will",
      "she'll": "she will", "we'll": "we will", "they'll": "they will",
      "that'll": "that will", "it'll": "it will", "there'll": "there will",

      // Have kısaltmaları
      "i've": "i have", "you've": "you have", "we've": "we have",
      "they've": "they have", "could've": "could have", "should've": "should have",
      "would've": "would have", "might've": "might have", "must've": "must have",

      // Not kısaltmaları
      "don't": "do not", "doesn't": "does not", "didn't": "did not",
      "won't": "will not", "wouldn't": "would not", "can't": "can not",
      "cannot": "can not", "couldn't": "could not", "shouldn't": "should not",
      "mightn't": "might not", "mustn't": "must not",
      "isn't": "is not", "aren't": "are not", "wasn't": "was not",
      "weren't": "were not", "hasn't": "has not", "haven't": "have not",
      "hadn't": "had not", "ain't": "am not",

      // Let's özel durumu
      "let's": "let us",

      // Informal konuşma
      "gonna": "going to", "wanna": "want to", "gotta": "got to",
      "hafta": "have to", "needa": "need to", "oughta": "ought to",
      "kinda": "kind of", "sorta": "sort of", "lotta": "lot of",
      "outta": "out of", "dunno": "do not know", "lemme": "let me",
      "gimme": "give me", "betcha": "bet you", "gotcha": "got you",
      "y'all": "you all", "c'mon": "come on", "'cause": "because",
      "cos": "because", "cuz": "because",
    };

    contractions.forEach((short, full) {
      s = s.replaceAll(RegExp('\\b$short\\b'), full);
    });

    return s;
  }

  String _normalizeNumbers(String s) {
    const numberMap = {
      '0': 'zero', '1': 'one', '2': 'two', '3': 'three', '4': 'four',
      '5': 'five', '6': 'six', '7': 'seven', '8': 'eight', '9': 'nine',
      '10': 'ten', '11': 'eleven', '12': 'twelve', '13': 'thirteen',
      '14': 'fourteen', '15': 'fifteen', '16': 'sixteen', '17': 'seventeen',
      '18': 'eighteen', '19': 'nineteen', '20': 'twenty', '21': 'twenty one',
      '22': 'twenty two', '23': 'twenty three', '24': 'twenty four',
      '25': 'twenty five', '30': 'thirty', '40': 'forty', '50': 'fifty',
      '60': 'sixty', '70': 'seventy', '80': 'eighty', '90': 'ninety',
      '100': 'one hundred', '1000': 'one thousand',
    };

    // Telefon numarası pattern'lerini yakala ve her rakamı ayrı ayrı çevir
    // 555-1234 veya 555 1234 veya 5551234 -> five five five one two three four
    s = s.replaceAllMapped(RegExp(r'\b(\d[\d\s\-\.]*\d|\d)\b'), (match) {
      final numStr = match.group(0)!;

      // Eğer sadece tire/nokta/boşluk içeriyorsa, her rakamı ayrı ayrı çevir (telefon numarası)
      if (numStr.contains(RegExp(r'[\-\.\s]')) || numStr.length >= 7) {
        // Tüm rakamları çıkar
        final digits = numStr.replaceAll(RegExp(r'[^\d]'), '');

        // Telefon numarası gibi uzun sayılar (7+ rakam) -> her rakamı ayrı oku
        if (digits.length >= 7) {
          return digits.split('').map((d) => numberMap[d]!).join(' ');
        }

        // Kısa formatlar için de her rakamı ayrı oku
        return digits.split('').map((d) => numberMap[d]!).join(' ');
      }

      // Normal sayılar için standart dönüşüm
      final num = int.tryParse(numStr);
      if (num == null) return numStr;

      // Özel sayıları kontrol et
      if (numberMap.containsKey(numStr)) {
        return numberMap[numStr]!;
      }

      // 100+ sayılar için (örn: 150 -> one hundred fifty)
      if (num >= 100 && num < 1000) {
        final hundreds = num ~/ 100;
        final rest = num % 100;
        String result = '${numberMap[hundreds.toString()]} hundred';
        if (rest > 0) {
          if (numberMap.containsKey(rest.toString())) {
            result += ' ${numberMap[rest.toString()]}';
          } else if (rest < 100 && rest > 20) {
            final tens = (rest ~/ 10) * 10;
            final ones = rest % 10;
            result += ' ${numberMap[tens.toString()]}';
            if (ones > 0) result += ' ${numberMap[ones.toString()]}';
          }
        }
        return result;
      }

      // 21-99 arası sayıları çevir (örn: 25 -> twenty five)
      if (num >= 21 && num < 100) {
        final tens = (num ~/ 10) * 10;
        final ones = num % 10;
        String result = numberMap[tens.toString()]!;
        if (ones > 0) result += ' ${numberMap[ones.toString()]}';
        return result;
      }

      // 0-20 arası ve özel sayılar
      if (numberMap.containsKey(num.toString())) {
        return numberMap[num.toString()]!;
      }

      return numStr;
    });

    // Yazılı sayıları normalize et (twenty-one -> twenty one)
    s = s.replaceAll(RegExp(r'(twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety)-'), r'\1 ');

    // "number" kelimesinden sonra gelen "is" yi normalize et
    s = s.replaceAll(RegExp(r'\bnumber\s+is\s+'), 'number ');

    return s;
  }

  String _normalizeTime(String s) {
    // 10:30 -> ten thirty
    // 3:45 PM -> three forty five
    s = s.replaceAllMapped(RegExp(r'\b(\d{1,2}):(\d{2})\s*(am|pm|a\.m\.|p\.m\.)?\b'), (match) {
      final hour = match.group(1)!;
      final minute = match.group(2)!;
      final period = match.group(3);

      String result = _numberToWord(int.parse(hour));

      if (minute == '00') {
        result += ' o clock';
      } else if (minute == '15') {
        result += ' fifteen';
      } else if (minute == '30') {
        result += ' thirty';
      } else if (minute == '45') {
        result += ' forty five';
      } else {
        result += ' ${_numberToWord(int.parse(minute))}';
      }

      if (period != null) {
        final p = period.toLowerCase().replaceAll('.', '');
        result += ' $p';
      }

      return result;
    });

    // "o'clock" varyasyonları
    s = s.replaceAll(RegExp(r"\bo'clock\b"), 'o clock');
    s = s.replaceAll(RegExp(r'\boclock\b'), 'o clock');

    // AM/PM normalleştirme
    s = s.replaceAll(RegExp(r'\ba\.m\.\b'), 'am');
    s = s.replaceAll(RegExp(r'\bp\.m\.\b'), 'pm');
    s = s.replaceAll(RegExp(r'\bin the morning\b'), '');
    s = s.replaceAll(RegExp(r'\bin the afternoon\b'), '');
    s = s.replaceAll(RegExp(r'\bin the evening\b'), '');

    return s;
  }

  String _normalizePercentages(String s) {
    // 50% -> fifty percent
    // 3.5% -> three point five percent
    s = s.replaceAllMapped(RegExp(r'\b(\d+(?:\.\d+)?)\s*%'), (match) {
      final num = match.group(1)!;
      if (num.contains('.')) {
        final parts = num.split('.');
        return '${_numberToWord(int.parse(parts[0]))} point ${parts[1].split('').map((d) => _numberToWord(int.parse(d))).join(' ')} percent';
      }
      return '${_numberToWord(int.parse(num))} percent';
    });

    return s;
  }

  String _normalizeOrdinals(String s) {
    // 1st -> first, 2nd -> second, 3rd -> third, 4th -> fourth
    const ordinalMap = {
      '1st': 'first', '2nd': 'second', '3rd': 'third', '4th': 'fourth',
      '5th': 'fifth', '6th': 'sixth', '7th': 'seventh', '8th': 'eighth',
      '9th': 'ninth', '10th': 'tenth', '11th': 'eleventh', '12th': 'twelfth',
      '13th': 'thirteenth', '20th': 'twentieth', '21st': 'twenty first',
      '22nd': 'twenty second', '23rd': 'twenty third', '30th': 'thirtieth',
    };

    ordinalMap.forEach((num, word) {
      s = s.replaceAll(RegExp('\\b$num\\b'), word);
    });

    return s;
  }

  String _normalizeCurrency(String s) {
    // $50 -> fifty dollars
    // £20 -> twenty pounds
    // €10 -> ten euros

    // Dolar
    s = s.replaceAllMapped(RegExp(r'\$(\d+(?:\.\d+)?)'), (match) {
      final amount = match.group(1)!;
      if (amount.contains('.')) {
        final parts = amount.split('.');
        return '${_numberToWord(int.parse(parts[0]))} dollars and ${_numberToWord(int.parse(parts[1]))} cents';
      }
      return '${_numberToWord(int.parse(amount))} dollars';
    });

    // Euro
    s = s.replaceAllMapped(RegExp(r'€(\d+(?:\.\d+)?)'), (match) {
      final amount = match.group(1)!;
      return '${_numberToWord(int.parse(amount.split('.')[0]))} euros';
    });

    // Pound
    s = s.replaceAllMapped(RegExp(r'£(\d+(?:\.\d+)?)'), (match) {
      final amount = match.group(1)!;
      return '${_numberToWord(int.parse(amount.split('.')[0]))} pounds';
    });

    // "dollars" varyasyonları
    s = s.replaceAll(RegExp(r'\bdollar\b'), 'dollars');
    s = s.replaceAll(RegExp(r'\beuro\b'), 'euros');
    s = s.replaceAll(RegExp(r'\bpound\b'), 'pounds');

    return s;
  }

  String _normalizeCommonPhrases(String s) {
    // Yaygın alternatif ifadeler
    const phraseMap = {
      'ok': 'okay', 'alright': 'all right', 'yeah': 'yes',
      'yep': 'yes', 'nope': 'no', 'nah': 'no',
      'u': 'you', 'ur': 'your', 'r': 'are',
      'thru': 'through', 'tho': 'though', 'til': 'until',
      'cause': 'because', 'bout': 'about',
      'em': 'them', 'im': 'i am',
      'ive': 'i have', 'youve': 'you have',
      'thats': 'that is', 'whats': 'what is',
      'isnt': 'is not', 'arent': 'are not',
      'wasnt': 'was not', 'werent': 'were not',
      'hasnt': 'has not', 'havent': 'have not',
      'hadnt': 'had not', 'wont': 'will not',
      'wouldnt': 'would not', 'couldnt': 'could not',
      'shouldnt': 'should not', 'cant': 'can not',
      'didnt': 'did not', 'doesnt': 'does not',
      'dont': 'do not', 'mightnt': 'might not',
    };

    phraseMap.forEach((alt, standard) {
      s = s.replaceAll(RegExp('\\b$alt\\b'), standard);
    });

    // Çoklu boşlukları normalize et
    s = s.replaceAll(RegExp(r'\s+'), ' ');

    return s;
  }

  String _numberToWord(int n) {
    const words = {
      0: 'zero', 1: 'one', 2: 'two', 3: 'three', 4: 'four',
      5: 'five', 6: 'six', 7: 'seven', 8: 'eight', 9: 'nine',
      10: 'ten', 11: 'eleven', 12: 'twelve', 13: 'thirteen',
      14: 'fourteen', 15: 'fifteen', 16: 'sixteen', 17: 'seventeen',
      18: 'eighteen', 19: 'nineteen', 20: 'twenty', 30: 'thirty',
      40: 'forty', 50: 'fifty', 60: 'sixty', 70: 'seventy',
      80: 'eighty', 90: 'ninety',
    };

    if (words.containsKey(n)) return words[n]!;

    if (n < 100) {
      final tens = (n ~/ 10) * 10;
      final ones = n % 10;
      return '${words[tens]} ${words[ones]}';
    }

    if (n < 1000) {
      final hundreds = n ~/ 100;
      final rest = n % 100;
      String result = '${words[hundreds]} hundred';
      if (rest > 0) result += ' ${_numberToWord(rest)}';
      return result;
    }

    return n.toString();
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

