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
import 'package:lingua_chat/services/admin_service.dart';
import 'package:lingua_chat/screens/ban_user_screen.dart';
import 'package:lingua_chat/services/block_service.dart';


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
  bool _isUserPremium = false;
  bool _shimmerStarted = false;
  bool _canBan = false;
  bool _isPrivileged = false; // admin veya moderator

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.likes.contains(currentUser?.uid);
    likeCount = widget.post.likes.length;
    _checkBanPermission();
    _fetchRole();

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

  Future<void> _checkBanPermission() async {
    try {
      final allowed = await AdminService().canBanUser(widget.post.userId);
      if (mounted) setState(() => _canBan = allowed);
    } catch (_) {
      if (mounted) setState(() => _canBan = false);
    }
  }

  Future<void> _fetchRole() async {
    try {
      final role = await AdminService().getCurrentUserRole();
      if (mounted) {
        setState(() => _isPrivileged = role == 'admin' || role == 'moderator');
      }
    } catch (_) {
      if (mounted) setState(() => _isPrivileged = false);
    }
  }

  Future<void> _toggleLike() async {
    if (currentUser == null) return;

    final prevLiked = isLiked;
    final prevCount = likeCount;

    setState(() {
      isLiked = !isLiked;
      likeCount = isLiked ? likeCount + 1 : likeCount - 1;
    });

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.post.id);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(postRef);
        if (!snap.exists) throw Exception('Gönderi bulunamadı');
        final data = snap.data() as Map<String, dynamic>;
        final List<dynamic> raw = (data['likes'] as List<dynamic>? ) ?? [];
        final likes = raw.map((e) => e.toString()).toList();
        final uid = currentUser!.uid;
        if (isLiked) {
          if (!likes.contains(uid)) {
            likes.add(uid);
          }
        } else {
          likes.remove(uid);
        }
        tx.update(postRef, {'likes': likes});
      });
    } catch (e) {
      // Geri al
      if (mounted) {
        setState(() {
          isLiked = prevLiked;
          likeCount = prevCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Beğeni güncellenemedi: ${e.toString()}')),
        );
      }
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

  Future<void> _blockUser() async {
    final me = currentUser;
    if (me == null) return;
    try {
      await BlockService().blockUser(currentUserId: me.uid, targetUserId: widget.post.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kullanıcı engellendi.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
      }
    }
  }

  Future<void> _unblockUser() async {
    final me = currentUser;
    if (me == null) return;
    try {
      await BlockService().unblockUser(currentUserId: me.uid, targetUserId: widget.post.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Engel kaldırıldı.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
      }
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
    // Rol renkleri
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
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KULLANICI BAŞLIĞI: users/{userId} dokümanını canlı dinle
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.post.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                String displayName = widget.post.userName;
                String avatarUrl = widget.post.userAvatarUrl;
                bool isPremium = _isUserPremium;
                String? role;

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  displayName = (data['displayName'] as String?)?.trim().isNotEmpty == true
                      ? data['displayName']
                      : displayName;
                  avatarUrl = (data['avatarUrl'] as String?)?.trim().isNotEmpty == true
                      ? data['avatarUrl']
                      : avatarUrl;
                  isPremium = (data['isPremium'] as bool?) ?? false;
                  role = data['role'] as String?;
                  _isUserPremium = isPremium;
                  if (isPremium && !_shimmerStarted) {
                    _shimmerStarted = true;
                    _shimmerController.forward();
                  }
                }

                final baseColor = roleColor(role);

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade200,
                      child: ClipOval(
                        child: avatarUrl.isNotEmpty
                            ? SvgPicture.network(
                                avatarUrl,
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
                                child: isPremium
                                    ? AnimatedBuilder(
                                        animation: _shimmerController,
                                        builder: (context, child) {
                                          final highlightColor = Colors.white;
                                          final value = _shimmerController.value;
                                          final start = value * 1.5 - 0.5;
                                          final end = value * 1.5;
                                          final bool isSpecialRole = (role == 'admin' || role == 'moderator');
                                          final Color shimmerBase = isSpecialRole ? baseColor : const Color(0xFFE5B53A);
                                          return ShaderMask(
                                            blendMode: BlendMode.srcIn,
                                            shaderCallback: (bounds) => LinearGradient(
                                              colors: [shimmerBase, highlightColor, shimmerBase],
                                              stops: [start, (start + end) / 2, end]
                                                  .map((e) => e.clamp(0.0, 1.0))
                                                  .toList(),
                                            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                                            child: child,
                                          );
                                        },
                                        child: Text(
                                          displayName,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: (role == 'admin' || role == 'moderator') ? baseColor : const Color(0xFFE5B53A)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    : Text(
                                        displayName,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: baseColor),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ),
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
                                reportedContentId: widget.post.id, // içerik id eklendi
                              ),
                            ),
                          );
                        } else if (value == 'ban') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BanUserScreen(targetUserId: widget.post.userId),
                            ),
                          );
                        } else if (value == 'block') {
                          _blockUser();
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        List<PopupMenuEntry<String>> items = [];
                        if (isAuthor || _isPrivileged) {
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
                        }
                        if (!isAuthor) {
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
                          items.add(
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
                          );
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
                        }
                        return items;
                      },
                    ),
                  ],
                );
              },
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
