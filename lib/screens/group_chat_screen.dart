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

class _GroupChatScreenState extends State<GroupChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser;

  String _userName = 'Kullanıcı';
  String _avatarUrl = '';

  late final AnimationController _nameShimmerController;

  // Yeni: Engellediklerim (anlık filtre için)
  List<String> _blocked = const [];

  @override
  void initState() {
    super.initState();
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
  }

  void _listenMyBlocked() {
    final me = currentUser;
    if (me == null) return;
    FirebaseFirestore.instance.collection('users').doc(me.uid).snapshots().listen((snap) {
      final list = (snap.data()?['blockedUsers'] as List<dynamic>?)?.cast<String>() ?? const <String>[];
      if (mounted) setState(() => _blocked = list);
    });
  }

  @override
  void dispose() {
    _leaveRoom();
    _messageController.dispose();
    _scrollController.dispose();
    _nameShimmerController.dispose();
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

  Future<void> _showUserActionsDialog(GroupMessage message) async {
    final isMe = message.senderId == currentUser?.uid;
    if (isMe) return; // Kendini banlama/bildirme yok

    bool canBan = false;
    try {
      canBan = await AdminService().canBanUser(message.senderId);
    } catch (_) {
      canBan = false;
    }

    final me = currentUser;
    bool isBlocked = false;
    if (me != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(me.uid).get();
        final blocked = (userDoc.data()?['blockedUsers'] as List<dynamic>?)?.cast<String>() ?? const <String>[];
        isBlocked = blocked.contains(message.senderId);
      } catch (_) {}
    }

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
                title: const Text('Kullanıcıyı Bildir'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportUserScreen(
                        reportedUserId: message.senderId,
                        reportedContent: '"${message.text}" (Grup Sohbeti Mesajı)',
                      ),
                    ),
                  );
                },
              ),
              if (!isBlocked)
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text('Kullanıcıyı Engelle'),
                  onTap: () async {
                    Navigator.pop(context);
                    final me = currentUser;
                    if (me == null) return;
                    try {
                      await BlockService().blockUser(currentUserId: me.uid, targetUserId: message.senderId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kullanıcı engellendi.')));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
                      }
                    }
                  },
                ),
              if (canBan)
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text('Hesabı Banla'),
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

                final allDocs = snapshot.data!.docs;
                final docs = allDocs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final senderId = (data['senderId'] as String?) ?? '';
                  // Sadece benim engellediklerimi gizle
                  return !_blocked.contains(senderId);
                }).toList();

                // Yeni mesaj geldiğinde en alta kaydır
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final message = GroupMessage.fromFirestore(docs[index]);
                    final isMe = message.senderId == currentUser?.uid;
                    return GestureDetector(
                      onLongPress: () => _showUserActionsDialog(message),
                      child: _buildMessageBubble(message, isMe),
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
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(message.senderId).snapshots(),
                      builder: (context, snap) {
                        String name = message.senderName;
                        String? role;
                        bool isPremium = false;
                        if (snap.hasData && snap.data!.exists) {
                          final data = snap.data!.data() as Map<String, dynamic>;
                          name = (data['displayName'] as String?)?.trim().isNotEmpty == true ? data['displayName'] : name;
                          role = data['role'] as String?;
                          isPremium = data['isPremium'] == true;
                        }
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
                          style: TextStyle(fontSize: 12, color: baseColor),
                        );
                        if (isPremium) {
                          child = AnimatedBuilder(
                            animation: _nameShimmerController,
                            builder: (context, c) {
                              final value = _nameShimmerController.value;
                              final start = value * 1.5 - 0.5;
                              final end = value * 1.5;
                              return ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [baseColor, Colors.white, baseColor],
                                  stops: [start, (start + end) / 2, end],
                                ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                                child: c!,
                              );
                            },
                            child: child,
                          );
                        }
                        return child;
                      },
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