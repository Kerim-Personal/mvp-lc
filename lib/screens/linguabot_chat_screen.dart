// lib/screens/linguabot_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/services/linguabot_service.dart';

// Mesaj veri modeli
class BotMessage {
  final String text;
  final bool isFromUser;

  BotMessage({required this.text, required this.isFromUser});
}

class LinguaBotChatScreen extends StatefulWidget {
  const LinguaBotChatScreen({super.key});

  @override
  State<LinguaBotChatScreen> createState() => _LinguaBotChatScreenState();
}

class _LinguaBotChatScreenState extends State<LinguaBotChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final LinguaBotService _botService = LinguaBotService();

  final List<BotMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Botun ilk karşılama mesajı
    _messages.add(BotMessage(
        text: 'Merhaba! Ben LinguaBot. Dil pratiği yapmak için hazırım. Bana bir şeyler söyle!',
        isFromUser: false));
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessageText = _messageController.text.trim();
    _messageController.clear();

    // Kullanıcının mesajını ekle
    setState(() {
      _messages.add(BotMessage(text: userMessageText, isFromUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    // Bot'tan cevabı al ve ekle
    final botResponse = await _botService.sendMessage(userMessageText);
    setState(() {
      _messages.add(BotMessage(text: botResponse, isFromUser: false));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
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
        title: const Row(
          children: [
            Icon(Icons.smart_toy_outlined),
            SizedBox(width: 8),
            Text('LinguaBot'),
          ],
        ),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BotMessage message) {
    final isUser = message.isFromUser;
    final alignment = isUser ? MainAxisAlignment.end : MainAxisAlignment.start;
    final color = isUser ? Colors.teal.shade300 : Colors.grey.shade200;
    final textColor = isUser ? Colors.white : Colors.black87;

    return Row(
      mainAxisAlignment: alignment,
      children: [
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20).subtract(
                isUser
                    ? const BorderRadius.only(bottomRight: Radius.circular(16))
                    : const BorderRadius.only(bottomLeft: Radius.circular(16)),
              ),
            ),
            child: Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 5,
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _isLoading ? null : _sendMessage(),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Mesajını yaz...',
                  filled: true,
                  fillColor: Colors.grey.withAlpha(50),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send_rounded),
              color: _isLoading ? Colors.grey : Colors.purple,
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}