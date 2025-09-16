// lib/screens/group_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingua_chat/screens/report_user_screen.dart';
import 'package:lingua_chat/services/admin_service.dart';
import 'package:lingua_chat/screens/ban_user_screen.dart';
import 'package:lingua_chat/services/block_service.dart';
import 'package:lingua_chat/services/linguabot_service.dart';
import 'package:lingua_chat/models/grammar_analysis.dart';
import 'package:lingua_chat/widgets/message_composer.dart';
import 'package:lingua_chat/models/group_message.dart';
import 'package:lingua_chat/widgets/group_message_bubble.dart';
import 'package:lingua_chat/widgets/grammar_analysis_dialog.dart';
import 'package:lingua_chat/widgets/sender_header_label.dart';

// Mesaj veri modeli
// class GroupMessage {
//   final String id; // yeni: doc id
//   final String senderId;
//   final String senderName;
//   final String senderAvatarUrl;
//   final String text;
//   final Timestamp? createdAt; // renamed from timestamp
//   final String? senderRole;
//   final bool senderIsPremium;
//
//   GroupMessage({
//     required this.id,
//     required this.senderId,
//     required this.senderName,
//     required this.senderAvatarUrl,
//     required this.text,
//     required this.createdAt,
//     required this.senderRole,
//     required this.senderIsPremium,
//   });
//
//   factory GroupMessage.fromFirestore(DocumentSnapshot doc) {
//     Map data = doc.data() as Map<String, dynamic>;
//     return GroupMessage(
//       id: doc.id,
//       senderId: data['senderId'] ?? '',
//       senderName: data['senderName'] ?? 'Bilinmeyen',
//       senderAvatarUrl: data['senderAvatarUrl'] ?? '',
//       text: data['text'] ?? '',
//       createdAt: data['createdAt'],
//       senderRole: data['senderRole'] as String?,
//       senderIsPremium: (data['senderIsPremium'] as bool?) ?? false,
//     );
//   }
// }
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
  // final TextEditingController _messageController = TextEditingController(); // KALDIRILDI
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
  final Map<String, GrammarAnalysis> _grammarCache = {
  }; // sadece kendi mesaj analizleri
  final Set<String> _analyzing = {}; // analiz süren mesaj id'leri

  double _lastBottomInset = 0;

  int _messageLimit = 50; // sayfalama başlangıç limiti
  final int _messageIncrement = 50; // artış miktarı
  bool _isLoadingMore = false; // yeniden tetiklemeyi engelle
  bool _hasMore = true; // daha fazla kayıt olabilir

  bool _showScrollToBottom = false; // aşağı in butonu
  bool _didInitialScroll = false; // ilk yüklemede alta kaydırıldı mı

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
    _scrollController.addListener(_updateScrollToBottomVisibility);
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

  void _updateScrollToBottomVisibility() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final atBottom = (pos.maxScrollExtent - pos.pixels) < 120; // eşik
    final shouldShow = !atBottom;
    if (shouldShow != _showScrollToBottom) {
      if (mounted) setState(() => _showScrollToBottom = shouldShow);
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
    // _messageController.dispose(); // kaldırıldı
    _scrollController.removeListener(_onScrollLoadMore);
    _scrollController.removeListener(_updateScrollToBottomVisibility);
    _scrollController.dispose();
    _nameShimmerController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool immediate = false}) {
    if (!_scrollController.hasClients) return;
    // jumpTo zaten animasyonsuz; immediate param kullanılmıyor ama interface korunuyor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      try {
        _scrollController.jumpTo(max);
      } catch (_) {}
    });
  }

  @override
  void didChangeMetrics() {
    final bottomInset = View
        .of(context)
        .viewInsets
        .bottom;
    // Klavye yeni açıldı (artış oldu) ise koşulsuz en alta zıpla (jank yok, animasyon yok)
    if (bottomInset > _lastBottomInset) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          _scrollToBottom(immediate: true));
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


  Future<void> _sendGroupMessage(String text) async {
    if (currentUser == null) return;
    final messageText = text.trim();
    if (messageText.isEmpty) return;
    if (messageText.length > 1000) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Message cannot exceed 1000 characters.')),
        );
      }
      return;
    }
    final ref = await FirebaseFirestore.instance
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
      'serverAuth': true,
    });
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
                      builder: (context) =>
                          ReportUserScreen(
                            reportedUserId: message.senderId,
                            reportedContent: '"${message
                                .text}" (Group Chat Message)',
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
                      await BlockService().blockUser(currentUserId: me.uid,
                          targetUserId: message.senderId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User blocked.')));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')));
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
                        builder: (context) =>
                            BanUserScreen(targetUserId: message.senderId),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? Colors.teal.shade200 : Colors.teal.shade800;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.black, Colors.grey.shade900]
              : [Colors.teal.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: fgColor,
          titleSpacing: 0,
          title: Row(
            children: [
              const SizedBox(width: 4),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: isDark
                          ? [Colors.teal.shade800, Colors.teal.shade600]
                          : [Colors.teal.shade400, Colors.teal.shade600]),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Icon(widget.roomIcon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                widget.roomName,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: fgColor),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Burada oda ayarları veya üye listesi gibi bir menü açılabilir
              },
            ),
          ],
        ),
        floatingActionButton: _showScrollToBottom
            ? Padding(
                padding: const EdgeInsets.only(
                    bottom: 60.0), // Composer üstünde konum
                child: FloatingActionButton(
                  heroTag: 'scroll_bottom_btn',
                  backgroundColor:
                      isDark ? Colors.teal.shade700 : Colors.teal.shade500,
                  elevation: 4,
                  onPressed: () => _scrollToBottom(immediate: true),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white, size: 28),
                  shape: const CircleBorder(),
                ),
              )
            : null,
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
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Sohbeti başlat!"));
                }

                final rawDocs = snapshot.data!
                    .docs; // descending, limit uygulanmış
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

                // İlk yükleme sonrasında bir kez alta kaydır
                if (!_didInitialScroll) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_didInitialScroll) {
                      _didInitialScroll = true; // tekrar etme
                      _scrollToBottom(immediate: true);
                    }
                  });
                }

                return ListView.builder(
                  controller: _scrollController,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                  addSemanticIndexes: false,
                  cacheExtent: 600,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 + MediaQuery
                        .of(context)
                        .viewInsets
                        .bottom * 0.0,
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
                                ? const CircularProgressIndicator(
                                strokeWidth: 2)
                                : const SizedBox.shrink(),
                          ),
                        ),
                      );
                    }
                    final adjIndex = _hasMore
                        ? index - 1
                        : index; // loader varsa index kaydır
                    final doc = ordered[adjIndex];
                    final message = GroupMessage.fromFirestore(doc);
                    final isMe = message.senderId == currentUser?.uid;
                    final msgId = doc.id;
                    final ga = isMe ? _grammarCache[msgId] : null;
                    final analyzing = isMe && _analyzing.contains(msgId);

                    bool continuation = false;
                    if (adjIndex > 0) {
                      final prevDoc = ordered[adjIndex - 1];
                      final prevMsg = GroupMessage.fromFirestore(prevDoc);
                      if (prevMsg.senderId == message.senderId) {
                        continuation = true; // zaman sınırı kaldırıldı
                      }
                    }

                    return GestureDetector(
                      onLongPress: () async {
                        if (isMe) {
                          if (analyzing) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Analyzing...')));
                          } else if (ga != null) {
                            showGrammarAnalysisDialog(context, ga,
                                message.text); // mevcut analiz direkt aç
                          } else if (_isCurrentUserPremium) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Analyzing...')));
                            setState(() => _analyzing.add(msgId));
                            final analysis = await _grammarService
                                .analyzeGrammar(message.text);
                            if (!mounted) return;
                            setState(() {
                              _analyzing.remove(msgId);
                              if (analysis != null)
                                _grammarCache[msgId] = analysis;
                            });
                            if (analysis == null && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text(
                                      'Analysis failed, try again.')));
                            } else if (analysis != null) {
                              showGrammarAnalysisDialog(context, analysis,
                                  message.text); // yeni analiz otomatik aç
                            }
                          }
                        } else {
                          _showUserActionsDialog(message); // report/block
                        }
                      },
                      child: _buildMessageBubble(message, isMe, ga: ga,
                          analyzing: analyzing,
                          continuation: continuation),
                    );
                  },
                );
              },
            ),
          ),
          MessageComposer(
            onSend: _sendGroupMessage,
            nativeLanguage: _nativeLanguage,
            enableTranslation: _isCurrentUserPremium && _nativeLanguage != 'en',
            enableSpeech: true,
            enableEmojis: true,
            hintText: 'Type a message…',
            characterLimit: 1000,
            enabled: currentUser != null,
          ),
        ],
      ),
      ),
      );


  }

  Widget _buildMessageBubble(GroupMessage message, bool isMe,
      {GrammarAnalysis? ga, bool analyzing = false, bool continuation = false}) {
    final enableTranslation =
        !isMe && _isCurrentUserPremium && _nativeLanguage != 'en';

    Widget messageBubble = GroupMessageBubble(
      message: message,
      isMe: isMe,
      canTranslate: enableTranslation,
      targetLanguageCode: _nativeLanguage,
      grammarAnalysis: ga,
      analyzing: analyzing,
      isContinuation: continuation,
    );

    // Avatar sadece diğer kullanıcılar için oluşturulur
    final otherAvatar = CircleAvatar(
      radius: 18,
      backgroundColor: Colors.grey.shade300,
      child: ClipOval(
        child: SvgPicture.network(
          message.senderAvatarUrl,
          placeholderBuilder: (context) =>
              const Icon(Icons.person, size: 20),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        top: continuation ? 4.0 : 12.0,
        bottom: 4.0,
        left: 12.0,
        right: 12.0,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && !continuation) otherAvatar,
          if (!isMe && continuation) const SizedBox(width: 42), // 18*2 + 6
          SizedBox(width: isMe ? 0 : 6),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && !continuation)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: SenderHeaderLabel(
                      name: message.senderName,
                      role: message.senderRole,
                      isPremium: message.senderIsPremium,
                      shimmerAnimation: _nameShimmerController,
                    ),
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75),
                  child: messageBubble,
                ),
              ],
            ),
          ),
          // Kendi mesajlarımda avatar veya sağ boşluk EKLENMEZ
        ],
      ),
    );
  }

}