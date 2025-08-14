// lib/widgets/community_screen/feed_post_card.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingua_chat/screens/community_screen.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/screens/comment_screen.dart';
import 'package:lingua_chat/screens/report_user_screen.dart';


class FeedPostCard extends StatefulWidget {
  final FeedPost post;
  const FeedPostCard({super.key, required this.post});

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> with TickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser;
  late bool isLiked;
  late int likeCount;
  late AnimationController _shimmerController;
  // YENİ: Kullanıcının premium durumunu tutacak state
  bool _isUserPremium = false;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.likes.contains(currentUser?.uid);
    likeCount = widget.post.likes.length;
    // YENİ: Widget oluşturulduğunda kullanıcının premium durumunu anlık olarak çek.
    _fetchUserPremiumStatus();

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
    _shimmerController.dispose();
    super.dispose();
  }

  // YENİ: Kullanıcının anlık premium durumunu Firestore'dan çeken fonksiyon.
  Future<void> _fetchUserPremiumStatus() async {
    if (widget.post.userId.isEmpty) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.post.userId)
          .get();
      if (userDoc.exists && mounted) {
        setState(() {
          _isUserPremium = userDoc.data()?['isPremium'] ?? false;
        });
        // Eğer premium ise animasyonu başlat
        if (_isUserPremium) {
          _shimmerController.forward();
        }
      }
    } catch (e) {
      // Hata yönetimi (isteğe bağlı)
      print("Premium durumu çekilirken hata: $e");
    }
  }


  Future<void> _toggleLike() async {
    if (currentUser == null) return;

    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        likeCount++;
      } else {
        likeCount--;
      }
    });

    final postRef =
    FirebaseFirestore.instance.collection('posts').doc(widget.post.id);

    if (isLiked) {
      await postRef.update({
        'likes': FieldValue.arrayUnion([currentUser!.uid])
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayRemove([currentUser!.uid])
      });
    }
  }

  Future<void> _deletePost() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gönderiyi Sil'),
        content: const Text('Bu gönderiyi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .delete();
    }
  }

  String _timeAgo(Timestamp timestamp) {
    final difference = DateTime.now().difference(timestamp.toDate());
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} sn önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} sa önce';
    } else {
      return DateFormat('dd MMM yyyy', 'tr_TR').format(timestamp.toDate());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthor = currentUser?.uid == widget.post.userId;
    const premiumColor = Color(0xFFE5B53A);
    const premiumIcon = Icons.auto_awesome;

    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade200,
                  child: ClipOval(
                    child: widget.post.userAvatarUrl.isNotEmpty
                        ? SvgPicture.network(
                      widget.post.userAvatarUrl,
                      placeholderBuilder: (context) =>
                      const CircularProgressIndicator(),
                    )
                        : const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            // DEĞİŞİKLİK: 'widget.post.isUserPremium' yerine state'deki '_isUserPremium' kullanıldı.
                            child: _isUserPremium
                                ? AnimatedBuilder(
                              animation: _shimmerController,
                              builder: (context, child) {
                                final highlightColor = Colors.white;
                                final value = _shimmerController.value;
                                final start = value * 1.5 - 0.5;
                                final end = value * 1.5;
                                return ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [premiumColor, highlightColor, premiumColor],
                                    stops: [start, (start + end) / 2, end],
                                  ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                                  child: child,
                                );
                              },
                              child: Text(widget.post.userName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: premiumColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                                : Text(widget.post.userName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // DEĞİŞİKLİK: 'widget.post.isUserPremium' yerine state'deki '_isUserPremium' kullanıldı.
                          if(_isUserPremium) ...[
                            const SizedBox(width: 4),
                            const Icon(premiumIcon, color: premiumColor, size: 16),
                          ]
                        ],
                      ),
                      Text(_timeAgo(widget.post.timestamp),
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deletePost();
                    } else if (value == 'report') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportUserScreen(
                            reportedUserId: widget.post.userId,
                            reportedContent: widget.post.postText,
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    List<PopupMenuEntry<String>> items = [];
                    if (isAuthor) {
                      items.add(
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Sil'),
                            ],
                          ),
                        ),
                      );
                    } else {
                      items.add(
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
                      );
                    }
                    return items;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(widget.post.postText,
                style: const TextStyle(fontSize: 15, height: 1.4)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(
                  icon:
                  isLiked ? Icons.favorite : Icons.favorite_border_outlined,
                  text: '$likeCount Beğeni',
                  color: isLiked ? Colors.red : Colors.grey.shade700,
                  onTap: _toggleLike,
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  text: '${widget.post.commentCount} Yorum',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommentScreen(postId: widget.post.id),
                      ),
                    );
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
        required String text,
        Color? color,
        required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey.shade700),
            const SizedBox(width: 6),
            Text(text,
                style: TextStyle(
                    color: color ?? Colors.grey.shade800,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}