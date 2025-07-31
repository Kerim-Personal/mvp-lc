// lib/screens/community_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Map<String, dynamic> toJson() => {
    'name': name,
    'avatarUrl': avatarUrl,
    'rank': rank,
    'partnerCount': partnerCount,
  };

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) => LeaderboardUser(
    name: json['name'] as String,
    avatarUrl: json['avatarUrl'] as String,
    rank: json['rank'] as int,
    partnerCount: json['partnerCount'] as int,
  );
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
    return FeedPost(
      id: doc.id,
      userName: data['userName'] ?? 'Bilinmiyor',
      userAvatarUrl: data['userAvatarUrl'] ?? '',
      userId: data['userId'] ?? '',
      postText: data['postText'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userName': userName,
    'userAvatarUrl': userAvatarUrl,
    'userId': userId,
    'postText': postText,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'likes': likes,
    'commentCount': commentCount,
  };

  factory FeedPost.fromJson(Map<String, dynamic> json) => FeedPost(
    id: json['id'] as String,
    userName: json['userName'] as String,
    userAvatarUrl: json['userAvatarUrl'] as String,
    userId: json['userId'] as String,
    postText: json['postText'] as String,
    timestamp: Timestamp.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    likes: List<String>.from(json['likes'] as List),
    commentCount: json['commentCount'] as int,
  );
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
  final String _leaderboardPeriod = 'partnerCount';

  List<LeaderboardUser>? _leaderboardUsers;
  bool _isLeaderboardLoading = true;

  List<FeedPost>? _feedPosts;
  bool _isFeedLoading = false;

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
    _loadOrFetchLeaderboard();
    _loadFeedFromCacheAndFetchLatest();
  }

  // --- LİDERLİK TABLOSU VERİ YÖNETİMİ ---
  Future<void> _loadOrFetchLeaderboard() async {
    setState(() => _isLeaderboardLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final lastFetchMillis = prefs.getInt('leaderboard_last_fetch');
    final oneHourInMillis = const Duration(hours: 1).inMilliseconds;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (lastFetchMillis != null && (now - lastFetchMillis < oneHourInMillis)) {
      final cachedDataString = prefs.getString('leaderboard_cache');
      if (cachedDataString != null) {
        final List<dynamic> jsonData = jsonDecode(cachedDataString);
        if (mounted) {
          setState(() {
            _leaderboardUsers = jsonData.map((item) => LeaderboardUser.fromJson(item)).toList();
            _isLeaderboardLoading = false;
          });
        }
        return;
      }
    }
    await _fetchAndCacheLeaderboardData();
  }

  Future<void> _fetchAndCacheLeaderboardData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').orderBy(_leaderboardPeriod, descending: true).limit(20).get();
      final users = snapshot.docs.asMap().entries.map((entry) {
        int rank = entry.key + 1;
        Map<String, dynamic> data = entry.value.data();
        return LeaderboardUser(
          rank: rank,
          name: data['displayName'] ?? 'Bilinmeyen',
          avatarUrl: data['avatarUrl'] ?? '',
          partnerCount: data['partnerCount'] ?? 0,
        );
      }).toList();

      if (mounted) {
        setState(() => _leaderboardUsers = users);
        final prefs = await SharedPreferences.getInstance();
        final dataToCache = jsonEncode(users.map((user) => user.toJson()).toList());
        await prefs.setString('leaderboard_cache', dataToCache);
        await prefs.setInt('leaderboard_last_fetch', DateTime.now().millisecondsSinceEpoch);
      }
    } finally {
      if (mounted) setState(() => _isLeaderboardLoading = false);
    }
  }

  // --- AKIŞ (FEED) VERİ YÖNETİMİ ---
  Future<void> _loadFeedFromCacheAndFetchLatest() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDataString = prefs.getString('feed_cache');
    if (cachedDataString != null) {
      final List<dynamic> jsonData = jsonDecode(cachedDataString);
      if (mounted) {
        setState(() {
          _feedPosts = jsonData.map((item) => FeedPost.fromJson(item)).toList();
        });
      }
    } else {
      setState(() => _isFeedLoading = true);
    }
    await _fetchAndCacheFeedData();
  }

  Future<void> _fetchAndCacheFeedData({bool isManualRefresh = false}) async {
    if (isManualRefresh && mounted) {
      setState(() => _isFeedLoading = true);
    }

    try {
      final snapshot = await FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).limit(20).get();
      final newPosts = snapshot.docs.map((doc) => FeedPost.fromFirestore(doc)).toList();
      final bool isDataDifferent = _feedPosts == null || _feedPosts!.length != newPosts.length || (_feedPosts!.isNotEmpty && _feedPosts!.first.id != newPosts.first.id);

      if (mounted && isDataDifferent) {
        setState(() => _feedPosts = newPosts);
        final prefs = await SharedPreferences.getInstance();
        final dataToCache = jsonEncode(newPosts.map((post) => post.toJson()).toList());
        await prefs.setString('feed_cache', dataToCache);
      }
    } finally {
      if (mounted) setState(() => _isFeedLoading = false);
    }
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
                  if (postController.text.trim().isEmpty || currentUser == null) {
                    return;
                  }
                  final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
                  final userData = userDoc.data();
                  await FirebaseFirestore.instance.collection('posts').add({
                    'postText': postController.text.trim(),
                    'userId': currentUser.uid,
                    'userName': userData?['displayName'] ?? 'Bilinmeyen Kullanıcı',
                    'userAvatarUrl': userData?['avatarUrl'] ?? '',
                    'timestamp': FieldValue.serverTimestamp(),
                    'likes': [],
                    'commentCount': 0,
                  });
                  if (mounted) Navigator.pop(context);
                  _fetchAndCacheFeedData(isManualRefresh: true);
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
        tooltip: 'Yeni Gönderi',
        child: const Icon(Icons.add),
      )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardTab(),
          _buildFeedList(),
          _buildRoomsTab(),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    if (_isLeaderboardLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_leaderboardUsers == null || _leaderboardUsers!.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchAndCacheLeaderboardData,
        child: const Center(child: Text('Henüz liderlik verisi yok.')),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchAndCacheLeaderboardData,
      child: LeaderboardTable(users: _leaderboardUsers!),
    );
  }

  Widget _buildRoomsTab() {
    return ListView(
      padding: const EdgeInsets.only(top: 24.0),
      children: [
        _buildSectionHeader("Haftanın Sahnesi"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: GroupChatCard(room: _chatRooms.firstWhere((r) => r.isFeatured)),
        ),
        const SizedBox(height: 30),
        _buildSectionHeader("Tüm Odalar"),
        _buildRoomCategory(
          rooms: _chatRooms.where((r) => !r.isFeatured).toList(),
        ),
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

  Widget _buildRoomCategory({required List<GroupChatRoom> rooms}) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rooms.length,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: GroupChatCard(room: rooms[index]),
        );
      },
    );
  }

  Widget _buildFeedList() {
    if (_isFeedLoading && _feedPosts == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_feedPosts == null || _feedPosts!.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchAndCacheFeedData(isManualRefresh: true),
        child: const Center(
          child: Text(
            'Henüz hiç gönderi yok.\nİlk gönderiyi sen paylaş!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchAndCacheFeedData(isManualRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0),
        itemCount: _feedPosts!.length,
        itemBuilder: (context, index) {
          final post = _feedPosts![index];
          return FeedPostCard(post: post);
        },
      ),
    );
  }
}