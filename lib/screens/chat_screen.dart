// lib/screens/chat_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/screens/root_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  const ChatScreen({super.key, required this.chatRoomId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController();

  StreamSubscription? _chatSubscription;
  Timer? _heartbeatTimer;
  String? _partnerId;
  Future<DocumentSnapshot>? _partnerFuture;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _setupPartnerInfoAndStartHeartbeat();
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
    _scrollController.dispose();
    _chatSubscription?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  void _setupPartnerInfoAndStartHeartbeat() async {
    try {
      final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatRoomId).get();
      if (!mounted || !chatDoc.exists) return;

      final List<dynamic> users = chatDoc.data()?['users'];
      _partnerId = users.firstWhere((id) => id != _currentUser!.uid, orElse: () => '');

      if (_partnerId!.isNotEmpty) {
        setState(() {
          _partnerFuture = FirebaseFirestore.instance.collection('users').doc(_partnerId).get();
        });
        _listenToChatChanges();
        _startHeartbeat();
      }
    } catch (e) {
      // Hata yönetimi
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_currentUser != null) {
        FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatRoomId)
            .update({'${_currentUser!.uid}_lastActive': FieldValue.serverTimestamp()});
      } else {
        timer.cancel();
      }
    });
  }

  void _listenToChatChanges() {
    _chatSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || !snapshot.exists || _partnerId == null || _partnerId!.isEmpty) return;

      final data = snapshot.data()!;

      if (data['status'] == 'ended' && data['leftBy'] == _partnerId) {
        _chatSubscription?.cancel();
        _heartbeatTimer?.cancel();
        _showPartnerLeftDialog("Partneriniz sohbetten ayrıldı.");
        return;
      }

      final partnerLastActive = data['${_partnerId}_lastActive'] as Timestamp?;
      if (partnerLastActive != null) {
        final difference = Timestamp.now().seconds - partnerLastActive.seconds;
        if (difference > 30) {
          _chatSubscription?.cancel();
          _heartbeatTimer?.cancel();
          _showPartnerLeftDialog("Partnerinizin bağlantısı koptu.");
        }
      }
    });
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

  Future<void> _leaveChat() async {
    if (_currentUser == null) return;
    final navigator = Navigator.of(context);
    _heartbeatTimer?.cancel();
    _chatSubscription?.cancel();
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .update({
        'status': 'ended',
        'leftBy': _currentUser!.uid,
      });
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RootScreen()),
            (route) => false,
      );
    } catch (e) {
      // Hata yönetimi
    }
  }

  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _currentUser == null) {
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
      'userId': _currentUser!.uid,
    });

    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .update({'${_currentUser!.uid}_lastActive': FieldValue.serverTimestamp()});
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
    return WillPopScope(
      onWillPop: () {
        _handleLeaveAttempt();
        return Future.value(false);
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                  ),
                ],
              );
            },
          ),
          actions: [
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
                      return MessageBubble(
                        message: message['text'],
                        timestamp: message['createdAt'],
                        isMe: isMe,
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
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

  const MessageBubble({super.key, required this.message, required this.timestamp, required this.isMe});

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
              color: isMe ? Colors.teal[400] : Colors.grey[300],
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