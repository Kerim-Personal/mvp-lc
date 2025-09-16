// lib/screens/community_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lingua_chat/widgets/community_screen/leaderboard_table.dart';
import 'package:lingua_chat/widgets/community_screen/feed_post_card.dart';

// --- DATA MODELLERİ ---
class LeaderboardUser {
  final String name;
  final String avatarUrl;
  final int rank;
  final bool isPremium;
  final String role; // admin/moderator/user

  LeaderboardUser({
    required this.name,
    required this.avatarUrl,
    required this.rank,
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
  // GroupChatCard bunu buradan import ettiği için bu model korunuyor
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color1;
  final Color color2;
  final bool isFeatured;
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
  const CommunityScreen({super.key, this.initialTabIndex});
  final int? initialTabIndex;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _leaderboardType = 'weekly';

  // Ek performans & animasyon kontrolü
  bool _leaderboardFirstAnimationDone = false;
  List<LeaderboardUser>? _overallCache;
  List<LeaderboardUser>? _weeklyCache;

  late Future<QuerySnapshot> _feedFuture;

  // Flicker azaltma cache'leri
  List<LeaderboardUser>? _leaderboardCache;
  bool _leaderboardLoading = false;
  Object? _leaderboardError;
  List<DocumentSnapshot>? _feedPostsCache;

  // Kullanıcı rolü ve yetkileri için değişkenler
  bool _isPrivileged = false;
  bool _canBanOthers = false;
  bool _privilegeResolved = false;

  // Kullanıcı adı ve avatarı için cache
  String? _currentUserName;
  String? _currentUserAvatar;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final idx = widget.initialTabIndex;
    if (idx != null && idx >= 0 && idx < 2) {
      _tabController.index = idx;
    }
    _tabController.addListener(() => setState(() {}));
    _feedFuture = _fetchFeedData();
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
    // Var olan cache'i hızlı göster (force değilse) - lag azaltma
    if (!force) {
      if (_leaderboardType == 'overall' && _overallCache != null) {
        _leaderboardCache = _overallCache; // anında göster
        if (!initial) setState(() {});
        if (!initial) return; // arka planda fetch tetiklemeden çık
      } else if (_leaderboardType == 'weekly' && _weeklyCache != null) {
        _leaderboardCache = _weeklyCache;
        if (!initial) setState(() {});
        if (!initial) return;
      }
    }

    if (_leaderboardLoading) return;
    setState(() {
      _leaderboardLoading = true;
      if (force) _leaderboardError = null;
    });
    try {
      final data = await _fetchLeaderboardData();
      if (!mounted) return;
      setState(() {
        _leaderboardCache = data;
        if (_leaderboardType == 'overall') {
          _overallCache = data;
        } else {
          _weeklyCache = data;
        }
        _leaderboardLoading = false;
        if (!_leaderboardFirstAnimationDone && data.isNotEmpty) {
          _leaderboardFirstAnimationDone = true; // ilk başarılı yüklemede işaretle
        }
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

  Future<void> _refreshFeed() async {
    setState(() {
      _feedFuture = _fetchFeedData();
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
            return const Center(child: Text('No leaderboard data.'));
          }
          return LeaderboardTable(
            users: data,
            animate: !_leaderboardFirstAnimationDone,
          );
        },
      ),
    );
  }

  Widget _buildTabSelector() {
    final isLeaderboard = _tabController.index == 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, isLeaderboard ? 8 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(13),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildTabItem(title: 'Leaderboard', icon: Icons.leaderboard_outlined, index: 0),
                _buildTabItem(title: 'Feed', icon: Icons.dynamic_feed_outlined, index: 1),
              ],
            ),
          ),
          if (isLeaderboard) const SizedBox(height: 10),
          if (isLeaderboard)
            Center(
              child: _LeaderboardModePicker(
                current: _leaderboardType,
                onChanged: (val) {
                  if (_leaderboardType == val) return;
                  setState(() { _leaderboardType = val; });
                  _loadLeaderboard(force: false);
                },
              ),
            ),
        ],
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
    Query baseQuery = FirebaseFirestore.instance
        .collection('users')
        .orderBy('streak', descending: true)
        .limit(100);

    QuerySnapshot snapshot;
    snapshot = await baseQuery.get();

