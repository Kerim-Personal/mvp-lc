// lib/screens/community_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lingua_chat/widgets/community_screen/leaderboard_table.dart';
import 'package:lingua_chat/widgets/community_screen/feed_post_card.dart';
import 'package:lingua_chat/widgets/community_screen/group_chat_card.dart';

// --- DATA MODELLERİ ---
class LeaderboardUser {
  final String name;
  final String avatarUrl;
  final int rank;
  final int partnerCount;

  LeaderboardUser({
    required this.name,
    required this.avatarUrl,
    required this.rank,
    required this.partnerCount,
  });
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
    final List<String> likes =
    likesData.map((item) => item.toString()).toList();

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
  final bool isFeatured;

  GroupChatRoom({
    required this.name,
    required this.description,
    required this.icon,
    required this.members,
    required this.color1,
    required this.color2,
    this.isFeatured = false,
  });
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
  late Future<List<LeaderboardUser>> _leaderboardFuture;
  final String _leaderboardPeriod = 'partnerCount';

  final List<GroupChatRoom> _chatRooms = [
    GroupChatRoom(
        name: "Müzik Kutusu",
        description: "Farklı türlerden müzikler keşfedin ve favori sanatçılarınızı paylaşın.",
        icon: Icons.music_note_outlined,
        members: 215,
        color1: Colors.pink.shade300,
        color2: Colors.red.shade400,
        isFeatured: true),
    GroupChatRoom(
        name: "Film & Dizi Kulübü",
        description: "Haftanın popüler yapımlarını ve kült klasiklerini tartışın.",
        icon: Icons.movie_filter_outlined,
        members: 128,
        color1: Colors.purple.shade400,
        color2: Colors.indigo.shade500),
    GroupChatRoom(
        name: "Gezginler Durağı",
        description: "Seyahat anılarınızı ve bir sonraki macera için ipuçlarınızı paylaşın.",
        icon: Icons.airplanemode_active_outlined,
        members: 89,
        color1: Colors.orange.shade400,
        color2: Colors.deepOrange.shade500),
    GroupChatRoom(
        name: "Teknoloji Tayfası",
        description: "En yeni gadget'ları, yazılımları ve gelecek teknolojilerini konuşun.",
        icon: Icons.computer_outlined,
        members: 150,
        color1: Colors.blue.shade500,
        color2: Colors.cyan.shade600),
    GroupChatRoom(
        name: "Kitap Kurtları",
        description: "Okuduğunuz kitaplar hakkında derinlemesine sohbet edin.",
        icon: Icons.menu_book_outlined,
        members: 76,
        color1: Colors.brown.shade400,
        color2: Colors.brown.shade600),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _leaderboardFuture = _fetchLeaderboardData();
  }

  Future<List<LeaderboardUser>> _fetchLeaderboardData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy(_leaderboardPeriod, descending: true)
        .limit(20)
        .get();

    if (snapshot.docs.isEmpty) return [];
    return snapshot.docs.asMap().entries.map((entry) {
      int rank = entry.key + 1;
      Map<String, dynamic> data = entry.value.data();
      return LeaderboardUser(
        rank: rank,
        name: data['displayName'] ?? 'Bilinmeyen',
        avatarUrl: data['avatarUrl'] ?? '',
        partnerCount: data['partnerCount'] ?? 0,
      );
    }).toList();
  }

  @override
  void dispose() {
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
          FutureBuilder<List<LeaderboardUser>>(
            future: _leaderboardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Henüz liderlik verisi yok.'));
              }
              return LeaderboardTable(users: snapshot.data!);
            },
          ),
          _buildFeedList(),
          _buildRoomsTab(),
        ],
      ),
    );
  }

  Widget _buildRoomsTab() {
    return ListView(
      padding: const EdgeInsets.only(top: 24.0),
      children: [
        _buildSectionHeader("Haftanın Sahnesi"),
        _buildFeaturedRoomCard(),
        const SizedBox(height: 30),
        _buildSectionHeader("Popüler Odalar"),
        _buildRoomCategory(
          rooms: _chatRooms.where((r) => r.members > 100 && !r.isFeatured).toList(),
        ),
        const SizedBox(height: 30),
        _buildSectionHeader("Yeni Keşifler"),
        _buildRoomCategory(
          rooms: _chatRooms.where((r) => r.members <= 100).toList(),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildFeaturedRoomCard() {
    final featuredRoom = _chatRooms.firstWhere((r) => r.isFeatured);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: GroupChatCard(room: featuredRoom),
    );
  }

  Widget _buildRoomCategory({required List<GroupChatRoom> rooms}) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: rooms.length,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 280,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GroupChatCard(room: rooms[index]),
            ),
          );
        },
      ),
    );
  }

  // *** HATA DÜZELTMESİ BU FONKSİYONDA YAPILDI ***
  Widget _buildFeedList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // YÜKLENME DURUMU
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // HATA DURUMU
        if (snapshot.hasError) {
          return const Center(child: Text('Gönderiler yüklenemedi.\nLütfen tekrar deneyin.', textAlign: TextAlign.center));
        }
        // VERİ OLMAMA DURUMU (Boş liste veya null data)
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Henüz hiç gönderi yok.\nİlk gönderiyi sen paylaş!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        // VERİ BAŞARIYLA GELDİYSE
        final posts = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = FeedPost.fromFirestore(posts[index]);
            return FeedPostCard(post: post);
          },
        );
      },
    );
  }
}