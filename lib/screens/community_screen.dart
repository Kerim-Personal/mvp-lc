// lib/screens/community_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
import 'package:lingua_chat/screens/group_chat_screen.dart';

// --- Mock Data Models (Gerçek veriler için Firebase'den çekilecek) ---

// Liderlik tablosu için örnek kullanıcı modeli
class LeaderboardUser {
  final String name;
  final String avatarUrl;
  final int streak;
  final int rank;

  LeaderboardUser({required this.name, required this.avatarUrl, required this.streak, required this.rank});
}

// Akış gönderileri için örnek model
class FeedPost {
  final String userName;
  final String userAvatarUrl;
  final String postText;
  final String timeAgo;
  final int likeCount;
  final int commentCount;

  FeedPost({
    required this.userName,
    required this.userAvatarUrl,
    required this.postText,
    required this.timeAgo,
    this.likeCount = 0,
    this.commentCount = 0,
  });
}

// Sohbet odası modeli
class GroupChatRoom {
  final String name;
  final String description;
  final IconData icon;
  final int members;
  final Color color1;
  final Color color2;

  GroupChatRoom({required this.name, required this.description, required this.icon, required this.members, required this.color1, required this.color2});
}


// --- Main Screen Widget ---

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Örnek Veriler (Bu kısımlar daha sonra Firebase'den gelecek)
  final List<LeaderboardUser> _users = List.generate(20, (index) {
    final random = Random();
    return LeaderboardUser(
      rank: index + 1,
      name: 'User_${random.nextInt(1000)}',
      avatarUrl: 'https://api.dicebear.com/8.x/micah/svg?seed=${random.nextInt(1000)}',
      streak: 150 - (index * random.nextInt(5)) - 10,
    );
  });

  final List<FeedPost> _posts = [
    FeedPost(userName: 'Gezgin_Ayşe', userAvatarUrl: 'https://api.dicebear.com/8.x/micah/svg?seed=ayse', postText: 'Bugün "serendipity" kelimesini öğrendim ve partnerimle sohbette kullandım! Anlamı "beklenmedik anda değerli bir şey bulma şansı" demekmiş. ✨ #newword', timeAgo: '15 dk önce', likeCount: 23, commentCount: 4),
    FeedPost(userName: 'Bookworm_Ali', userAvatarUrl: 'https://api.dicebear.com/8.x/micah/svg?seed=ali', postText: 'İngilizce kitap okuma serüvenimde yeni bir kitaba başladım. Herkese tavsiye ederim! 📚', timeAgo: '1 saat önce', likeCount: 45, commentCount: 8),
    FeedPost(userName: 'Traveler_Ece', userAvatarUrl: 'https://api.dicebear.com/8.x/micah/svg?seed=ece', postText: 'İspanyolca pratiği yaparken İspanya\'dan biriyle tanıştım ve bana yerel yemek tarifleri verdi! Bu uygulama harika. 🥘', timeAgo: '3 saat önce', likeCount: 78, commentCount: 12),
  ];

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topluluk'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        automaticallyImplyLeading: false,
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

  // Liderlik Tablosu Listesi
  Widget _buildLeaderboardList() {
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return LeaderboardListItem(user: user);
      },
    );
  }

  // Sosyal Akış Listesi
  Widget _buildFeedList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return FeedPostCard(post: post);
      },
    );
  }

  // Grup Sohbet Odaları Listesi
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


// --- Custom Widgets for Community Screen ---

// Liderlik Tablosu için özel liste elemanı
class LeaderboardListItem extends StatelessWidget {
  final LeaderboardUser user;
  const LeaderboardListItem({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Text(
              '#${user.rank}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: user.rank <= 3 ? Colors.amber.shade700 : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              child: ClipOval(
                child: SvgPicture.network(
                  user.avatarUrl,
                  placeholderBuilder: (context) => const CircularProgressIndicator(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                Icon(Icons.local_fire_department_rounded, color: Colors.orange.shade600, size: 20),
                const SizedBox(width: 4),
                Text(
                  user.streak.toString(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// Akış gönderileri için özel kart
class FeedPostCard extends StatelessWidget {
  final FeedPost post;
  const FeedPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
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
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade200,
                  child: ClipOval(
                    child: SvgPicture.network(
                      post.userAvatarUrl,
                      placeholderBuilder: (context) => const CircularProgressIndicator(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(post.timeAgo, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Post Text
            Text(post.postText, style: const TextStyle(fontSize: 15, height: 1.4)),
            const SizedBox(height: 16),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(icon: Icons.favorite_border_outlined, text: '${post.likeCount} Beğeni'),
                _buildActionButton(icon: Icons.chat_bubble_outline_rounded, text: '${post.commentCount} Yorum'),
                _buildActionButton(icon: Icons.share_outlined, text: 'Paylaş'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// Grup Sohbet Odası Kartı
class GroupChatCard extends StatelessWidget {
  final GroupChatRoom room;
  const GroupChatCard({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: room.color1.withOpacity(0.4),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupChatScreen(roomName: room.name, roomIcon: room.icon),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [room.color1, room.color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(room.icon, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    room.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                room.description,
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.person_outline, color: Colors.white.withOpacity(0.8), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${room.members} üye',
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}