    if (snapshot.docs.isEmpty) {
      return [];
    }
    return _mapUsersFromSnapshot(snapshot);
  }

  List<LeaderboardUser> _mapUsersFromSnapshot(QuerySnapshot snapshot) {
    final users = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'];
      return status == null || (status != 'banned' && status != 'deleted');
    }).toList();
    return users.asMap().entries.map((entry) {
      final data = entry.value.data() as Map<String, dynamic>;
      return LeaderboardUser(
        rank: entry.key + 1,
        name: (data['displayName'] as String?)?.trim().isNotEmpty == true ? data['displayName'] : 'Unknown',
        avatarUrl: (data['avatarUrl'] as String?)?.trim().isNotEmpty == true ? data['avatarUrl'] : 'https://api.dicebear.com/8.x/micah/svg?seed=guest',
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
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Material(
        color: theme.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
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
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      minLines: 5,
                      maxLength: _maxLen,
                      decoration: InputDecoration(
                        hintText: 'What are you thinking?',
                        counterText: '',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.25),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: _length,
                      builder: (context, len, _) => Text('$len/$_maxLen', style: theme.textTheme.bodySmall),
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardModePicker extends StatefulWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _LeaderboardModePicker({required this.current, required this.onChanged});

  @override
  State<_LeaderboardModePicker> createState() => _LeaderboardModePickerState();
}

class _LeaderboardModePickerState extends State<_LeaderboardModePicker> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  final GlobalKey _buttonKey = GlobalKey();
  Offset _calculatedOffset = const Offset(0, 46);
  double _popupWidth = 140; // dinamik belirlenecek minimum

  bool get _isWeekly => widget.current == 'weekly';

  void _toggle() {
    if (_entry == null) {
      _prepareAndShow();
    } else {
      _hide();
    }
  }

  void _prepareAndShow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _buttonKey.currentContext;
      if (ctx != null) {
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null) {
          final btnSize = box.size;
          final btnWidth = btnSize.width;
          final btnHeight = btnSize.height;
          // Dinamik popup genişliği: butondan en az 16px fazla ya da min 140, max 220
          _popupWidth = btnWidth + 16;
          if (_popupWidth < 140) _popupWidth = 140;
          if (_popupWidth > 220) _popupWidth = 220;
          double dx = (btnWidth - _popupWidth) / 2; // merkezle
          final screenWidth = MediaQuery.of(ctx).size.width;
          final buttonGlobalPos = box.localToGlobal(Offset.zero);
          final globalLeft = buttonGlobalPos.dx + dx;
          if (globalLeft < 8) {
            dx += (8 - globalLeft);
          }
          final globalRight = buttonGlobalPos.dx + dx + _popupWidth;
          if (globalRight > screenWidth - 8) {
            dx -= (globalRight - (screenWidth - 8));
          }
          final dy = btnHeight + 8;
          _calculatedOffset = Offset(dx, dy);
        }
      }
      if (mounted) _show();
    });
  }

  void _show() {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    _entry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _hide,
            child: Stack(
              children: [
                CompositedTransformFollower(
                  link: _link,
                  showWhenUnlinked: false,
                  offset: _calculatedOffset,
                  child: Material(
                    color: Colors.transparent,
                    child: _buildCard(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    overlay.insert(_entry!);
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  Widget _buildCard() {
    final theme = Theme.of(context);
    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      scale: 1,
      child: Container(
        width: _popupWidth,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 18,
              offset: const Offset(0, 8),
            )
          ],
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _modeTile('weekly', Icons.calendar_view_week, 'Weekly'),
            _divider(),
            _modeTile('overall', Icons.public, 'Overall'),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Divider(height: 14, thickness: 0.8, color: Theme.of(context).dividerColor.withAlpha(80)),
  );

  Widget _modeTile(String value, IconData icon, String text) {
    final theme = Theme.of(context);
    final selected = widget.current == value;
    return InkWell(
      onTap: () {
        if (!selected) widget.onChanged(value);
        _hide();
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 18, color: theme.colorScheme.onPrimaryContainer),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(
          key: _buttonKey,
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.55),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_isWeekly ? Icons.calendar_view_week : Icons.public, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                _isWeekly ? 'Weekly' : 'Overall',
                style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
