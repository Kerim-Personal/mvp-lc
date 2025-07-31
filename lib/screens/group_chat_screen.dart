// lib/screens/group_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

// Mesaj veri modeli
class GroupMessage {
  final String senderId;
  final String senderName;
  final String senderAvatarUrl;
  final String text;
  final Timestamp? timestamp;

  GroupMessage({
    required this.senderId,
    required this.senderName,
    required this.senderAvatarUrl,
    required this.text,
    required this.timestamp,
  });

  factory GroupMessage.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return GroupMessage(
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Bilinmeyen',
      senderAvatarUrl: data['senderAvatarUrl'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'],
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

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser;

  String _userName = 'Kullanıcı';
  String _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserDataAndJoinRoom();
  }

  @override
  void dispose() {
    _leaveRoom();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDataAndJoinRoom() async {
    if (currentUser == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['displayName'] ?? 'Kullanıcı';
          _avatarUrl = userDoc.data()?['avatarUrl'] ?? '';
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
      // Hata yönetimi
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
    if (_messageController.text.trim().isEmpty || currentUser == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    FirebaseFirestore.instance
        .collection('group_chats')
        .doc(widget.roomId) // Her oda için benzersiz bir döküman
        .collection('messages')
        .add({
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': currentUser!.uid,
      'senderName': _userName,
      'senderAvatarUrl': _avatarUrl,
    });

    // Mesaj gönderildiğinde en alta kaydır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

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
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Sohbeti başlat!"));
                }

                final messages = snapshot.data!.docs;

                // Yeni mesaj geldiğinde en alta kaydır
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = GroupMessage.fromFirestore(messages[index]);
                    final isMe = message.senderId == currentUser?.uid;
                    return _buildMessageBubble(message, isMe);
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

  Widget _buildMessageBubble(GroupMessage message, bool isMe) {
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isMe ? Colors.teal.shade300 : Colors.grey.shade200;
    final textColor = isMe ? Colors.white : Colors.black87;

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
                    child: Text(
                      message.senderName,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
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
                  child: Text(
                    message.text,
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                ),
                if (message.timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      DateFormat('HH:mm').format(message.timestamp!.toDate()),
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
}