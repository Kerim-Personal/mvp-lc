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
  final bool isPremium;
  final String role; // admin/moderator/user

  LeaderboardUser({
    required this.name,
    required this.avatarUrl,
    required this.rank,
    required this.partnerCount,
    this.isPremium = false,
    this.role = 'user',
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
      userName: data['userName'] ?? 'Unknown',
      userAvatarUrl: data['userAvatarUrl'] ?? '',
      userId: data['userId'] ?? '',
      postText: data['postText'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      likes: likes,
      commentCount: data['commentCount'] ?? 0,
    );
  }
}

class GroupChatRoomInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color1;
  final Color color2;
  final bool isFeatured;
  // Denormalize alanlar (maliyet azaltımı)
  final int? memberCount;
  final List<String>? avatarsPreview;

  GroupChatRoomInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color1,
    required this.color2,
    this.isFeatured = false,
    this.memberCount,
    this.avatarsPreview,
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
  // late Future<List<LeaderboardUser>> _leaderboardFuture; // Kaldırıldı
  final String _leaderboardPeriod = 'partnerCount';

  late Future<QuerySnapshot> _feedFuture;
  late Future<QuerySnapshot> _roomsFuture;

  // Flicker azaltma cache'leri
  List<LeaderboardUser>? _leaderboardCache;
  bool _leaderboardLoading = false;
  Object? _leaderboardError;
  List<DocumentSnapshot>? _feedPostsCache;
  List<DocumentSnapshot>? _roomsDocsCache;

  // Kullanıcı rolü ve yetkileri için değişkenler
  bool _isPrivileged = false; // admin veya moderator mu
  bool _canBanOthers = false; // ban yetkisi
  bool _privilegeResolved = false;

  // Kullanıcı adı ve avatarı için cache
  String? _currentUserName;
  String? _currentUserAvatar;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _feedFuture = _fetchFeedData();
    _roomsFuture = _fetchRoomsData();
    _loadLeaderboard(initial: true);
    _resolvePrivilege();
    _prefetchCurrentUserMeta();
  }

  Future<void> _prefetchCurrentUserMeta() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      if (!mounted) return;
      setState(() {
        _currentUserName = (data['displayName'] as String?)?.trim().isNotEmpty == true ? data['displayName'] : 'Unknown User';
        _currentUserAvatar = (data['avatarUrl'] as String?)?.trim().isNotEmpty == true ? data['avatarUrl'] : '';
      });
    } catch (_) {/* sessiz */}
  }

  Future<void> _resolvePrivilege() async {
    try {
      final roleSnap = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get();
      String? role;
      if (roleSnap.exists) {
        role = (roleSnap.data()?['role'] as String?);
      }
      final isPriv = role == 'admin' || role == 'moderator';
      bool canBan = false;
      if (isPriv) {
        // basit politika: admin her kesi banlayabilir, moderator admin dışı
        canBan = true;
      }
      if (!mounted) return;
      setState(() {
        _isPrivileged = isPriv;
        _canBanOthers = canBan;
        _privilegeResolved = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _privilegeResolved = true; });
    }
  }

  Future<void> _loadLeaderboard({bool force = false, bool initial = false}) async {
    if (_leaderboardLoading) return; // eşzamanlı istek engelle
    if (!force && !initial && _leaderboardCache != null) return; // zaten var, zorunlu değil
    setState(() {
      _leaderboardLoading = true;
      if (force) _leaderboardError = null; // yenilemede önceki hatayı temizle
    });
    try {
      final data = await _fetchLeaderboardData();
      if (!mounted) return;
      setState(() {
        _leaderboardCache = data;
        _leaderboardLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _leaderboardError = e;
        _leaderboardLoading = false;
      });
    }
  }

  Future<void> _refreshLeaderboard() async {
    await _loadLeaderboard(force: true);
  }


  Future<QuerySnapshot> _fetchFeedData() {
    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .get();
  }

  Future<QuerySnapshot> _fetchRoomsData() {
    return FirebaseFirestore.instance.collection('group_chats').orderBy('isFeatured', descending: true).get();
  }

  Future<void> _refreshFeed() async {
    setState(() {
      _feedFuture = _fetchFeedData();
    });
  }

  Future<void> _refreshRooms() async {
    setState(() {
      _roomsFuture = _fetchRoomsData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreatePostModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CreatePostSheet(
        cachedName: _currentUserName,
        cachedAvatar: _currentUserAvatar,
        onPosted: () {
          Navigator.pop(context);
          _refreshFeed();
        },
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return RefreshIndicator(
      onRefresh: _refreshLeaderboard,
      child: Builder(
        builder: (context) {
          if (_leaderboardLoading && (_leaderboardCache == null || _leaderboardCache!.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_leaderboardError != null && (_leaderboardCache == null || _leaderboardCache!.isEmpty)) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('An error occurred: ' + _leaderboardError.toString()),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _loadLeaderboard(force: true),
                    child: const Text('Retry'),
                  )
                ],
              ),
            );
          }
          final data = _leaderboardCache;
          if (data == null || data.isEmpty) {
            return const Center(child: Text('No leaderboard data yet.'));
          }
          return LeaderboardTable(users: data);
        },
      ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(13),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            _buildTabItem(title: 'Leaderboard', icon: Icons.leaderboard_outlined, index: 0),
            _buildTabItem(title: 'Feed', icon: Icons.dynamic_feed_outlined, index: 1),
            _buildTabItem(title: 'Rooms', icon: Icons.chat_bubble_outline_rounded, index: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({required String title, required IconData icon, required int index}) {
    final bool isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_tabController.index != index) {
            setState(() {
              _tabController.index = index;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.teal : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.teal : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomsTab() {
    return FutureBuilder<QuerySnapshot>(
      future: _roomsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData && _roomsDocsCache == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          if (_roomsDocsCache != null) {
            // Önceki veri ile listeyi yine göster
            return _buildRoomsListFromDocs(_roomsDocsCache!);
          }
          return const Center(child: Text('Failed to load rooms.'));
        }
        if (snapshot.hasData) {
          _roomsDocsCache = snapshot.data!.docs; // cache güncelle
        }
        if (_roomsDocsCache == null || _roomsDocsCache!.isEmpty) {
          return const Center(child: Text('No rooms yet.'));
        }
        return RefreshIndicator(
          onRefresh: _refreshRooms,
          child: _buildRoomsListFromDocs(_roomsDocsCache!),
        );
      },
    );
  }

  Widget _buildRoomsListFromDocs(List<DocumentSnapshot> roomDocs) {
    final List<GroupChatRoomInfo> rooms = roomDocs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      IconData getIconData(String iconName) {
        switch (iconName) {
          case 'music_note_outlined': return Icons.music_note_outlined;
          case 'movie_filter_outlined': return Icons.movie_filter_outlined;
          case 'airplanemode_active_outlined': return Icons.airplanemode_active_outlined;
          case 'computer_outlined': return Icons.computer_outlined;
          case 'menu_book_outlined': return Icons.menu_book_outlined;
          default: return Icons.chat_bubble_outline_rounded;
        }
      }

      return GroupChatRoomInfo(
        id: doc.id,
        name: data['name'] ?? 'Unknown Room',
        description: data['description'] ?? '',
        icon: getIconData(data['iconName'] ?? 'chat_bubble_outline_rounded'),
        color1: Color(_parseColor(data['color1'], 0xFFFF8A80)),
        color2: Color(_parseColor(data['color2'], 0xFFFF5252)),
        isFeatured: data['isFeatured'] ?? false,
        memberCount: data['memberCount'] is int ? data['memberCount'] : null,
        avatarsPreview: (data['avatarsPreview'] is List)
            ? (data['avatarsPreview'] as List)
                .whereType<String>()
                .take(3)
                .toList()
            : null,
      );
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final roomInfo = rooms[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: GroupChatCard(roomInfo: roomInfo),
        );
      },
    );
  }

  Widget _buildFeedList() {
    return FutureBuilder<QuerySnapshot>(
      future: _feedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData && _feedPostsCache == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          if (_feedPostsCache != null) {
            return _buildFeedListFromDocs(_feedPostsCache!);
          }
          return const Center(child: Text('Failed to load posts.\nPlease try again.', textAlign: TextAlign.center));
        }
        if (snapshot.hasData) {
          _feedPostsCache = snapshot.data!.docs; // cache
        }
        if (_feedPostsCache == null || _feedPostsCache!.isEmpty) {
          return const Center(
            child: Text(
              'No posts yet.\nBe the first to share!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        return _buildFeedListFromDocs(_feedPostsCache!);
      },
    );
  }

  Widget _buildFeedListFromDocs(List<DocumentSnapshot> posts) {
    if (!_privilegeResolved) {
      return const Center(child: CircularProgressIndicator());
    }
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) {
      return RefreshIndicator(
        onRefresh: _refreshFeed,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = FeedPost.fromFirestore(posts[index]);
            return FeedPostCard(post: post, isPrivileged: _isPrivileged, canBanAccount: _canBanOthers);
          },
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(me.uid)
          .collection('blockedUsers')
          .snapshots(),
      builder: (context, userSnap) {
        final blocked = (userSnap.data?.docs.map((d) => d.id).toList() ?? const <String>[]);
        final filtered = posts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
            final authorId = (data['userId'] as String?) ?? '';
            return !blocked.contains(authorId);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Text('No posts match the filters.'),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshFeed,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final post = FeedPost.fromFirestore(filtered[index]);
              return FeedPostCard(post: post, isPrivileged: _isPrivileged, canBanAccount: _canBanOthers);
            },
          ),
        );
      },
    );
  }

  Future<List<LeaderboardUser>> _fetchLeaderboardData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy(_leaderboardPeriod, descending: true)
        .limit(100)
        .get();
    if (snapshot.docs.isEmpty) return [];
    final users = snapshot.docs.where((doc) {
      final data = doc.data();
      final status = data['status'];
      return status == null || (status != 'banned' && status != 'deleted');
    }).toList();
    return users.asMap().entries.map((entry) {
      final data = entry.value.data();
      return LeaderboardUser(
        rank: entry.key + 1,
        name: (data['displayName'] as String?)?.trim().isNotEmpty == true ? data['displayName'] : 'Unknown',
        avatarUrl: (data['avatarUrl'] as String?)?.trim().isNotEmpty == true ? data['avatarUrl'] : 'https://api.dicebear.com/8.x/micah/svg?seed=guest',
        partnerCount: (data['partnerCount'] is int) ? data['partnerCount'] : 0,
        isPremium: data['isPremium'] == true,
        role: (data['role'] as String?) ?? 'user',
      );
    }).toList();
  }

  int _parseColor(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is String) {
      String v = value.trim();
      if (v.startsWith('0x')) v = v.substring(2);
      v = v.replaceAll('#', '');
      if (v.length == 6) v = 'FF$v';
      final parsed = int.tryParse(v, radix: 16);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () => _showCreatePostModal(context),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
              tooltip: 'New Post',
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildTabSelector(),
            Expanded(
              child: IndexedStack(
                index: _tabController.index,
                children: [
                  _buildLeaderboardTab(),
                  Container(key: const ValueKey('feed'), child: _buildFeedList()),
                  Container(key: const ValueKey('rooms'), child: _buildRoomsTab()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  final String? cachedName;
  final String? cachedAvatar;
  final VoidCallback onPosted;
  const _CreatePostSheet({required this.cachedName, required this.cachedAvatar, required this.onPosted});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final TextEditingController _controller = TextEditingController();
  final ValueNotifier<int> _length = ValueNotifier<int>(0);
  bool _posting = false;
  final int _maxLen = 280;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => _length.value = _controller.text.characters.length);
    // Immediate focus (single combined animation with keyboard)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _length.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final text = _controller.text.trim();
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      // Mümkünse cache, yoksa minimal fetch
      String userName = widget.cachedName ?? 'Unknown User';
      String avatar = widget.cachedAvatar ?? '';
      if (widget.cachedName == null) {
        final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final data = snap.data();
        if (data != null) {
          userName = (data['displayName'] as String?)?.trim().isNotEmpty == true ? data['displayName'] : userName;
          avatar = (data['avatarUrl'] as String?)?.trim().isNotEmpty == true ? data['avatarUrl'] : avatar;
        }
      }
      await FirebaseFirestore.instance.collection('posts').add({
        'postText': text,
        'userId': user.uid,
        'userName': userName,
        'userAvatarUrl': avatar,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'commentCount': 0,
      });
      if (!mounted) return;
      widget.onPosted();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create post: $e')),
      );
      setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final viewInsets = MediaQuery.of(context).viewInsets; // keyboard inset
    // Remove AnimatedPadding + heightFactor to prevent multi-phase vertical jumps.
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Material(
        color: theme.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // Cap max height so content feels like a sheet, but allow shrink when keyboard appears.
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: onSurface.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text('Create New Post', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                // Expanded only if remaining vertical space > threshold; else flexible scroll.
                Flexible(
                  fit: FlexFit.loose,
                  child: RepaintBoundary(
                    child: SingleChildScrollView(
                      // Ensures content scrollable when keyboard reduces space.
                      padding: EdgeInsets.zero,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        minLines: 5,
                        maxLength: _maxLen,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: 'What are you thinking?',
                          counterText: '',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: _length,
                      builder: (context, len, _) {
                        return Text('$len/$_maxLen', style: theme.textTheme.bodySmall);
                      },
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _posting ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _posting ? null : _submit,
                      child: _posting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Post'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
