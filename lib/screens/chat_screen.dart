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
  bool _canBan = false;

  // Yeni: Engelleme durumu
  bool _interactionAllowed = true;
  bool _blockedByMe = false;

  late DateTime _chatStartTime;
  bool _isSaving = false;

  late AnimationController _shimmerController;

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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _refreshBlockState(String currentUserId, String partnerId) async {
    try {
      final usersColl = FirebaseFirestore.instance.collection('users');
      final results = await Future.wait([
        usersColl.doc(currentUserId).get(),
        usersColl.doc(partnerId).get(),
      ]);
      final myBlocked = (results[0].data()?['blockedUsers'] as List<dynamic>?) ?? const [];
      final theirBlocked = (results[1].data()?['blockedUsers'] as List<dynamic>?) ?? const [];
      final blockedByMe = myBlocked.contains(partnerId);
      final blockedMe = theirBlocked.contains(currentUserId);
      if (mounted) {
        setState(() {
          _blockedByMe = blockedByMe;
          _interactionAllowed = !(blockedByMe || blockedMe);
        });
      }
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
          setState(() {
            _partnerFuture = Future.value(results[0]);
            _isPartnerPremium = isPremium;
            _isCurrentUserPremium = (currentUserData?['isPremium'] as bool?) ?? false;
          });
          if (isPremium) {
            _shimmerController.forward();
          }
        }

        // Yeni: Engelleme durumunu güncelle
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

              Widget nameWidget = Text(
                partnerName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: baseColor,
                ),
                overflow: TextOverflow.ellipsis,
              );

              if (isPremium) {
                nameWidget = AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    final highlightColor = Colors.white;
                    final value = _shimmerController.value;
                    final start = value * 1.5 - 0.5;
                    final end = value * 1.5;
                    return ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [baseColor, highlightColor, baseColor],
                        stops: [start, (start + end) / 2, end],
                      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                      child: child!,
                    );
                  },
                  child: nameWidget,
                );
              }

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
                color: Colors.orange.withOpacity(0.15),
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
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('Konuşmayı başlatmak için selam ver!'));
                  }
                  final chatDocs = snapshot.data!.docs;
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                    itemCount: chatDocs.length,
                    itemBuilder: (context, index) {
                      final message = chatDocs[index].data() as Map<String, dynamic>;
                      final isMe = message['userId'] == _currentUser?.uid;
                      final isPremium = isMe ? _isCurrentUserPremium : _isPartnerPremium;
                      return MessageBubble(
                        message: message['text'],
                        timestamp: message['createdAt'],
                        isMe: isMe,
                        isPremium: isPremium,
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
            ),
          ],
        ),
      ),
    );
  }
}

// ... (_MessageComposer ve MessageBubble widget'ları aynı kalır)
class _MessageComposer extends StatefulWidget {
  final String chatRoomId;
  final User? currentUser;
  final bool enabled;

  const _MessageComposer({required this.chatRoomId, required this.currentUser, this.enabled = true});

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

  void _sendMessage() {
    if (!widget.enabled) return;
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || widget.currentUser == null) {
      return;
    }

    _messageController.clear();

    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .collection('messages')
        .add({
      'text': messageText,
      'createdAt': Timestamp.now(),
      'userId': widget.currentUser!.uid,
    });

    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .update({'${widget.currentUser!.uid}_lastActive': FieldValue.serverTimestamp()});
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

class MessageBubble extends StatelessWidget {
  final String message;
  final Timestamp timestamp;
  final bool isMe;
  final bool isPremium;

  const MessageBubble({super.key, required this.message, required this.timestamp, required this.isMe, this.isPremium = false});

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat('HH:mm').format(timestamp.toDate());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: isPremium
                  ? LinearGradient(
                colors: isMe
                    ? [const Color(0xFFE5B53A), const Color(0xFFC08A0A)]
                    : [Colors.grey.shade300, Colors.grey.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : null,
              color: isPremium ? null : (isMe ? Colors.teal[400] : Colors.grey[300]),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(16),
                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
              ),
            ),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Text(message, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16)),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(formattedTime, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
