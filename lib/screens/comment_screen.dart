// lib/screens/comment_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:lingua_chat/services/translation_service.dart';

// Comment data model
class Comment {
  final String text;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final Timestamp timestamp;

  Comment({
    required this.text,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.timestamp,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Comment(
      text: data['text'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userAvatarUrl: data['userAvatarUrl'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class CommentScreen extends StatefulWidget {
  final String postId;

  const CommentScreen({super.key, required this.postId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  late final AnimationController _nameShimmerController;

  // Emoji & STT (chat_screen’den uyarlanmıştır)
  bool _showEmoticons = false;
  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  bool _listening = false;
  String _speechBaseText = '';
  String? _enLocaleId;
  bool _isComposing = false; // eklendi

  // Çeviri durumu
  bool _translating = false;
  String? _translatedPreview;
  String _selectedTargetCode = 'en'; // 'en' veya anadil kodu
  bool _showTranslationPanel = false; // Çeviri paneli aç/kapa

  // Yorumlar stream'ini cache'le (yeniden subscribe olmaması için)
  late final Stream<QuerySnapshot> _commentsStream;

  final List<String> _textEmoticons = const [
    ':)', ':(', ';)', ':D', ':P', ':O', ':/', ':|', 'XD', 'T_T', '^^', '>_<', '^_^', 'o_O', 'O_o', '-_-', '=_=',
    ':3', '>:(', ':-)', ':-(', ':-D', ':-P', ':-O', ':-|', ':-/', ';-)', '(^_^)', '(>_<)', '(T_T)', '(._.)',
    '(^o^)/', '(¬_¬)', '(•_•)', '(•‿•)', '(☞ﾟ∀ﾟ)☞', '(づ｡◕‿‿◕｡)づ', '┬─┬ ノ( ゜-゜ノ)', '(ಥ﹏ಥ)', '(づ￣ ³￣)づ', '¯\\_(ツ)_/¯',
  ];

  @override
  void initState() {
    super.initState();
    _nameShimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _nameShimmerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _nameShimmerController.forward(from: 0);
        });
      }
    });
    _nameShimmerController.forward();
    _initSpeech();

    // Stream'i bir kez oluşturup sakla
    _commentsStream = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots();

    _commentController.addListener(() {
      final c = _commentController.text.trim().isNotEmpty;
      if (c != _isComposing || _translatedPreview != null) {
        setState(() {
          _isComposing = c;
          _translatedPreview = null; // yazı değişince eski çeviriyi temizle
        });
      }
    });
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(onStatus: (s) {
      if (s == 'done' || s == 'notListening') {
        if (mounted) setState(() => _listening = false);
      }
    }, onError: (e) {
      if (mounted) setState(() => _listening = false);
    });
    if (_speechReady) {
      try {
        final locales = await _speech.locales();
        _enLocaleId = locales.firstWhere((l) => l.localeId == 'en_US', orElse: () => locales.firstWhere((l)=> l.localeId.startsWith('en'))).localeId;
      } catch (_) {
        _enLocaleId = 'en_US';
      }
    }
    if (mounted) setState(() {});
  }

  void _toggleEmoticons() {
    setState(() => _showEmoticons = !_showEmoticons);
  }

  Future<void> _toggleListening() async {
    if (!_speechReady) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cihaz konuşmayı tanımayı desteklemiyor veya izin verilmedi.')));
      return;
    }
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    _speechBaseText = _commentController.text;
    setState(() => _listening = true);
    await _speech.listen(onResult: (res) {
      final recognized = res.recognizedWords;
      final newText = (_speechBaseText.isEmpty ? recognized : (_speechBaseText + (recognized.isEmpty ? '' : ' ' + recognized)));
      _commentController.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
    }, localeId: _enLocaleId ?? 'en_US');
  }

  void _insertEmoticon(String emo) {
    final text = _commentController.text;
    final sel = _commentController.selection;
    final start = sel.start >= 0 ? sel.start : text.length;
    final end = sel.end >= 0 ? sel.end : text.length;
    final newText = text.replaceRange(start, end, emo);
    _commentController.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: start + emo.length));
  }

