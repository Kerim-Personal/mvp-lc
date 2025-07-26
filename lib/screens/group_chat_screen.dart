// lib/screens/group_chat_screen.dart

import 'package:flutter/material.dart';
import 'dart:math';

// Örnek mesaj modeli
class GroupMessage {
  final String senderName;
  final String text;
  final bool isMe;

  GroupMessage({required this.senderName, required this.text, required this.isMe});
}

class GroupChatScreen extends StatefulWidget {
  final String roomName;
  final IconData roomIcon;

  const GroupChatScreen({super.key, required this.roomName, required this.roomIcon});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<GroupMessage> _messages = [
    GroupMessage(senderName: 'Ali', text: 'Hey everyone! Has anyone seen the new sci-fi movie?', isMe: false),
    GroupMessage(senderName: 'Ece', text: 'Yes! I saw it last weekend, it was amazing.', isMe: false),
    GroupMessage(senderName: 'You', text: 'I haven\'t seen it yet. Is it worth watching?', isMe: true),
    GroupMessage(senderName: 'Ali', text: 'Definitely! The special effects are incredible.', isMe: false),
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.add(
          GroupMessage(senderName: 'You', text: _messageController.text.trim(), isMe: true)
      );
      _messageController.clear();
      // Rastgele bir cevap ekleyelim (simülasyon için)
      Future.delayed(const Duration(seconds: 2), (){
        setState(() {
          _messages.add(
              GroupMessage(senderName: 'Zeynep', text: 'That\'s a great point!', isMe: false)
          );
        });
      });
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  // Mesaj balonu widget'ı
  Widget _buildMessageBubble(GroupMessage message) {
    final alignment = message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = message.isMe ? Colors.teal.shade300 : Colors.grey.shade200;
    final textColor = message.isMe ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (!message.isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
              child: Text(
                message.senderName,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Mesaj yazma alanı widget'ı
  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(offset: const Offset(0, -2), blurRadius: 5, color: Colors.black.withAlpha(10))
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide.none),
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