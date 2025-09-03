// lib/screens/group_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/screens/report_user_screen.dart';
import 'package:lingua_chat/services/admin_service.dart';
import 'package:lingua_chat/screens/ban_user_screen.dart';
import 'package:lingua_chat/services/block_service.dart';
import 'package:lingua_chat/services/translation_service.dart';
import 'package:lingua_chat/services/linguabot_service.dart';
import 'package:lingua_chat/models/grammar_analysis.dart';

// Mesaj veri modeli
class GroupMessage {
  final String id; // yeni: doc id
  final String senderId;
  final String senderName;
  final String senderAvatarUrl;
  final String text;
  final Timestamp? createdAt; // renamed from timestamp
  final String? senderRole;
  final bool senderIsPremium;

  GroupMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatarUrl,
    required this.text,
    required this.createdAt,
    required this.senderRole,
    required this.senderIsPremium,
  });

  factory GroupMessage.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return GroupMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Bilinmeyen',
      senderAvatarUrl: data['senderAvatarUrl'] ?? '',
      text: data['text'] ?? '',
      createdAt: data['createdAt'],
      senderRole: data['senderRole'] as String?,
      senderIsPremium: (data['senderIsPremium'] as bool?) ?? false,
    );
  }
}

class GroupChatScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final IconData roomIcon;

  const GroupChatScreen(
      {super.key, required this.roomId, required this.roomName, required this.roomIcon});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser;

  String _userName = 'Kullanıcı';
  String _avatarUrl = '';
  String? _userRole; // yeni role cache

  late final AnimationController _nameShimmerController;

  // Yeni: Engellediklerim (anlık filtre için)
  List<String> _blocked = const [];

  bool _isCurrentUserPremium = false; // yeni
  String _nativeLanguage = 'en'; // yeni

  final LinguaBotService _grammarService = LinguaBotService(); // premium analiz
  final Map<String, GrammarAnalysis> _grammarCache = {}; // sadece kendi mesaj analizleri
  final Set<String> _analyzing = {}; // analiz süren mesaj id'leri

  double _lastBottomInset = 0;

  int _messageLimit = 50; // sayfalama başlangıç limiti
  final int _messageIncrement = 50; // artış miktarı
  bool _isLoadingMore = false; // yeniden tetiklemeyi engelle
  bool _hasMore = true; // daha fazla kayıt olabilir

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserDataAndJoinRoom();
    _listenMyBlocked();
    // Premium isim shimmer'ı için ortak controller
    _nameShimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _nameShimmerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _nameShimmerController.forward(from: 0);
        });
      }
    });
    _nameShimmerController.forward();

    _scrollController.addListener(_onScrollLoadMore);
  }

  void _onScrollLoadMore() {
    if (!_hasMore || _isLoadingMore) return;
    if (!_scrollController.hasClients) return;
    // Liste kronolojik (en eski üstte) olduğundan en üste yaklaşınca (pixels <= 120) daha fazla çek
    if (_scrollController.position.pixels <= 120) {
      setState(() {
        _isLoadingMore = true;
        _messageLimit += _messageIncrement;
      });
    }
  }

  void _listenMyBlocked() {
    final me = currentUser;
    if (me == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(me.uid)
        .collection('blockedUsers')
        .snapshots()
        .listen((snap) {
      final list = snap.docs.map((d) => d.id).toList(growable: false);
      if (mounted) setState(() => _blocked = list);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _leaveRoom();
    _messageController.dispose();
    _scrollController.removeListener(_onScrollLoadMore);
    _scrollController.dispose();
    _nameShimmerController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool immediate = false}) {
    if (!_scrollController.hasClients) return;
    // Bir sonraki frame'de güvenli jump/animate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.position.pixels;
      if ((max - current).abs() < 5) return; // Zaten altta
      if (immediate) {
        _scrollController.jumpTo(max);
      } else {
        _scrollController.animateTo(
          max,
            duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
    if (bottomInset > 0 && bottomInset != _lastBottomInset) {
      _scrollToBottom(immediate: true); // anında zıpla
    }
    _lastBottomInset = bottomInset;
    super.didChangeMetrics();
  }

  Future<void> _loadUserDataAndJoinRoom() async {
    if (currentUser == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (!mounted) return;
      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _userName = data['displayName'] ?? 'Kullanıcı';
          _avatarUrl = data['avatarUrl'] ?? '';
          _isCurrentUserPremium = (data['isPremium'] as bool?) ?? false;
          _nativeLanguage = (data['nativeLanguage'] as String?) ?? 'en';
          _userRole = data['role'] as String?;
        });
        await FirebaseFirestore.instance
            .collection('group_chats')
            .doc(widget.roomId)
            .collection('members')
            .doc(currentUser!.uid)
            .set({
          'displayName': _userName,
          'avatarUrl': _avatarUrl,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanıcı verisi alınamadı: $e')),
        );
      }
    }
  }

  Future<void> _leaveRoom() async {
    if (currentUser == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('group_chats')
          .doc(widget.roomId)
          .collection('members')
          .doc(currentUser!.uid)
          .delete();
    } catch (e) {
      // Hata yönetimi
    }
  }


  void _sendMessage() {
    if (currentUser == null) return;
    final raw = _messageController.text;
    final messageText = raw.trim();
    if (messageText.isEmpty) return;
    if (messageText.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesaj 1000 karakterden uzun olamaz.')),
      );
      return;
    }
    _messageController.clear();

    FirebaseFirestore.instance
        .collection('group_chats')
        .doc(widget.roomId)
        .collection('messages')
        .add({
      'text': messageText,
      'createdAt': Timestamp.now(),
      'senderId': currentUser!.uid,
      'senderName': _userName,
      'senderAvatarUrl': _avatarUrl,
      'senderRole': _userRole,
      'senderIsPremium': _isCurrentUserPremium,
      'serverAuth': true, // security rule gereği
    }).then((ref) async {
      if (_isCurrentUserPremium) {
        setState(() => _analyzing.add(ref.id));
        final analysis = await _grammarService.analyzeGrammar(messageText);
        if (!mounted) return;
        setState(() {
          _analyzing.remove(ref.id);
          if (analysis != null) {
            _grammarCache[ref.id] = analysis;
          }
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(immediate: true); // mesaj sonrası da anında
    });
  }

  Future<void> _showUserActionsDialog(GroupMessage message) async {
    final isMe = message.senderId == currentUser?.uid;
    if (isMe) return;

    bool canBan = false;
    try {
      canBan = await AdminService().canBanUser(message.senderId);
    } catch (_) {
      canBan = false;
    }
    if (!mounted) return;

    final me = currentUser;
    bool isBlocked = false;
    if (me != null) {
      try {
        final blockDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(me.uid)
            .collection('blockedUsers')
            .doc(message.senderId)
            .get();
        if (!mounted) return;
        isBlocked = blockDoc.exists;
      } catch (_) {}
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.report, color: Colors.red),
                title: const Text('Report User'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportUserScreen(
                        reportedUserId: message.senderId,
                        reportedContent: '"${message.text}" (Group Chat Message)',
                        reportedContentId: message.id, // yeni: mesaj id
                      ),
                    ),
                  );
                },
              ),
              if (!isBlocked)
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text('Block User'),
                  onTap: () async {
                    Navigator.pop(context);
                    final me = currentUser;
                    if (me == null) return;
                    try {
                      await BlockService().blockUser(currentUserId: me.uid, targetUserId: message.senderId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User blocked.')));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                      }
                    }
                  },
                ),
              if (canBan)
                ListTile(
                  leading: const Icon(Icons.gavel, color: Colors.red),
                  title: const Text('Ban Account'),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BanUserScreen(targetUserId: message.senderId),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showGrammarDialog(GrammarAnalysis ga, String original) {
    String _formality(Formality f) {
      switch (f) {
        case Formality.informal: return 'Samimi';
        case Formality.neutral: return 'Nötr';
        case Formality.formal: return 'Resmi';
      }
    }
    final maxH = MediaQuery.of(context).size.height * 0.7;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.85),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.cyanAccent.withValues(alpha: .4))),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH, minWidth: 300),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: const [Icon(Icons.science_outlined, color: Colors.cyanAccent), SizedBox(width: 8), Text('Gramer Analizi', style: TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 8),
                  Text('"$original"', style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                  const Divider(color: Colors.cyanAccent, height: 22),
                  Wrap(spacing: 12, runSpacing: 8, children: [
                    _pill(Icons.score, '${(ga.grammarScore*100).toStringAsFixed(0)}%'),
                    _pill(Icons.school, ga.cefr),
                    _pill(Icons.access_time, ga.tense),
                    _pill(Icons.theater_comedy, _formality(ga.formality)),
                    _pill(Icons.translate, 'N:${ga.nounCount}'),
                    _pill(Icons.text_rotation_none, 'V:${ga.verbCount}'),
                    _pill(Icons.color_lens, 'Adj:${ga.adjectiveCount}'),
                  ]),
                  const SizedBox(height: 12),
                  if (ga.corrections.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: .1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orangeAccent.withValues(alpha: .6))),
                      child: Row(children: [
                        const Icon(Icons.edit, color: Colors.orangeAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: RichText(text: TextSpan(style: const TextStyle(color: Colors.white, fontSize: 14), children: [
                          ...ga.corrections.entries.take(1).map((e)=> TextSpan(children:[
                            TextSpan(text: e.key, style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.redAccent)),
                            const TextSpan(text: ' → '),
                            TextSpan(text: e.value, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600)),
                          ]))
                        ])))
                      ])
                    ),
                  if (ga.errors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.white24),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        iconColor: Colors.orangeAccent,
                        collapsedIconColor: Colors.orangeAccent,
                        title: const Text('Hatalar', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                        children: ga.errors.take(6).map((e)=> ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: RichText(text: TextSpan(style: const TextStyle(color: Colors.white70, fontSize: 12), children: [
                            TextSpan(text: '${e.type}: ', style: const TextStyle(color: Colors.cyanAccent)),
                            TextSpan(text: e.original, style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.redAccent)),
                            const TextSpan(text: ' → '),
                            TextSpan(text: e.correction, style: const TextStyle(color: Colors.greenAccent)),
                            TextSpan(text: ' (${e.severity})\n', style: const TextStyle(fontSize: 10, color: Colors.white38)),
                            TextSpan(text: e.explanation, style: const TextStyle(fontSize: 10, color: Colors.white54)),
                          ])),
                        )).toList(),
                      ),
                    ),
                  ],
                  if (ga.suggestions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.white24),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        iconColor: Colors.lightBlueAccent,
                        collapsedIconColor: Colors.lightBlueAccent,
                        title: const Text('Öneriler', style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold)),
                        children: ga.suggestions.take(6).map((s)=> ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Text('•', style: TextStyle(color: Colors.lightBlueAccent)),
                          title: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        )).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('Kapat')),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData i, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.cyanAccent.withValues(alpha: .3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(i, size: 13, color: Colors.cyanAccent), const SizedBox(width: 4), Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11))]),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(widget.roomIcon, size: 24),
            const SizedBox(width: 8),
            Text(widget.roomName),
          ],
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('group_chats')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .limit(_messageLimit)
                  .snapshots(),
              builder: (context, snapshot) {
                // Spinner sadece ilk veri hiç gelmemişse gösterilsin; aksi halde eski veri üzerinden devam
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Sohbeti başlat!"));
                }

                final rawDocs = snapshot.data!.docs; // descending, limit uygulanmış
                // hasMore hesapla: limit dolmuşsa muhtemelen daha eski var
                final bool newHasMore = rawDocs.length >= _messageLimit;
                if (newHasMore != _hasMore) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _hasMore = newHasMore);
                  });
                }
                if (_isLoadingMore) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _isLoadingMore = false);
                  });
                }

                final ordered = rawDocs.reversed.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final senderId = (data['senderId'] as String?) ?? '';
                  return !_blocked.contains(senderId);
                }).toList();

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 + MediaQuery.of(context).viewInsets.bottom * 0.0,
                  ),
                  itemCount: ordered.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_hasMore && index == 0) {
                      // En üstte loader (daha eski mesajları yüklüyor)
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: _isLoadingMore
                                ? const CircularProgressIndicator(strokeWidth: 2)
                                : const SizedBox.shrink(),
                          ),
                        ),
                      );
                    }
                    final adjIndex = _hasMore ? index - 1 : index; // loader varsa index kaydır
                    final doc = ordered[adjIndex];
                    final message = GroupMessage.fromFirestore(doc);
                    final isMe = message.senderId == currentUser?.uid;
                    final msgId = doc.id;
                    final ga = isMe ? _grammarCache[msgId] : null;
                    final analyzing = isMe && _analyzing.contains(msgId);
                    return GestureDetector(
                      onLongPress: () async {
                        if (isMe) {
                          if (analyzing) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Analiz devam ediyor...')));
                          } else if (ga != null) {
                            _showGrammarDialog(ga, message.text);
                          } else if (_isCurrentUserPremium) {
                            setState(() => _analyzing.add(msgId));
                            final analysis = await _grammarService.analyzeGrammar(message.text);
                            if (!mounted) return;
                            setState(() {
                              _analyzing.remove(msgId);
                              if (analysis != null) _grammarCache[msgId] = analysis;
                            });
                            if (analysis == null && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Analiz başarısız, tekrar deneyebilirsin.')));
                            }
                          }
                        } else {
                          _showUserActionsDialog(message);
                        }
                      },
                      child: _buildMessageBubble(message, isMe, ga: ga, analyzing: analyzing),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(GroupMessage message, bool isMe, {GrammarAnalysis? ga, bool analyzing = false}) {
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isMe ? Colors.teal.shade300 : Colors.grey.shade200;
    final enableTranslation = !isMe && _isCurrentUserPremium && _nativeLanguage != 'en';

    Widget messageContent = GroupMessageBubble(
      message: message,
      isMe: isMe,
      canTranslate: enableTranslation,
      targetLanguageCode: _nativeLanguage,
      grammarAnalysis: ga,
      analyzing: analyzing,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: ClipOval(
                child: SvgPicture.network(
                  message.senderAvatarUrl,
                  placeholderBuilder: (context) => const Icon(Icons.person, size: 18),
                ),
              ),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: alignment,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: _buildStaticSenderHeader(message),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          right: isMe ? 20 : 0,
                          top: 0,
                        ),
                        child: messageContent,
                      ),
                      if (isMe && analyzing)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          // Önceden spinner vardı; kaldırıldı ki flicker oluşmasın
                        )
                      else if (isMe && ga != null)
                        const Icon(Icons.science_outlined, size: 16, color: Colors.cyanAccent),
                    ],
                  ),
                ),
                if (message.createdAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      DateFormat('HH:mm').format(message.createdAt!.toDate()),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
          if (isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: ClipOval(
                child: SvgPicture.network(
                  _avatarUrl,
                  placeholderBuilder: (context) => const Icon(Icons.person, size: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
              offset: const Offset(0, -2),
              blurRadius: 5,
              color: Colors.black.withAlpha(10))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Mesajını yaz...',
                  filled: true,
                  fillColor: Colors.grey.withAlpha(50),
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send_rounded),
              color: Colors.teal,
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticSenderHeader(GroupMessage message) {
    String name = message.senderName;
    final role = message.senderRole;
    final isPremium = message.senderIsPremium;
    Color baseColor;
    switch (role) {
      case 'admin':
        baseColor = Colors.red;
        break;
      case 'moderator':
        baseColor = Colors.orange;
        break;
      default:
        baseColor = Colors.grey.shade600;
    }
    Widget child = Text(
      name,
      style: TextStyle(
        fontSize: 12,
        color: (isPremium && !(role == 'admin' || role == 'moderator')) ? const Color(0xFFE5B53A) : baseColor,
      ),
    );
    if (isPremium) {
      child = AnimatedBuilder(
        animation: _nameShimmerController,
        builder: (context, c) {
          final value = _nameShimmerController.value;
          final start = value * 1.5 - 0.5;
          final end = value * 1.5;
          final bool isSpecialRole = (role == 'admin' || role == 'moderator');
          final Color shimmerBase = isSpecialRole ? baseColor : const Color(0xFFE5B53A);
          return ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              colors: [shimmerBase, Colors.white, shimmerBase],
              stops: [start, (start + end) / 2, end]
                  .map((e) => e.clamp(0.0, 1.0))
                  .toList(),
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: c!,
          );
        },
        child: child,
      );
    }
    return child;
  }
}

class GroupMessageBubble extends StatefulWidget {
  final GroupMessage message;
  final bool isMe;
  final bool canTranslate;
  final String targetLanguageCode;
  final GrammarAnalysis? grammarAnalysis; // premium kendi mesajı
  final bool analyzing;

  const GroupMessageBubble({super.key, required this.message, required this.isMe, required this.canTranslate, required this.targetLanguageCode, this.grammarAnalysis, this.analyzing = false});

  @override
  State<GroupMessageBubble> createState() => _GroupMessageBubbleState();
}

class _GroupMessageBubbleState extends State<GroupMessageBubble> {
  String? _translated;
  bool _translating = false;
  bool _showTranslation = true;
  String? _error;

  Future<void> _handleTranslate() async {
    if (_translated != null) {
      setState(() => _showTranslation = !_showTranslation);
      return;
    }
    setState(() { _translating = true; _error = null; });
    try {
      await TranslationService.instance.ensureReady(widget.targetLanguageCode);
       final tr = await TranslationService.instance.translateFromEnglish(widget.message.text, widget.targetLanguageCode);
       setState(() { _translated = tr; _showTranslation = true; });
    } catch (e) {
      setState(() { _error = 'Çeviri başarısız: ${e.toString()}'; });
    } finally {
      if (mounted) setState(() { _translating = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    final baseColor = isMe ? Colors.white : Colors.black87;
    Widget inner;
    if (widget.canTranslate && _translated != null && _showTranslation) {
      inner = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.message.text, style: TextStyle(color: baseColor.withValues(alpha: 0.75), fontSize: 14, fontStyle: FontStyle.italic)),
          const SizedBox(height: 4),
          Text(_translated!, style: TextStyle(color: baseColor, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      );
    } else {
      inner = Text(widget.message.text, style: TextStyle(color: baseColor, fontSize: 16));
    }

    final translateIcon = widget.canTranslate
        ? Positioned(
            bottom: -6,
            right: -6,
            child: InkWell(
              onTap: _translating ? null : _handleTranslate,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _translating
                    ? Container(
                        key: const ValueKey('grp_prog'),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: (isMe ? Colors.teal[600] : Colors.white),
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0,2))],
                          border: Border.all(color: isMe ? Colors.white70 : Colors.teal.shade200, width: 1),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(isMe ? Colors.white : Colors.teal)),
                      )
                    : Container(
                        key: ValueKey(_translated == null ? 'g1' : (_showTranslation ? 'g2' : 'g3')),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: (isMe ? Colors.teal[600] : Colors.white),
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0,2))],
                          border: Border.all(color: isMe ? Colors.white70 : Colors.teal.shade200, width: 1),
                        ),
                        child: Icon(
                          _translated == null
                              ? Icons.translate_outlined
                              : (_showTranslation ? Icons.visibility_off : Icons.visibility),
                          size: 14,
                          color: isMe ? Colors.white : Colors.teal.shade700,
                        ),
                      ),
              ),
            ),
          )
        : const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isMe ? Colors.teal.shade300 : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: widget.isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: widget.isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
              ),
              child: inner,
            ),
            translateIcon,
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4),
            child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
          ),
      ],
    );
  }
}
