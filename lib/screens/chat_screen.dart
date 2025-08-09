// lib/screens/chat_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/screens/report_user_screen.dart';
import 'package:lingua_chat/screens/root_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  const ChatScreen({super.key, required this.chatRoomId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController();

  StreamSubscription? _chatSubscription;
  Timer? _heartbeatTimer;
  String? _partnerId;
  Future<DocumentSnapshot>? _partnerFuture;
  bool _isPartnerPremium = false;
  bool _isCurrentUserPremium = false;

  late DateTime _chatStartTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _chatStartTime = DateTime.now();
    _setupPartnerInfoAndStartHeartbeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatSubscription?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
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
        final partnerDocFuture = FirebaseFirestore.instance.collection('users').doc(partnerId).get();
        final currentUserDocFuture = FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();

        final results = await Future.wait([partnerDocFuture, currentUserDocFuture]);

        final partnerData = results[0].data();
        final currentUserData = results[1].data();

        if (mounted) {
          setState(() {
            _partnerFuture = Future.value(results[0]);
            _isPartnerPremium = (partnerData?['isPremium'] as bool?) ?? false;
            _isCurrentUserPremium = (currentUserData?['isPremium'] as bool?) ?? false;
          });
        }

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
    await _savePracticeTime();

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
      onPopInvoked: (didPop) {
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
              final isPremium = _isPartnerPremium;
              const premiumColor = Color(0xFFE5B53A);
              const premiumIcon = Icons.auto_awesome;
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
                  Text(
                    partnerData['displayName'] ?? 'Bilinmeyen Kullanıcı',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isPremium ? premiumColor : Colors.black87,
                    ),
                  ),
                  if (isPremium) ...[
                    const SizedBox(width: 4),
                    const Icon(premiumIcon, color: premiumColor, size: 18),
                  ]
                ],
              );
            },
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
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
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
              ],
            ),
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              onPressed: _handleLeaveAttempt,
            )
          ],
        ),
        body: Column(
          children: <Widget>[
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
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageComposer extends StatefulWidget {
  final String chatRoomId;
  final User? currentUser;

  const _MessageComposer({required this.chatRoomId, required this.currentUser});

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
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Mesajını yaz...',
                  filled: true,
                  fillColor: Colors.grey.withAlpha(50),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: _isComposing ? Colors.teal : Colors.grey,
                    onPressed: _isComposing ? _sendMessage : null,
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