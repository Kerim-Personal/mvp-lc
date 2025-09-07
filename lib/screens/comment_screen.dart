// lib/screens/comment_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/widgets/message_composer.dart';

// Comment data model
class Comment {
  final String text;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final Timestamp timestamp;

  Comment({
    required this.text,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.timestamp,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Comment(
      text: data['text'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userAvatarUrl: data['userAvatarUrl'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class CommentScreen extends StatefulWidget {
  final String postId;

  const CommentScreen({super.key, required this.postId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> with TickerProviderStateMixin {
  late final AnimationController _nameShimmerController;
  late final Stream<QuerySnapshot> _commentsStream;
  final currentUser = FirebaseAuth.instance.currentUser;
  String _nativeLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _nameShimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _nameShimmerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _nameShimmerController.forward(from: 0);
        });
      }
    });
    _nameShimmerController.forward();
    _commentsStream = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots();
    _loadNativeLanguage();
  }

  Future<void> _loadNativeLanguage() async {
    try {
      if (currentUser == null) return;
      final snap = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      final code = (snap.data()?['nativeLanguage'] as String?)?.trim().toLowerCase();
      if (code != null && code.isNotEmpty && code != _nativeLanguage) {
        if (mounted) setState(() => _nativeLanguage = code);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameShimmerController.dispose();
    super.dispose();
  }

  Future<void> _postComment(String text) async {
    if (text.trim().isEmpty || currentUser == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    if (!mounted) return;
    final userData = userDoc.data();
    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    await postRef.collection('comments').add({
      'text': text.trim(),
      'userId': currentUser!.uid,
      'userName': userData?['displayName'] ?? 'Unknown User',
      'userAvatarUrl': userData?['avatarUrl'] ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });
    await postRef.update({'commentCount': FieldValue.increment(1)});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Comments'), elevation: 1),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _commentsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Be the first to comment!'));
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final comment = Comment.fromFirestore(doc);
                      return KeyedSubtree(
                        key: ValueKey(doc.id),
                        child: RepaintBoundary(child: _buildCommentTile(comment)),
                      );
                    },
                  );
                },
              ),
            ),
            MessageComposer(
              onSend: _postComment,
              nativeLanguage: _nativeLanguage,
              enableTranslation: _nativeLanguage != 'en',
              enableSpeech: true,
              enableEmojis: true,
              hintText: 'Type your comment…',
              characterLimit: 1000,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTile(Comment comment) {
    Color roleColor(String? role) {
      switch (role) {
        case 'admin':
          return Colors.red;
        case 'moderator':
          return Colors.orange;
        default:
          return Colors.black87;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              child: ClipOval(
                child: comment.userAvatarUrl.isNotEmpty
                    ? SvgPicture.network(
                  comment.userAvatarUrl,
                  placeholderBuilder: (context) => const SizedBox.shrink(),
                )
                    : const Icon(Icons.person),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(comment.userId).snapshots(),
                    builder: (context, snapshot) {
                      String displayName = comment.userName;
                      String? role;
                      bool isPremium = false;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        displayName = (data['displayName'] as String?)?.trim().isNotEmpty == true ? data['displayName'] : displayName;
                        role = data['role'] as String?;
                        isPremium = data['isPremium'] == true;
                      }
                      final baseColor = roleColor(role);
                      Widget name = Text(
                        displayName,
                        style: TextStyle(fontWeight: FontWeight.bold, color: baseColor),
                      );
                      if (isPremium) {
                        final bool isSpecialRole = (role == 'admin' || role == 'moderator');
                        final Color shimmerBase = isSpecialRole ? baseColor : const Color(0xFFE5B53A);
                        name = AnimatedBuilder(
                          animation: _nameShimmerController,
                          builder: (context, child) {
                            final value = _nameShimmerController.value;
                            final start = value * 1.5 - 0.5;
                            final end = value * 1.5;
                            return ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [shimmerBase, Colors.white, shimmerBase],
                                stops: [start, (start + end) / 2, end]
                                    .map((e) => e.clamp(0.0, 1.0))
                                    .toList(),
                              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                              child: child!,
                            );
                          },
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSpecialRole ? baseColor : const Color(0xFFE5B53A),
                            ),
                          ),
                        );
                      }
                      return name;
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(comment.text),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'en_US').format(comment.timestamp.toDate()),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}