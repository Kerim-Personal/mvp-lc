// lib/screens/comment_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

// Yorum veri modeli
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
      userName: data['userName'] ?? 'Bilinmeyen',
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

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || currentUser == null) {
      return;
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    final userData = userDoc.data();

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    // Yorumu 'comments' alt koleksiyonuna ekle
    await postRef.collection('comments').add({
      'text': _commentController.text.trim(),
      'userId': currentUser!.uid,
      'userName': userData?['displayName'] ?? 'Bilinmeyen Kullanıcı',
      'userAvatarUrl': userData?['avatarUrl'] ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Gönderideki yorum sayısını artır
    await postRef.update({'commentCount': FieldValue.increment(1)});

    _commentController.clear();
    FocusScope.of(context).unfocus(); // Klavyeyi kapat
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yorumlar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('İlk yorumu sen yap!'));
                }
                final comments = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = Comment.fromFirestore(comments[index]);
                    return _buildCommentTile(comment);
                  },
                );
              },
            ),
          ),
          _buildCommentComposer(),
        ],
      ),
    );
  }

  Widget _buildCommentTile(Comment comment) {
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
                  Text(
                    comment.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(comment.text),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(comment.timestamp.toDate()),
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

  Widget _buildCommentComposer() {
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
                controller: _commentController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Yorumunu yaz...',
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
              color: Colors.teal,
              onPressed: _postComment,
            ),
          ],
        ),
      ),
    );
  }
}