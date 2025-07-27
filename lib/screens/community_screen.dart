// lib/screens/community_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';

// Widget'ları kendi dosyalarından import ediyoruz
import 'package:lingua_chat/widgets/community_screen/leaderboard_list_item.dart';
import 'package:lingua_chat/widgets/community_screen/feed_post_card.dart';
import 'package:lingua_chat/widgets/community_screen/group_chat_card.dart';

// --- DATA MODELLERİ ---
class LeaderboardUser {
  final String name;
  final String avatarUrl;
  final int streak;
  final int rank;

  LeaderboardUser(
      {required this.name,
        required this.avatarUrl,
        required this.streak,
        required this.rank});
}

class FeedPost {
  final String id;
  final String userName;
  final String userAvatarUrl;
  final String userId;
  final String postText;
  final Timestamp timestamp;
  final List<String> likes;
  final int commentCount;

  FeedPost({
    required this.id,
    required this.userName,
    required this.userAvatarUrl,
    required this.userId,
    required this.postText,
    required this.timestamp,
    required this.likes,
    this.commentCount = 0,
  });

  factory FeedPost.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final List<dynamic> likesData = data['likes'] ?? [];
    final List<String> likes = likesData.map((item) => item.toString()).toList();

    return FeedPost(
      id: doc.id,
      userName: data['userName'] ?? 'Bilinmiyor',
      userAvatarUrl: data['userAvatarUrl'] ?? '',
      userId: data['userId'] ?? '',
      postText: data['postText'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      likes: likes,
      commentCount: data['commentCount'] ?? 0,
    );
  }
}

class GroupChatRoom {
  final String name;
  final String description;
  final IconData icon;
  final int members;
  final Color color1;
  final Color color2;

  GroupChatRoom(
      {required this.name,
        required this.description,
        required this.icon,
        required this.members,
        required this.color1,
        required this.color2});
}

// --- ANA EKRAN WIDGET'I ---
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<LeaderboardUser> _users = List.generate(20, (index) {
    final random = Random();
    return LeaderboardUser(
      rank: index + 1,
      name: 'User_${random.nextInt(1000)}',
      avatarUrl:
      'https://api.dicebear.com/8.x/micah/svg?seed=${random.nextInt(1000)}',
      streak: 150 - (index * random.nextInt(5)) - 10,
    );
  });

  final List<GroupChatRoom> _chatRooms = [
    GroupChatRoom(name: "Film & Dizi Kulübü", description: "Haftanın popüler yapımlarını tartışın.", icon: Icons.movie_filter_outlined, members: 128, color1: Colors.purple.shade300, color2: Colors.indigo.shade400),
    GroupChatRoom(name: "Gezginler Durağı", description: "Seyahat anılarınızı ve ipuçlarınızı paylaşın.", icon: Icons.airplanemode_active_outlined, members: 89, color1: Colors.orange.shade300, color2: Colors.red.shade400),
    GroupChatRoom(name: "Müzik Kutusu", description: "Farklı türlerden müzikler keşfedin.", icon: Icons.music_note_outlined, members: 215, color1: Colors.pink.shade300, color2: Colors.red.shade300),
    GroupChatRoom(name: "Kitap Kurtları", description: "Okuduğunuz kitaplar hakkında konuşun.", icon: Icons.menu_book_outlined, members: 76, color1: Colors.brown.shade300, color2: Colors.brown.shade500),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    super.dispose();
  }

  void _showCreatePostModal(BuildContext context) {
    final TextEditingController postController = TextEditingController();
    final currentUser = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Yeni Gönderi Oluştur',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: postController,
                autofocus: true,
                maxLines: 5,
                maxLength: 280,
                decoration: InputDecoration(
                  hintText: 'Ne düşünüyorsun?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (postController.text.trim().isEmpty ||
                      currentUser == null) {
                    return;
                  }

                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .get();
                  final userData = userDoc.data();

                  await FirebaseFirestore.instance.collection('posts').add({
                    'postText': postController.text.trim(),
                    'userId': currentUser.uid,
                    'userName':
                    userData?['displayName'] ?? 'Bilinmeyen Kullanıcı',
                    'userAvatarUrl': userData?['avatarUrl'] ?? '',
                    'timestamp': FieldValue.serverTimestamp(),
                    'likes': [],
                    'commentCount': 0,
                  });

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Paylaş'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.teal,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Liderlik', icon: Icon(Icons.leaderboard_outlined)),
            Tab(text: 'Akış', icon: Icon(Icons.dynamic_feed_outlined)),
            Tab(text: 'Odalar', icon: Icon(Icons.chat_bubble_outline_rounded)),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
        onPressed: () => _showCreatePostModal(context),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Yeni Gönderi',
      )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardList(),
          _buildFeedList(),
          _buildGroupChatList(),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList() {
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return LeaderboardListItem(user: user);
      },
    );
  }

  Widget _buildFeedList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Henüz hiç gönderi yok.\nİlk gönderiyi sen paylaş!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          padding:
          const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0), // FAB için boşluk
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = FeedPost.fromFirestore(posts[index]);
            return FeedPostCard(post: post);
          },
        );
      },
    );
  }

  Widget _buildGroupChatList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: _chatRooms.length,
      itemBuilder: (context, index) {
        final room = _chatRooms[index];
        return GroupChatCard(room: room);
      },
    );
  }
}