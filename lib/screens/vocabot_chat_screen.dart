// lib/screens/vocabot_chat_screen.dart
// This is not a chat screen, it's a language universe simulator.
// v2.4.0: Star animations have been calmed and naturalized. The environment is now authentic and not distracting.

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vocachat/services/vocabot_service.dart';
import 'package:vocachat/models/grammar_analysis.dart';
import 'package:vocachat/models/grammar_quiz.dart';
import 'package:vocachat/models/message_unit.dart';
import 'package:vocachat/widgets/linguabot/linguabot.dart';
import 'package:vocachat/utils/text_metrics.dart';
import 'package:vocachat/widgets/message_composer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:circle_flags/circle_flags.dart';
import 'package:vocachat/services/local_chat_storage.dart';
import 'package:vocachat/models/lesson_model.dart';
import 'package:vocachat/services/streak_service.dart';
import 'package:vocachat/widgets/linguabot/language_data.dart';
import 'package:vocachat/widgets/linguabot/linguabot_settings.dart';

// --- MAIN SCREEN: THE HEART OF THE SIMULATOR ---

class LinguaBotChatScreen extends StatefulWidget {
  final bool isPremium;
  const LinguaBotChatScreen({super.key, this.isPremium = false});

  @override
  State<LinguaBotChatScreen> createState() => _LinguaBotChatScreenState();
}

