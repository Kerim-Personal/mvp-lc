import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocachat/screens/group_chat_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> with TickerProviderStateMixin {
  late AnimationController _entryAnimationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, Map<String, dynamic>> _roomStats = {};

  // Static rooms data including your music room
  final List<Map<String, dynamic>> _staticRooms = [
    {
      'id': 'music_room_001',
      'name': 'Music Lovers',
      'description': 'Share your favorite songs and discover new music',
      'icon': Icons.music_note_rounded,
      'color': Colors.purple,
    },
    {
      'id': 'general_chat_001',
      'name': 'General Chat',
      'description': 'Talk about anything and everything',
      'icon': Icons.chat_bubble_rounded,
      'color': Colors.blue,
    },
    {
      'id': 'english_practice_001',
      'name': 'English Practice',
      'description': 'Practice English with other learners',
      'icon': Icons.language_rounded,
      'color': Colors.green,
    },
    {
      'id': 'grammar_help_001',
      'name': 'Grammar Help',
      'description': 'Get help with grammar questions',
      'icon': Icons.auto_fix_high_rounded,
      'color': Colors.orange,
    },
    {
      'id': 'vocabulary_001',
      'name': 'Vocabulary Building',
      'description': 'Learn new words together',
      'icon': Icons.book_rounded,
      'color': Colors.teal,
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _entryAnimationController.forward();
    _loadRoomStats();
  }

  void _loadRoomStats() async {
    for (var room in _staticRooms) {
      final String roomId = room['id'];
      try {
        // Read member count from group_chats/{roomId}/members
        final membersRef = FirebaseFirestore.instance
            .collection('group_chats')
            .doc(roomId)
            .collection('members');

        int memberCount = 0;
        try {
          final agg = await membersRef.count().get();
          memberCount = (agg.count ?? 0);
        } catch (_) {
          // Fallback: approximate by fetching a small page
          final snap = await membersRef.limit(20).get();
          memberCount = snap.size;
        }

        // Determine activity from latest message timestamp within last 24h
        bool isActive = false;
        try {
          final latestMsgSnap = await FirebaseFirestore.instance
              .collection('group_chats')
              .doc(roomId)
              .collection('messages')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();

          if (latestMsgSnap.docs.isNotEmpty) {
            final data = latestMsgSnap.docs.first.data();
            final ts = data['createdAt'];
            DateTime? last;
            if (ts is Timestamp) {
              last = ts.toDate();
            } else if (ts is DateTime) {
              last = ts;
            }
            if (last != null) {
              isActive = DateTime.now().difference(last).inHours < 24;
            }
          }
        } catch (_) {
          // ignore activity failures
        }

        if (mounted) {
          setState(() {
            _roomStats[roomId] = {
              'memberCount': memberCount,
              'isActive': isActive,
            };
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _roomStats[roomId] = {
              'memberCount': 0,
              'isActive': false,
            };
          });
        }
      }
    }
  }

  void _setupAnimations() {
    _entryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entryAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryAnimationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _entryAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    cs.surface,
                    cs.surface.withValues(alpha: 0.8),
                    cs.primary.withValues(alpha: 0.1),
                  ]
                : [
                    cs.primary.withValues(alpha: 0.1),
                    cs.surface,
                    cs.primary.withValues(alpha: 0.05),
                  ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(context, cs, isDark),
                  Expanded(
                    child: _buildRoomsList(context, cs, isDark),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.forum_rounded,
              color: cs.onPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chat Rooms',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  'Join conversations with other learners',
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsList(BuildContext context, ColorScheme cs, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _staticRooms.length,
      itemBuilder: (context, index) {
        final roomData = _staticRooms[index];
        final roomId = roomData['id'];
        final stats = _roomStats[roomId];

        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutCubic,
          child: _buildRoomCard(context, cs, isDark, roomData, stats),
        );
      },
    );
  }

  Widget _buildRoomCard(BuildContext context, ColorScheme cs, bool isDark,
      Map<String, dynamic> roomData, Map<String, dynamic>? stats) {
    final String roomName = roomData['name'];
    final String description = roomData['description'];
    final IconData roomIcon = roomData['icon'];
    final Color roomColor = roomData['color'];

    // Use real stats if available, otherwise show loading or default
    final int memberCount = stats?['memberCount'] ?? 0;
    final bool isActive = stats?['isActive'] ?? false;
    final bool isLoading = stats == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(20),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      cs.surface.withValues(alpha: 0.9),
                      cs.surface.withValues(alpha: 0.7),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.8),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _joinRoom(context, roomData['id'], roomName, roomIcon),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          roomColor,
                          roomColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: roomColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      roomIcon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                roomName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isActive)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.people_rounded,
                              size: 16,
                              color: roomColor,
                            ),
                            const SizedBox(width: 4),
                            if (isLoading)
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(roomColor),
                                ),
                              )
                            else
                              Text(
                                memberCount == 0 ? 'No members' :
                                memberCount == 1 ? '1 member' : '$memberCount members',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: roomColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            const Spacer(),
                            if (!isLoading)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isActive ? 'Active' : 'Quiet',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isActive ? Colors.green : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: roomColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _joinRoom(BuildContext context, String roomId, String roomName, IconData roomIcon) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            GroupChatScreen(
              roomId: roomId,
              roomName: roomName,
              roomIcon: roomIcon,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
