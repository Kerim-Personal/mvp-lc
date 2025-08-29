// lib/screens/chat_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/screens/report_user_screen.dart';
import 'package:lingua_chat/screens/root_screen.dart';
import 'package:lingua_chat/services/admin_service.dart';
import 'package:lingua_chat/screens/ban_user_screen.dart';
import 'package:lingua_chat/services/block_service.dart';
import 'package:lingua_chat/services/translation_service.dart';
import 'package:lingua_chat/services/linguabot_service.dart';
import 'package:lingua_chat/models/grammar_analysis.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  const ChatScreen({super.key, required this.chatRoomId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _currentUser = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController();

  StreamSubscription? _chatSubscription;
  Timer? _heartbeatTimer;
  String? _partnerId;
  Future<DocumentSnapshot>? _partnerFuture;
  bool _isPartnerPremium = false;
  bool _isCurrentUserPremium = false;
  String _currentUserNativeLanguage = 'en';
  bool _canBan = false;
  bool _autoTranslate = false; // yeni
  StreamSubscription<DocumentSnapshot>? _userPrefSub; // yeni
  StreamSubscription<DocumentSnapshot>? _partnerUserSub; // eklendi: partner doc dinleyici
  Map<String, dynamic>? _currentUserDataCache; // eklendi: cache
  Map<String, dynamic>? _partnerDataCache; // eklendi: cache
  // yeni: current user native language
  bool _interactionAllowed = true;
  bool _blockedByMe = false;

  late DateTime _chatStartTime;
  bool _isSaving = false;

  late AnimationController _shimmerController;

  final LinguaBotService _grammarService = LinguaBotService(); // premium analiz
  final Map<String, GrammarAnalysis> _grammarCache = {}; // lokal analiz cache (yalnız kendi mesajlarım)
  final Set<String> _analyzing = {}; // analiz devam eden mesaj id'leri

  int _messageLimit = 30; // sayfalama başlangıç limiti
  final int _messageIncrement = 30; // artış miktarı
  bool _isLoadingMore = false; // tekrar tetiklemeyi engelle
  bool _hasMore = true; // daha fazla veri var mı

  @override
  void initState() {
    super.initState();
    _chatStartTime = DateTime.now();
    _setupPartnerInfoAndStartHeartbeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _shimmerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            _shimmerController.forward(from: 0.0);
          }
        });
      }
    });

    _scrollController.addListener(_onScrollLoadMore);
  }

  void _onScrollLoadMore() {
    if (!_hasMore || _isLoadingMore) return;
    if (!_scrollController.hasClients) return;
    // reverse:true olduğundan eski mesajlara yaklaşmak = maxScrollExtent'e yaklaşmak
    final pos = _scrollController.position;
    if (pos.pixels >= (pos.maxScrollExtent - 150)) {
      setState(() {
        _isLoadingMore = true;
        _messageLimit += _messageIncrement;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _shimmerController.dispose();
    _userPrefSub?.cancel(); // yeni
    _partnerUserSub?.cancel(); // eklendi
    _scrollController.removeListener(_onScrollLoadMore);
    super.dispose();
  }

  void _updateBlockStateFromCaches() {
    if (_currentUserDataCache == null || _partnerDataCache == null) return;
    final currentUser = _currentUser;
    final partnerId = _partnerId;
    if (currentUser == null || partnerId == null) return;
    final myBlocked = (_currentUserDataCache?['blockedUsers'] as List<dynamic>?) ?? const [];
    final theirBlocked = (_partnerDataCache?['blockedUsers'] as List<dynamic>?) ?? const [];
    final blockedByMe = myBlocked.contains(partnerId);
    final blockedMe = theirBlocked.contains(currentUser.uid);
    final interactionAllowed = !(blockedByMe || blockedMe);
    if (blockedByMe != _blockedByMe || interactionAllowed != _interactionAllowed) {
      if (mounted) {
        setState(() {
          _blockedByMe = blockedByMe;
          _interactionAllowed = interactionAllowed;
        });
      }
    }
  }

  Future<void> _refreshBlockState(String currentUserId, String partnerId) async {
    try {
      final usersColl = FirebaseFirestore.instance.collection('users');
      final results = await Future.wait([
        usersColl.doc(currentUserId).get(),
        usersColl.doc(partnerId).get(),
      ]);
      _currentUserDataCache = results[0].data();
      _partnerDataCache = results[1].data();
      _updateBlockStateFromCaches();
    } catch (_) {
      if (mounted) {
        setState(() {
          _blockedByMe = false;
          _interactionAllowed = true;
        });
      }
    }
  }

  Future<void> _setupPartnerInfoAndStartHeartbeat() async {
    final currentUser = _currentUser;
    if (currentUser == null) return;

    try {
      final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatRoomId).get();
      if (!mounted || !chatDoc.exists) return;

      final List<dynamic> users = chatDoc.data()?['users'];
      final partnerId = users.firstWhere((id) => id != currentUser.uid, orElse: () => null);
      _partnerId = partnerId;

      if (partnerId != null) {
        // Ban yetkisi kontrolü
        try {
          final allowed = await AdminService().canBanUser(partnerId);
          if (mounted) setState(() => _canBan = allowed);
        } catch (_) {
          if (mounted) setState(() => _canBan = false);
        }

        final partnerDocFuture = FirebaseFirestore.instance.collection('users').doc(partnerId).get();
        final currentUserDocFuture = FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();

        final results = await Future.wait([partnerDocFuture, currentUserDocFuture]);

        final partnerData = results[0].data();
        final currentUserData = results[1].data();

        if (mounted) {
          final isPremium = (partnerData?['isPremium'] as bool?) ?? false;
          _currentUserNativeLanguage = (currentUserData?['nativeLanguage'] as String?) ?? 'en';
          _autoTranslate = (currentUserData?['autoTranslate'] as bool?) ?? false; // yeni
          // cache initial
          _currentUserDataCache = currentUserData;
          _partnerDataCache = partnerData;
          setState(() {
            _partnerFuture = Future.value(results[0]);
            _isPartnerPremium = isPremium;
            _isCurrentUserPremium = (currentUserData?['isPremium'] as bool?) ?? false;
          });
          if (isPremium) {
            _shimmerController.forward();
          }
        }

        // Kullanıcı tercihlerini + engelleme durumunu dinle (gerçek zamanlı)
        _userPrefSub = FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots().listen((snap) {
          final data = snap.data();
          if (data == null) return;
          _currentUserDataCache = data;
          final nl = (data['nativeLanguage'] as String?) ?? 'en';
          final at = (data['autoTranslate'] as bool?) ?? false;
          if (mounted) {
            setState(() {
              _currentUserNativeLanguage = nl;
              _autoTranslate = at;
            });
          }
          _updateBlockStateFromCaches();
        });

        _partnerUserSub = FirebaseFirestore.instance.collection('users').doc(partnerId).snapshots().listen((snap) {
          final data = snap.data();
          if (data == null) return;
            _partnerDataCache = data;
          _updateBlockStateFromCaches();
        });

        // Yeni: Engelleme durumunu ilk kez güncelle (cache ile)
        await _refreshBlockState(currentUser.uid, partnerId);

        _listenToChatChanges();
        _startHeartbeat();
      }
    } catch (e) {
      // Hata yönetimi
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      final currentUser = _currentUser;
      if (currentUser != null) {
        FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatRoomId)
            .update({'${currentUser.uid}_lastActive': FieldValue.serverTimestamp()});
      } else {
        timer.cancel();
      }
    });
  }

  void _listenToChatChanges() {
    final partnerId = _partnerId;
    if (partnerId == null) return;

    _chatSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .snapshots()
        .listen((snapshot) async {
      if (!mounted || !snapshot.exists) return;

      final data = snapshot.data()!;

      if (data['status'] == 'ended' && data['leftBy'] == partnerId) {
        await _endChatAndSaveChanges("Partneriniz sohbetten ayrıldı.");
        return;
      }

      final partnerLastActive = data['${partnerId}_lastActive'] as Timestamp?;
      if (partnerLastActive != null) {
        final difference = Timestamp.now().seconds - partnerLastActive.seconds;
        if (difference > 30) {
          await _endChatAndSaveChanges("Partnerinizin bağlantısı koptu.");
        }
      }
    });
  }

  Future<void> _savePracticeTime() async {
    final currentUser = _currentUser;
    if (currentUser == null) return;

    final chatDuration = DateTime.now().difference(_chatStartTime);
    final durationInMinutes = chatDuration.inMinutes;

    if (durationInMinutes > 0) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) return;

        final userData = userDoc.data() as Map<String, dynamic>;

        int currentStreak = userData['streak'] ?? 0;
        Timestamp lastActivityTimestamp = userData['lastActivityDate'] ?? Timestamp.now();
        DateTime lastActivityDate = lastActivityTimestamp.toDate();
        DateTime now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day);
        DateTime lastActivityDay = DateTime(lastActivityDate.year, lastActivityDate.month, lastActivityDate.day);
        DateTime yesterday = today.subtract(const Duration(days: 1));

        int newStreak = 1;
        if (lastActivityDay.isAtSameMomentAs(today)) {
          newStreak = currentStreak;
        } else if (lastActivityDay.isAtSameMomentAs(yesterday)) {
          newStreak = currentStreak + 1;
        }

        transaction.update(userRef, {
          'totalPracticeTime': FieldValue.increment(durationInMinutes),
          'streak': newStreak,
          'lastActivityDate': Timestamp.now(),
        });
      });
    }
  }


  Future<void> _endChatAndSaveChanges(String message) async {
    if (_isSaving) return;
    _isSaving = true;

    _chatSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _savePracticeTime();

    if (mounted) {
      _showPartnerLeftDialog(message);
    }
  }

  Future<void> _leaveChat() async {
    final currentUser = _currentUser;
    if (currentUser == null || _isSaving) return;
    _isSaving = true;

    _heartbeatTimer?.cancel();
    _chatSubscription?.cancel();
    await _savePracticeTime();

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .update({
        'status': 'ended',
        'leftBy': currentUser.uid,
      });
    } catch (e) {
      // Hata yönetimi
    } finally {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RootScreen()),
              (route) => false,
        );
      }
    }
  }

  Future<void> _blockOrUnblock() async {
    final partnerId = _partnerId;
    final currentUser = _currentUser;
    if (partnerId == null || currentUser == null) return;
    try {
      if (_blockedByMe) {
        // Engeli kaldır özelliği menüden kaldırıldığı için burada işlem yapılmıyor.
        return;
      } else {
        await BlockService().blockUser(currentUserId: currentUser.uid, targetUserId: partnerId);
        await _refreshBlockState(currentUser.uid, partnerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kullanıcı engellendi.')),
          );
          // Sohbetten çık
          await _leaveChat();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    }
  }

  void _showPartnerLeftDialog(String message) {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Sohbet Sona Erdi'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Ana Sayfa'),
            onPressed: () {
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const RootScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleLeaveAttempt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sohbetten Ayrıl'),
        content: const Text(
            'Bu sohbeti sonlandırmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Ayrıl', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(ctx).pop();
              _leaveChat();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleLeaveAttempt();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).cardColor,
          elevation: 1,
          title: FutureBuilder<DocumentSnapshot>(
            future: _partnerFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Text('Yükleniyor...');
              }
              final partnerData = snapshot.data!.data() as Map<String, dynamic>;
              final avatarUrl = partnerData['avatarUrl'] as String?;
              final partnerName = partnerData['displayName'] ?? 'Bilinmeyen Kullanıcı';
              final role = partnerData['role'] as String?;
              final isPremium = (partnerData['isPremium'] as bool?) ?? false;

              Color baseColor;
              switch (role) {
                case 'admin':
                  baseColor = Colors.red;
                  break;
                case 'moderator':
                  baseColor = Colors.orange;
                  break;
                default:
                  baseColor = Colors.black87;
              }

              if (isPremium && !_shimmerController.isAnimating) {
                _shimmerController.forward(from: 0);
              }

              Widget nameWidget = isPremium
                  ? AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        final value = _shimmerController.value;
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
                          child: child,
                        );
                      },
                      child: Text(
                        partnerName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: (role == 'admin' || role == 'moderator') ? baseColor : const Color(0xFFE5B53A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : Text(
                      partnerName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: baseColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    );

              return Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.teal.shade100,
                    child: avatarUrl != null
                        ? ClipOval(
                            child: SvgPicture.network(
                              avatarUrl,
                              placeholderBuilder: (context) => const SizedBox(
                                  width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2,)
                              ),
                              width: 36,
                              height: 36,
                            ),
                          )
                        : const Icon(Icons.person, color: Colors.teal),
                  ),
                  const SizedBox(width: 12),
                  Flexible(child: nameWidget),
                ],
              );
            },
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'report') {
                  final partnerId = _partnerId;
                  if (partnerId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportUserScreen(reportedUserId: partnerId),
                      ),
                    );
                  }
                } else if (value == 'ban') {
                  final partnerId = _partnerId;
                  if (partnerId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BanUserScreen(targetUserId: partnerId),
                      ),
                    );
                  }
                } else if (value == 'block') {
                  await _blockOrUnblock();
                }
              },
              itemBuilder: (BuildContext context) {
                final List<PopupMenuEntry<String>> items = [
                  if (!_blockedByMe)
                    const PopupMenuItem<String>(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(Icons.block, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Kullanıcıyı Engelle'),
                        ],
                      ),
                    ),
                  const PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.report, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Kullanıcıyı Bildir'),
                      ],
                    ),
                  ),
                ];
                if (_canBan) {
                  items.add(
                    const PopupMenuItem<String>(
                      value: 'ban',
                      child: Row(
                        children: [
                          Icon(Icons.block, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hesabı Banla'),
                        ],
                      ),
                    ),
                  );
                }
                return items;
              },
            ),
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              onPressed: _handleLeaveAttempt,
            )
          ],
        ),
        body: Column(
          children: <Widget>[
            if (!_interactionAllowed)
              Container(
                width: double.infinity,
                color: Colors.orange.withValues(alpha: 0.15),
                padding: const EdgeInsets.all(12),
                child: Text(
                  _blockedByMe
                      ? 'Bu kullanıcıyı engellediniz. Mesaj göndermek için engeli kaldırın.'
                      : 'Bu kullanıcı sizi engellemiş. Mesaj gönderemezsiniz.',
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatRoomId)
                    .collection('messages')
                    .orderBy('createdAt', descending: true)
                    .limit(_messageLimit)
                    .snapshots(),
                builder: (context, snapshot) {
                  // Spinner sadece ilk veri yokken gosterilsin; sonraki anlik gecikmelerde flicker olmasin
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('Konuşmayı başlatmak için selam ver!'));
                  }
                  final chatDocs = snapshot.data!.docs;
                  // sayfalama durum güncelle
                  final reachedFullPage = chatDocs.length >= _messageLimit;
                  // Eğer isLoadingMore ve yeni snapshot geldi ise loadingMore false'a dön
                  if (_isLoadingMore) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _isLoadingMore = false);
                    });
                  }
                  // Daha fazla veri var mı: snapshot boyutu limitten küçükse artık yok
                  final newHasMore = reachedFullPage; // limit doluysa muhtemelen devamı var
                  if (newHasMore != _hasMore) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _hasMore = newHasMore);
                    });
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                    itemCount: chatDocs.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_hasMore && index == chatDocs.length) {
                        // üst tarafta (eski mesajlara) loader göstergesi
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                      final doc = chatDocs[index];
                      final message = doc.data() as Map<String, dynamic>;
                      final isMe = message['userId'] == _currentUser?.uid;
                      final isPremium = isMe ? _isCurrentUserPremium : _isPartnerPremium;
                      final GrammarAnalysis? ga = isMe ? _grammarCache[doc.id] : null;
                      final bool analyzing = isMe && _analyzing.contains(doc.id);
                      return MessageBubble(
                        message: message['text'],
                        timestamp: message['createdAt'],
                        isMe: isMe,
                        isPremium: isPremium,
                        canTranslate: _autoTranslate && _isCurrentUserPremium && !isMe && _currentUserNativeLanguage != 'en',
                        targetLanguageCode: _currentUserNativeLanguage,
                        grammarAnalysis: ga,
                        analyzing: analyzing,
                        onRequestAnalysis: () async {
                          if (!_isCurrentUserPremium) return;
                          if (analyzing) return;
                          setState(() => _analyzing.add(doc.id));
                          final a = await _grammarService.analyzeGrammar(message['text']);
                          if (!mounted) return;
                          setState(() {
                            _analyzing.remove(doc.id);
                            if (a != null) _grammarCache[doc.id] = a;
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
            _MessageComposer(
              chatRoomId: widget.chatRoomId,
              currentUser: _currentUser,
              enabled: _interactionAllowed,
              isPremium: _isCurrentUserPremium,
              onAfterSend: (text, ref) async {
                if (_isCurrentUserPremium) {
                  setState(() => _analyzing.add(ref.id));
                  final analysis = await _grammarService.analyzeGrammar(text);
                  if (!mounted) return;
                  setState(() {
                    _analyzing.remove(ref.id);
                    if (analysis != null) {
                      _grammarCache[ref.id] = analysis;
                    }
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ... (_MessageComposer widget'ı aynı kalır)
class _MessageComposer extends StatefulWidget {
  final String chatRoomId;
  final User? currentUser;
  final bool enabled;
  final bool isPremium; // premium flag
  final Future<void> Function(String text, DocumentReference ref)? onAfterSend; // analiz callback

  const _MessageComposer({required this.chatRoomId, required this.currentUser, this.enabled = true, this.isPremium = false, this.onAfterSend});

  @override
  State<_MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<_MessageComposer> {
  final _messageController = TextEditingController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      final isComposing = _messageController.text.isNotEmpty;
      if (_isComposing != isComposing) {
        setState(() {
          _isComposing = isComposing;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!widget.enabled) return;
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || widget.currentUser == null) {
      return;
    }

    _messageController.clear();

    final ref = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .collection('messages')
        .add({
      'text': messageText,
      'createdAt': Timestamp.now(),
      'userId': widget.currentUser!.uid,
      'serverAuth': true, // security rule gereği
    });

    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .update({'${widget.currentUser!.uid}_lastActive': FieldValue.serverTimestamp()});

    if (widget.onAfterSend != null) {
      widget.onAfterSend!(messageText, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canType = widget.enabled && widget.currentUser != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(offset: const Offset(0, -2), blurRadius: 5, color: Colors.black.withAlpha(10))],
      ),
      child: SafeArea(
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: canType,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: canType ? 'Mesajını yaz...' : 'Mesaj gönderme devre dışı',
                  filled: true,
                  fillColor: Colors.grey.withAlpha(50),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: (_isComposing && canType) ? Colors.teal : Colors.grey,
                    onPressed: (_isComposing && canType) ? _sendMessage : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatefulWidget {
  final String message;
  final Timestamp timestamp;
  final bool isMe;
  final bool isPremium;
  final bool canTranslate;
  final String targetLanguageCode;
  final GrammarAnalysis? grammarAnalysis; // premium kendi mesajı analizi
  final bool analyzing;
  final Future<void> Function()? onRequestAnalysis; // manuel yeniden dene

  const MessageBubble({super.key, required this.message, required this.timestamp, required this.isMe, this.isPremium = false, this.canTranslate = false, this.targetLanguageCode = 'en', this.grammarAnalysis, this.analyzing = false, this.onRequestAnalysis});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  String? _translated;
  bool _translating = false;
  bool _showTranslation = true; // gösterim şekli: orijinal üstte çeviri altta
  String? _error;

  Future<void> _handleTranslate() async {
    if (_translated != null) {
      // Toggle gösterimi: çeviri zaten alınmış; göster/gizle
      setState(() => _showTranslation = !_showTranslation);
      return;
    }
    setState(() { _translating = true; _error = null; });
    try {
      // Model hazır değilse indir (sessiz)
      final ready = await TranslationService.instance.isModelReady(widget.targetLanguageCode);
      if (!ready) {
        await TranslationService.instance.preDownloadModels(widget.targetLanguageCode);
        // Basit bekleme döngüsü: model hazır olana dek (timeout ~20s)
        final start = DateTime.now();
        while (true) {
          await Future.delayed(const Duration(milliseconds: 300));
            final ok = await TranslationService.instance.isModelReady(widget.targetLanguageCode);
          if (ok) break;
          if (DateTime.now().difference(start).inSeconds > 20) {
            throw Exception('Zaman aşımı');
          }
        }
      }
      final tr = await TranslationService.instance.translateFromEnglish(widget.message, widget.targetLanguageCode);
      setState(() { _translated = tr; _showTranslation = true; });
    } catch (e) {
      setState(() { _error = 'Çeviri başarısız: ${e.toString()}'; });
    } finally {
      if (mounted) setState(() { _translating = false; });
    }
  }

  void _showGrammarDialog() {
    if (widget.grammarAnalysis == null) return;
    final ga = widget.grammarAnalysis!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('Gramer Analizi', style: TextStyle(color: Colors.cyanAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Zaman: ${ga.tense}', style: const TextStyle(color: Colors.white70)),
            Text('İsim: ${ga.nounCount}  Fiil: ${ga.verbCount}  Sıfat: ${ga.adjectiveCount}', style: const TextStyle(color: Colors.white70)),
            Text('Duygu: ${(ga.sentiment).toStringAsFixed(2)}  Karmaşıklık: ${(ga.complexity).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
            Text('Formallik: ${ga.formality.name}', style: const TextStyle(color: Colors.white70)),
            if (ga.corrections.isNotEmpty) const SizedBox(height: 8),
            if (ga.corrections.isNotEmpty) const Text('Düzeltmeler:', style: TextStyle(color: Colors.orangeAccent)),
            if (ga.corrections.isNotEmpty)
              ...ga.corrections.entries.take(5).map((e) => Text('${e.key} → ${e.value}', style: const TextStyle(color: Colors.white, fontSize: 13))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    final formattedTime = DateFormat('HH:mm').format(widget.timestamp.toDate());
    final baseTextColor = isMe ? Colors.white : Colors.black87;

    Widget content;
    if (widget.canTranslate && _translated != null && _showTranslation) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.message, style: TextStyle(color: baseTextColor.withValues(alpha: 0.75), fontSize: 14, fontStyle: FontStyle.italic)),
          const SizedBox(height: 4),
          Text(_translated!, style: TextStyle(color: baseTextColor, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      );
    } else {
      content = Text(widget.message, style: TextStyle(color: baseTextColor, fontSize: 16));
    }

    final translateIcon = widget.canTranslate
        ? Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: _translating ? null : _handleTranslate,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _translating
                    ? Container(
                        key: const ValueKey('prog'),
                        width: 22,
                        height: 22,
                        decoration: _iconDecoration(isMe),
                        padding: const EdgeInsets.all(3),
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(isMe ? Colors.white : Colors.teal)),
                      )
                    : Container(
                        key: ValueKey(_translated == null ? 't1' : (_showTranslation ? 't2' : 't3')),
                        width: 22,
                        height: 22,
                        decoration: _iconDecoration(isMe),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Balon + sağda ikon için boşluk
              Padding(
                padding: EdgeInsets.only(right: widget.canTranslate ? 28 : 0),
                child: GestureDetector(
                  onLongPress: () {
                    if (widget.isMe && widget.grammarAnalysis != null) {
                      _showGrammarDialog();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: widget.isPremium
                          ? LinearGradient(
                              colors: isMe
                                  ? [const Color(0xFFE5B53A), const Color(0xFFC08A0A)]
                                  : [Colors.grey.shade300, Colors.grey.shade400],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: widget.isPremium ? null : (isMe ? Colors.teal[400] : Colors.grey[300]),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(16),
                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                      ),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: content,
                  ),
                ),
              ),
              translateIcon,
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 8, right: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
            ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(formattedTime, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ),
        ],
      ),
    );
  }

  BoxDecoration _iconDecoration(bool isMe) => BoxDecoration(
        color: (isMe ? Colors.teal[600] : Colors.white),
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
        border: Border.all(color: isMe ? Colors.white70 : Colors.teal.shade200, width: 1),
      );
}