  // Hedef dili seç ve çevir
  Future<void> _selectTargetAndTranslate(String targetCode) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _selectedTargetCode = targetCode;
        _translatedPreview = null;
      });
      return;
    }
    setState(() {
      _selectedTargetCode = targetCode;
      _translating = true;
    });
    try {
      final native = Localizations.localeOf(context).languageCode.toLowerCase();
      final nativeOrTr = (native == 'en') ? 'tr' : native;
      final source = (targetCode == 'en') ? nativeOrTr : 'en';
      final result = await TranslationService.instance.translatePair(
        text,
        sourceCode: source,
        targetCode: targetCode,
      );
      if (!mounted) return;
      setState(() => _translatedPreview = result.trim());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Çeviri başarısız: $e')));
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  void _toggleTranslationPanel() {
    setState(() {
      _showTranslationPanel = !_showTranslationPanel;
    });
  }

  void _applyTranslatedToInput() {
    final text = _translatedPreview?.trim();
    if (text == null || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktarılacak bir çeviri yok.')),
      );
      return;
    }
    _commentController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _nameShimmerController.dispose();
    if (_listening) {
      _speech.stop();
    }
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || currentUser == null) {
      return;
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    if (!mounted) return;
    final userData = userDoc.data();

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    // Add comment to 'comments' subcollection
    await postRef.collection('comments').add({
      'text': _commentController.text.trim(),
      'userId': currentUser!.uid,
      'userName': userData?['displayName'] ?? 'Unknown User',
      'userAvatarUrl': userData?['avatarUrl'] ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Increment comment count in the post
    await postRef.update({'commentCount': FieldValue.increment(1)});

    if (!mounted) return;
    _commentController.clear();
    setState(() => _translatedPreview = null); // gönderim sonrası çeviriyi temizle
    FocusScope.of(context).unfocus(); // Dismiss the keyboard
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ensure scaffold resizes when keyboard appears and avoid layout overflow
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Comments'),
        elevation: 1,
      ),
      // Use SafeArea to respect system UI and keep composer above keyboard
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _commentsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Be the first to comment!'));
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final comment = Comment.fromFirestore(doc);
                      return KeyedSubtree(
                        key: ValueKey(doc.id),
                        child: RepaintBoundary(child: _buildCommentTile(comment)),
                      );
                    },
                  );
                },
              ),
            ),
            // Composer is padded by viewInsets so it stays above the keyboard
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: _buildCommentComposer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTile(Comment comment) {
    Color roleColor(String? role) {
      switch (role) {
        case 'admin':
          return Colors.red;
        case 'moderator':
          return Colors.orange;
        default:
          return Colors.black87;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              child: ClipOval(
                child: comment.userAvatarUrl.isNotEmpty
                    ? SvgPicture.network(
                  comment.userAvatarUrl,
                  placeholderBuilder: (context) => const SizedBox.shrink(),
                )
                    : const Icon(Icons.person),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(comment.userId).snapshots(),
                    builder: (context, snapshot) {
                      String displayName = comment.userName;
                      String? role;
                      bool isPremium = false;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        displayName = (data['displayName'] as String?)?.trim().isNotEmpty == true ? data['displayName'] : displayName;
                        role = data['role'] as String?;
                        isPremium = data['isPremium'] == true;
                      }
                      final baseColor = roleColor(role);
                      Widget name = Text(
                        displayName,
                        style: TextStyle(fontWeight: FontWeight.bold, color: baseColor),
                      );
                      if (isPremium) {
                         final bool isSpecialRole = (role == 'admin' || role == 'moderator');
                        final Color shimmerBase = isSpecialRole ? baseColor : const Color(0xFFE5B53A);
                        name = AnimatedBuilder(
                          animation: _nameShimmerController,
                          builder: (context, child) {
                            final value = _nameShimmerController.value;
                            final start = value * 1.5 - 0.5;
                            final end = value * 1.5;
                            return ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [shimmerBase, Colors.white, shimmerBase],
                                stops: [start, (start + end) / 2, end]
                                    .map((e) => e.clamp(0.0, 1.0))
                                    .toList(),
                              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                              child: child!,
                            );
                          },
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSpecialRole ? baseColor : const Color(0xFFE5B53A),
                            ),
                          ),
                        );
                      }
                      return name;
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(comment.text),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'en_US').format(comment.timestamp.toDate()),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangToggle(Color onSurface) {
    final native = Localizations.localeOf(context).languageCode.toLowerCase();
    final nativeCode = (native == 'en') ? 'tr' : native; // EN ise TR varsayılanı göster
    final isNativeSelected = _selectedTargetCode == nativeCode;
    final isEnSelected = _selectedTargetCode == 'en';

    Widget pill(String code, bool selected) => SizedBox(
      height: 26,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _translating ? null : () => _selectTargetAndTranslate(code),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? onSurface.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            code.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.6,
              color: onSurface.withValues(alpha: 0.84),
            ),
          ),
        ),
      ),
    );

    return Container(
      width: 46,
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          pill(nativeCode, isNativeSelected),
          const SizedBox(height: 4),
          pill('en', isEnSelected),
        ],
      ),
    );
  }

  Widget _buildCommentComposer() {
    final theme = Theme.of(context);
    // Nötr arka plan: light için siyah %4, dark için beyaz %8
    final Color pillColor = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.04);
    final bool hasPreview = _translatedPreview != null && _translatedPreview!.trim().isNotEmpty;

    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: theme.colorScheme.onSurface,
          secondary: theme.colorScheme.onSurface,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          isCollapsed: true,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: theme.colorScheme.onSurface,
          selectionColor: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          selectionHandleColor: theme.colorScheme.onSurface,
        ),
        iconButtonTheme: const IconButtonThemeData(
          style: ButtonStyle(
            overlayColor: WidgetStatePropertyAll(Colors.transparent),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: theme.dividerColor.withValues(alpha: .30)),
          ),
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Üst satır: Çeviri paneli (açılabilir)
                  if (_showTranslationPanel)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Sabit boyutlu ve kaydırılabilir çeviri kutusu
                        Expanded(
                          child: Container(
                            height: 110,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3)),
                              ],
                              border: Border.all(color: theme.dividerColor.withValues(alpha: .20)),
                            ),
                            child: ScrollConfiguration(
                              behavior: const ScrollBehavior().copyWith(overscroll: false),
                              child: SingleChildScrollView(
                                child: Text(
                                  hasPreview ? _translatedPreview! : 'Çeviri burada görünecek',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withValues(alpha: hasPreview ? 0.9 : 0.5),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Şeffaf tik (çeviriyi inputa aktar)
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: IconButton(
                            tooltip: 'Çeviriyi uygula',
                            icon: Icon(Icons.check_circle_outline, color: theme.colorScheme.onSurface.withValues(alpha: 0.36), size: 20),
                            onPressed: _applyTranslatedToInput,
                            splashRadius: 18,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Dil toggle + çeviri yükleniyor göstergesi
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildLangToggle(theme.colorScheme.onSurface),
                            if (_translating)
                              const SizedBox(
                                width: 34,
                                height: 34,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                      ],
                    ),
                  if (_showTranslationPanel) const SizedBox(height: 8),

                  // Alt satır: input + mic/gönder + panel ok tuşu
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: pillColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.emoji_emotions_outlined),
                                splashRadius: 22,
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                color: theme.iconTheme.color,
                                onPressed: _toggleEmoticons,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  textCapitalization: TextCapitalization.sentences,
                                  minLines: 1,
                                  maxLines: 4,
                                  cursorColor: theme.colorScheme.onSurface,
                                  decoration: const InputDecoration.collapsed(
                                    hintText: 'Yorumunuzu yazın…',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 46,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Panel aç/kapa ok tuşu
                            SizedBox(
                              height: 20,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  _showTranslationPanel ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                                  size: 18,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                onPressed: _toggleTranslationPanel,
                                splashRadius: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Mic / Gönder butonu
                            SizedBox(
                              width: 46,
                              height: 46,
                              child: CircleAvatar(
                                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                                child: IconButton(
                                  icon: Icon(_isComposing ? Icons.send_rounded : (_listening ? Icons.mic : Icons.mic_none), color: theme.colorScheme.onSurface.withValues(alpha: 0.84)),
                                  onPressed: () async {
                                    if (_isComposing) {
                                      await _postComment();
                                    } else {
                                      await _toggleListening();
                                    }
                                  },
                                  splashRadius: 22,
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_showEmoticons)
            Container(
              height: 180,
              margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: GridView.builder(
                itemCount: _textEmoticons.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.6,
                ),
                // Prevent GridView from trying to expand to infinite height
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, i) {
                  final emo = _textEmoticons[i];
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
                    onPressed: () => _insertEmoticon(emo),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(emo, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