class _LinguaBotChatScreenState extends State<LinguaBotChatScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late LinguaBotService _botService; // hedef dil değiştikçe yeniden oluşturulacak
  final ScrollController _scrollController = ScrollController();
  final List<MessageUnit> _messages = [];
  bool _isBotThinking = false;
  String _nativeLanguage = 'en';
  String _targetLanguage = 'en'; // öğrenilmek istenen dil
  String _learningLevel = 'medium'; // kullanıcının seçtiği seviye
  bool _botReady = false;
  bool _isPremium = false;
  bool _allowPop = false; // allow programmatic pop after confirm
  bool _composerEmojiOpen = false; // composer emoji panel durumu
  String? _scenario; // seçili senaryo
  bool _showScrollToBottom = false; // scroll to bottom butonunu göster/gizle

  // Desteklenen diller (öğrenilecek dil seçenekleri)
  static const Map<String, String> _supportedLanguages = supportedLanguages;

  // Dil kodları ile bayrak kodları eşleştirmesi
  static const Map<String, String> _languageFlags = languageFlags;

  // Açılış selamları (hedef öğrenilen dilde)
  static const Map<String, String> _welcomeMessages = welcomeMessages;

  late AnimationController _backgroundController;
  late AnimationController _entryController;
  late Animation<double> _blurAnimation;

  // Oturum süresi takibi (leaderboard için totalRoomTime)
  DateTime? _sessionStart;
  static const int _maxSessionSeconds = 6 * 60 * 60; // 6 saat güvenlik sınırı

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionStart = DateTime.now();

    _backgroundController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _blurAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    // Eski: İngilizce sabit mesaj ekleniyordu. Artık profil yüklendikten sonra hedef dile göre eklenecek.
    _entryController.forward();
    _loadUserProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _commitAndResetSessionTime();
    _backgroundController.dispose();
    _entryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _commitAndResetSessionTime();
    } else if (state == AppLifecycleState.resumed) {
      // Yeni dilim için başlangıcı sıfırla
      _sessionStart = DateTime.now();
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _commitAndResetSessionTime() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final start = _sessionStart;
    if (start == null) {
      _sessionStart = DateTime.now();
      return;
    }
    final seconds = DateTime.now().difference(start).inSeconds;
    if (seconds > 0) {
      final safeSeconds = seconds > _maxSessionSeconds ? _maxSessionSeconds : seconds;
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'totalRoomTime': FieldValue.increment(safeSeconds)});
        // Kullanıcı etkinliği gerçekleşti: streak'i güncelle
        try {
          await StreakService.updateStreakOnActivity(uid: user.uid);
        } catch (_) {
          // sessizce geç: offline veya yarış koşulu olabilir
        }
      } catch (_) {
        // sessiz: offline veya yetki hatası olabilir
      }
    }
    // Yeni dilim için başlangıcı sıfırla
    _sessionStart = DateTime.now();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = snap.data();
      if (!mounted || data == null) return;
      setState(() {
        _nativeLanguage = (data['nativeLanguage'] as String?) ?? 'en';
        _targetLanguage = (data['learningLanguage'] as String?) ?? 'en';
        _learningLevel = (data['learningLanguageLevel'] as String?) ?? 'medium';
        _isPremium = (data['isPremium'] as bool?) ?? false;
      });
      // Yerel model indirme (on-device) kaldırıldı: Bu ekranda sadece AI tabanlı çeviri kullanılacak.
      _initBotService();
    } catch (_) {
      // sessizce geç
    }
  }

  void _initBotService() {
    _botService = LinguaBotService(targetLanguage: _targetLanguage, nativeLanguage: _nativeLanguage, learningLevel: _learningLevel);
    setState(() => _botReady = true);
    // Açılış mesajını sadece ilk kez (liste boşsa) ekle
    if (_messages.isEmpty) {
      _addWelcomeMessage();
    }
    // Hedef dile göre son 20 mesajı yükle (varsa karşılama mesajını yerini alır)
    _loadRecentMessages();
    // Scroll listener ekle
    _scrollController.addListener(_onScroll);
    // Dil değişimi durumunda scroll durumunu sıfırla
    setState(() => _showScrollToBottom = false);
  }

  // Scroll durumunu takip et
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    // Reverse ListView için:
    // - 0 = en alt (en yeni mesajlar) - BURADA BUTON GİZLENMELİ
    // - maxScrollExtent = en üst (en eski mesajlar)
    // Kullanıcı yukarı kaydırıp eski mesajlara baktığında butonu göster
    // En alttayken (currentScroll yaklaşık 0) butonu gizle
    final shouldShow = maxScroll > 50 && currentScroll > 50;

    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  Future<void> _loadRecentMessages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final list = await LocalChatStorage.instance.load(user.uid, _targetLanguage);
    if (!mounted) return;
    if (list.isNotEmpty) {
      setState(() {
        _messages
          ..clear()
          ..addAll(list);
      });
    }
    // Artık _scrollToBottom() çağrısına gerek yok - reverse: true ile otomatik altta görünür
  }

  void _addWelcomeMessage() {
    final msg = _welcomeMessages[_targetLanguage] ?? _welcomeMessages['en']!;
    setState(() {
      _messages.add(
        MessageUnit(
          text: msg,
          sender: MessageSender.bot,
          grammarAnalysis: const GrammarAnalysis(
            tense: 'Present Simple',
            verbCount: 1,
            nounCount: 2,
            complexity: 0.3,
            sentiment: 0.7,
          ),
        ),
      );
    });
  }

  // Modern level picker (EN, with flag & language)
  Future<String?> _promptLearningLevel(String langCode) async {
    final langName = _supportedLanguages[langCode] ?? langCode.toUpperCase();
    final flagCode = _languageFlags[langCode] ?? langCode;
    const levels = [
      {'code': 'none', 'label': "None", 'desc': "I don't know it yet"},
      {'code': 'low', 'label': "A little", 'desc': "Basic words and phrases"},
      {'code': 'medium', 'label': "Intermediate", 'desc': "Can hold simple conversations"},
      {'code': 'high', 'label': "Good", 'desc': "Comfortable in most situations"},
      {'code': 'very_high', 'label': "Very good", 'desc': "Near-fluent or fluent"},
    ];

    String tempSelected = _learningLevel; // pre-select current

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black.withAlpha(235),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 16),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.cyanAccent.withAlpha(100), width: 1),
                            ),
                            child: CircleFlag(flagCode, size: 24),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select your level',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  langName,
                                  style: TextStyle(color: Colors.cyanAccent.withAlpha(220), fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(null),
                            icon: const Icon(Icons.close, color: Colors.white70),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...levels.map((lvl) {
                        final code = lvl['code'] as String;
                        final isSelected = tempSelected == code;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white24, width: 1),
                            color: isSelected ? Colors.cyanAccent.withAlpha(22) : Colors.white.withAlpha(10),
                          ),
                          child: RadioListTile<String>(
                            value: code,
                            groupValue: tempSelected,
                            onChanged: (v) => setSheetState(() => tempSelected = v ?? tempSelected),
                            activeColor: Colors.cyanAccent,
                            dense: true,
                            title: Text(
                              lvl['label'] as String,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              lvl['desc'] as String,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white24),
                                foregroundColor: Colors.white70,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.of(context).pop(null),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyanAccent,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.of(context).pop(tempSelected),
                              child: const Text('Save level'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _changeTargetLanguage(String newCode, {String? level}) async {
    final isSameLanguage = newCode == _targetLanguage;
    if (isSameLanguage && (level == null || level == _learningLevel)) return; // değişiklik yok
    final user = FirebaseAuth.instance.currentUser;
    setState(() => _botReady = false);
    try {
      if (user != null) {
        final Map<String, dynamic> payload = {};
        if (!isSameLanguage) payload['learningLanguage'] = newCode;
        if (level != null) payload['learningLanguageLevel'] = level;
        if (payload.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(payload, SetOptions(merge: true));
        }
      }
    } catch (_) {
      // offline vs yetki: kullanıcıya yine de yerel güncelleme
    }
    setState(() {
      if (!isSameLanguage) {
        _targetLanguage = newCode;
        _messages.clear(); // Dil değişince sohbet temizlenir
      }
      if (level != null) _learningLevel = level;
    });
    _initBotService();
  }

  // Dil kartı tıklananca: aynı dilse sadece seviye değiştir, farklıysa seviye sorup dili değiştir
  Future<void> _onSelectLanguage(String langCode) async {
    if (langCode == _targetLanguage) {
      final selected = await _promptLearningLevel(langCode);
      if (selected == null || selected == _learningLevel) return;
      await _changeTargetLanguage(langCode, level: selected);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final selected = await _promptLearningLevel(langCode);
    if (selected == null) return; // kullanıcı vazgeçti
    await _changeTargetLanguage(langCode, level: selected);
    if (mounted) Navigator.of(context).pop(); // ayarlar ekranını kapat
  }

  List<String> _computeSuggestions() {
    // Kullanıcı isteği: tüm hazır öneri cümleleri kaldırıldı.
    return const [];
  }

  Widget _buildLanguageTile(String langCode) {
    final langName = _supportedLanguages[langCode]!;
    final isSelected = langCode == _targetLanguage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // biraz daha dar
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.cyanAccent.withAlpha(55),
                  Colors.cyanAccent.withAlpha(15),
                ],
              )
            : LinearGradient(
                colors: [
                  const Color(0xFF1B1B1B),
                  Colors.black.withAlpha(150),
                ],
              ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? Colors.cyanAccent : Colors.cyanAccent.withAlpha(40),
          width: isSelected ? 1.6 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _onSelectLanguage(langCode);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.07 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: CircleFlag(
                  _languageFlags[langCode] ?? langCode,
                  size: 42, // eski boyuta yakın
                ),
              ),
              const SizedBox(height: 5),
              Text(
                langName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.cyanAccent : Colors.white70,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.15,
                ),
              ),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 20,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty || !_botReady) return;

    // Gramer analizi: her durumda paralel başlat
    final Future<GrammarAnalysis?> analysisFuture = _botService.analyzeGrammar(text);

    final userMessage = MessageUnit(
      text: text,
      sender: MessageSender.user,
      grammarAnalysis: null, // analiz hazır olduğunda doldurulacak
      vocabularyRichness: TextMetrics.vocabularyRichness(text),
    );

    setState(() {
      _messages.add(userMessage);
      _isBotThinking = true;
    });
    // Yerel kaydet (kullanıcı mesajı eklendi)
    final u1 = FirebaseAuth.instance.currentUser;
    if (u1 != null) {
      LocalChatStorage.instance.save(u1.uid, _targetLanguage, _messages);
    }

    // Analiz tamamlanınca mesajı güncelle
    analysisFuture.then((analysis) {
      if (!mounted) return;
      if (analysis != null) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == userMessage.id);
          if (idx != -1) {
            _messages[idx].grammarAnalysis = analysis;
          }
        });
        // Analiz güncellemesi sonrası da kaydetmek gerekmiyor; sadece metinler saklanıyor.
      }
    }).catchError((_) {
      // sessizce yoksay
    });

    final botStartTime = DateTime.now();

    try {
      // Konuşma geçmişini hazırla (welcome mesajını hariç tut, son 8 mesaj)
      final List<Map<String, String>> chatHistory = [];
      for (var msg in _messages) {
        // İlk welcome mesajını geçmişe ekleme
        if (msg.sender == MessageSender.bot && msg.text == (_welcomeMessages[_targetLanguage] ?? _welcomeMessages['en']!)) {
          continue;
        }
        chatHistory.add({
          'role': msg.sender == MessageSender.user ? 'user' : 'assistant',
          'content': msg.text,
        });
      }

      // Son 8 mesajı gönder (4 soru-cevap çifti = yeterli bağlam)
      final recentHistory = chatHistory.length > 8
          ? chatHistory.sublist(chatHistory.length - 8)
          : chatHistory;

      final botResponseText = await _botService.sendMessage(text, scenario: _scenario, chatHistory: recentHistory);
      final botResponseTime = DateTime.now().difference(botStartTime);

      final botMessage = MessageUnit(
        text: botResponseText,
        sender: MessageSender.bot,
        botResponseTime: botResponseTime,
        grammarAnalysis: null, // bot mesajları analiz edilmez
        vocabularyRichness: TextMetrics.vocabularyRichness(botResponseText),
      );

      if (!mounted) return;
      setState(() {
        _messages.add(botMessage);
      });
      // Bot yanıtı eklendi -> kaydet
      final u2 = FirebaseAuth.instance.currentUser;
      if (u2 != null) {
        LocalChatStorage.instance.save(u2.uid, _targetLanguage, _messages);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('There was a problem sending the message.')));
    } finally {
      if (!mounted) return;
      setState(() => _isBotThinking = false);
      // Artık _scrollToBottom() çağrısına gerek yok - reverse: true ile otomatik görünür
    }
  }

  void _updateMessageText(String messageId, String newText) {
    setState(() {
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        _messages[messageIndex].text = newText;
      }
    });
    // Düzeltme sonrası kaydet
    final u3 = FirebaseAuth.instance.currentUser;
    if (u3 != null) {
      LocalChatStorage.instance.save(u3.uid, _targetLanguage, _messages);
    }
  }

  void _openSettings() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.black.withValues(alpha: 0.55), // arka plan hafif görünür
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, a1, a2) {
        return FullScreenSettings(
          supportedLanguages: _supportedLanguages,
          languageFlags: _languageFlags,
          targetLanguage: _targetLanguage,
          buildTile: _buildLanguageTile,
          onClose: () => Navigator.of(context).pop(),
          onChange: (code) {
            _changeTargetLanguage(code);
            Navigator.of(context).pop();
          },
        );
      },
      transitionBuilder: (context, anim, sec, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  // Basit normalizasyon: küçük harf, noktalama ve ekstra boşlukları temizle
  String _normalizeQuestion(String text) {
    final lower = text.toLowerCase();
    final cleaned = lower.replaceAll(RegExp(r'[^a-z0-9çğıışöüáéíóúñäöüßâêîôûãõàèìòù¿¡]+', caseSensitive: false), ' ');
    return cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).join(' ');
  }

  // Jaccard benzerliği (0..1) - kelime setleri üzerinde
  double _jaccardSimilarity(String a, String b) {
    final sa = _normalizeQuestion(a).split(' ').toSet();
    final sb = _normalizeQuestion(b).split(' ').toSet();
    if (sa.isEmpty && sb.isEmpty) return 1.0;
    if (sa.isEmpty || sb.isEmpty) return 0.0;
    final inter = sa.intersection(sb).length.toDouble();
    final union = sa.union(sb).length.toDouble();
    return inter / union;
  }

  // Bu topic için yakın geçmiş soru metinleri (normalize edilmiş)
  List<String> _recentQuestionsForTopic(String topicPath, {int maxItems = 10}) {
    final list = <String>[];
    for (final m in _messages.reversed) { // en yenilerden
      final q = m.quiz;
      if (q == null) continue;
      if (q.topicPath != topicPath) continue;
      list.add(q.question);
      if (list.length >= maxItems) break;
    }
    return list;
  }

  // Benzer soruları filtreleyerek yeni quiz getir
  Future<GrammarQuiz?> _getDistinctQuiz(String topicPath, String topicTitle, {int maxTries = 5, double similarityThreshold = 0.8}) async {
    GrammarQuiz? last;
    // Son sorular listesini kopyalayarak çalış
    final excludes = List<String>.from(_recentQuestionsForTopic(topicPath));
    for (int i = 0; i < maxTries; i++) {
      final quiz = await _botService.getGrammarQuiz(
        topicPath: topicPath,
        topicTitle: topicTitle,
        excludeQuestions: excludes,
      );
      if (quiz == null) continue; // tekrar dene
      last = quiz;
      if (excludes.isEmpty) return quiz; // geçmiş yok, kabul
      final tooSimilar = excludes.any((prev) {
        final sim = _jaccardSimilarity(prev, quiz.question);
        // Ayrıca içerme durumu (normalize edilince biri diğerini içeriyorsa) -> çok benzer say
        final pn = _normalizeQuestion(prev);
        final qn = _normalizeQuestion(quiz.question);
        final contains = pn.length > 8 && qn.contains(pn) || qn.length > 8 && pn.contains(qn);
        return sim >= similarityThreshold || contains;
      });
      if (!tooSimilar) return quiz; // yeterince farklı
      // Bu adayı da exclude listesine ekleyip tekrar dene
      excludes.add(quiz.question);
      await Future.delayed(const Duration(milliseconds: 120));
    }
    return last; // yoksa sonuncuyu ver (kullanıcıyı bekletmemek için)
  }

  // Quiz başlat (composer -> gramer seçimi)
  Future<void> _startGrammarQuiz(Lesson lesson) async {
    if (!_botReady) return;
    try {
      final quiz = await _getDistinctQuiz(lesson.contentPath, lesson.title);
      if (quiz == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz oluşturulamadı.')));
        return;
      }
      final msg = MessageUnit(
        text: quiz.question,
        sender: MessageSender.bot,
        botResponseTime: const Duration(milliseconds: 0),
        grammarAnalysis: null,
        vocabularyRichness: TextMetrics.vocabularyRichness(quiz.question),
        quiz: quiz,
        selectedOptionIndex: null,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(msg);
      });
      final u4 = FirebaseAuth.instance.currentUser;
      if (u4 != null) {
        LocalChatStorage.instance.save(u4.uid, _targetLanguage, _messages);
      }
      // Artık _scrollToBottom() çağrısına gerek yok - reverse: true ile otomatik görünür
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz yüklenirken hata oluştu.')));
    }
  }

  // Aynı konudan yeni bir soru iste (quiz cevabı sonrası buton)
  Future<void> _requestNextQuizForTopic(String topicPath, String topicTitle) async {
    if (!_botReady) return;
    try {
      final quiz = await _getDistinctQuiz(topicPath, topicTitle);
      if (quiz == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yeni soru oluşturulamadı.')));
        return;
      }
      final msg = MessageUnit(
        text: quiz.question,
        sender: MessageSender.bot,
        botResponseTime: const Duration(milliseconds: 0),
        grammarAnalysis: null,
        vocabularyRichness: TextMetrics.vocabularyRichness(quiz.question),
        quiz: quiz,
        selectedOptionIndex: null,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(msg);
      });
      final u = FirebaseAuth.instance.currentUser;
      if (u != null) {
        LocalChatStorage.instance.save(u.uid, _targetLanguage, _messages);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yeni soru yüklenirken hata oluştu.')));
    }
  }

  // Chat exit confirmation dialog
  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black.withAlpha(235),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          title: const Text('Leave chat?', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to exit this chat screen?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.cyanAccent)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // Quiz şık seçimi işlensin
  void _handleQuizAnswer(MessageUnit message, int index) {
    final idx = _messages.indexWhere((m) => m.id == message.id);
    if (idx == -1) return;
    // daha önce seçilmediyse işle
    if (_messages[idx].selectedOptionIndex != null) return;
    setState(() {
      _messages[idx].selectedOptionIndex = index;
    });
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      LocalChatStorage.instance.save(u.uid, _targetLanguage, _messages);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _computeSuggestions();
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Eğer alt composer geri tuşunu emoji/klavye kapatmak için kullandıysa, onay diyaloğunu açmayalım
        final primaryFocus = FocusManager.instance.primaryFocus;
        if (_composerEmojiOpen || (primaryFocus != null && primaryFocus.hasFocus)) {
          return;
        }
        _confirmExit().then((shouldPop) async {
          if (shouldPop && mounted) {
            await _commitAndResetSessionTime();
            setState(() => _allowPop = true);
            Navigator.of(context).pop();
          }
        });
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            CelestialBackground(controller: _backgroundController),
            AnimatedBuilder(
              animation: _entryController,
              builder: (context, child) => BackdropFilter(
                filter: ImageFilter.blur(sigmaX: _blurAnimation.value, sigmaY: _blurAnimation.value),
                child: child,
              ),
              child: Container(color: Colors.black.withAlpha(26)),
            ),
            SafeArea(
              child: Column(
                children: [
                  HolographicHeader(
                    isBotThinking: _isBotThinking,
                    onSettingsTap: _openSettings,
                    selectedLanguage: _targetLanguage,
                    languageFlags: _languageFlags,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        ListView.builder(
                          controller: _scrollController,
                          reverse: true, // Her zaman reverse - ChatGPT tarzı
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          itemCount: _messages.length + (_isBotThinking ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Reverse ListView için index hesaplama
                            if (_isBotThinking && index == 0) {
                              return const MessageEntranceAnimator(child: TypingIndicator());
                            }

                            final messageIndex = _isBotThinking ? index - 1 : index;
                            if (messageIndex >= _messages.length) return const SizedBox.shrink();

                            final actualIndex = _messages.length - 1 - messageIndex;
                            if (actualIndex < 0) return const SizedBox.shrink();

                            final message = _messages[actualIndex];
                            final bool isLastBubble = actualIndex == _messages.length - 1;
                            return MessageEntranceAnimator(
                              key: ValueKey(message.id),
                              child: MessageBubble(
                                message: message,
                                onCorrect: (newText) => _updateMessageText(message.id, newText),
                                isUserPremium: _isPremium,
                                nativeLanguage: _nativeLanguage,
                                isPremium: _isPremium,
                                onQuizAnswer: (idx) => _handleQuizAnswer(message, idx),
                                onRequestMoreQuiz: (topicPath, topicTitle) => _requestNextQuizForTopic(topicPath, topicTitle),
                                isLast: isLastBubble,
                              ),
                            );
                          },
                        ),
                        // Scroll to bottom button
                        if (_showScrollToBottom)
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: AnimatedSlide(
                              offset: _showScrollToBottom ? Offset.zero : const Offset(0, 1),
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              child: AnimatedOpacity(
                                opacity: _showScrollToBottom ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.cyanAccent.withAlpha(240),
                                        Colors.cyanAccent.withAlpha(200),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.cyanAccent.withAlpha(100),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.cyanAccent.withAlpha(80),
                                        blurRadius: 12,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(24),
                                      onTap: () {
                                        _scrollController.animateTo(
                                          0,
                                          duration: const Duration(milliseconds: 400),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                      child: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.black,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (suggestions.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: suggestions
                              .take(6)
                              .map((s) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ActionChip(
                                      label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      onPressed: _isBotThinking ? null : () => _sendMessage(s),
                                      backgroundColor: Colors.black.withAlpha(64),
                                      side: BorderSide(color: Colors.cyanAccent.withAlpha(100)),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: ThemeData.dark().colorScheme.copyWith(
                        primary: Colors.cyanAccent,
                        surface: const Color(0xFF121212),
                        onSurface: Colors.white,
                      ),
                      iconTheme: const IconThemeData(color: Colors.white),
                      hintColor: Colors.white70,
                      dividerColor: Colors.white24,
                      cardColor: const Color(0xFF1E1E1E),
                    ),
                    child: MessageComposer(
                      onSend: _sendMessage,
                      nativeLanguage: _nativeLanguage,
                      enableTranslation: _nativeLanguage != _targetLanguage, // anadil ile hedef dil farklı ise göster
                      enableSpeech: true,
                      enableEmojis: true,
                      hintText: _botReady ? 'Message' : 'Loading...',
                      characterLimit: 1000,
                      enabled: _botReady,
                      onEmojiVisibilityChanged: (open) => setState(() => _composerEmojiOpen = open),
                      isPremium: _isPremium,
                      useAiTranslation: true,
                      aiTargetLanguage: _targetLanguage,
                      // Senaryo
                      selectedScenario: _scenario,
                      onScenarioChanged: (s) => setState(() => _scenario = s),
                      // Gramer
                      onGrammarPractice: (lesson) => _startGrammarQuiz(lesson),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

