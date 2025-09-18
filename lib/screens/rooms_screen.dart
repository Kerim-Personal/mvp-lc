import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/screens/leaderboard_screen.dart' show GroupChatRoomInfo;
import 'package:lingua_chat/widgets/community_screen/group_chat_card.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  late Future<QuerySnapshot> _roomsFuture;
  List<DocumentSnapshot>? _roomsDocsCache;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _fetchRoomsData();
  }

  Future<QuerySnapshot> _fetchRoomsData() async {
    try {
      print('Rooms yükleniyor...');

      // Auth durumunu kontrol et
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Kullanıcı giriş yapmamış');
        throw Exception('Giriş yapmanız gerekiyor');
      }

      print('Kullanıcı ID: ${user.uid}');

      final result = await FirebaseFirestore.instance.collection('group_chats').get();
      print('${result.docs.length} oda bulundu');

      return result;
    } catch (e) {
      print('Rooms yükleme hatası: $e');
      rethrow;
    }
  }

  Future<void> _refreshRooms() async {
    setState(() {
      _roomsFuture = _fetchRoomsData();
    });
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

  EdgeInsets _listPadding(BuildContext context) {
    final inset = MediaQuery.of(context).padding.bottom;
    return EdgeInsets.fromLTRB(16, 12, 16, 24 + inset);
  }

  @override
  Widget build(BuildContext context) {
    final pad = _listPadding(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _roomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData && _roomsDocsCache == null) {
            // Yükleme göstergesi yerine iskelet kartlar
            return _buildSkeletonList(pad);
          }
          if (snapshot.hasError) {
            print('Snapshot error: ${snapshot.error}');
            if (_roomsDocsCache != null) {
              return _buildRoomsListFromDocs(_roomsDocsCache!, pad);
            }
            return RefreshIndicator(
              onRefresh: _refreshRooms,
              child: ListView(
                padding: pad,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Rooms yüklenemedi',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hata: ${snapshot.error}',
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshRooms,
                          child: const Text('Yeniden Dene'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasData) {
            _roomsDocsCache = snapshot.data!.docs;
          }
          if (_roomsDocsCache == null || _roomsDocsCache!.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshRooms,
              child: ListView(
                padding: pad,
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(child: Text('Henüz oda yok.')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refreshRooms,
            child: _buildRoomsListFromDocs(_roomsDocsCache!, pad),
          );
        },
      ),
    );
  }

  Widget _buildRoomsListFromDocs(List<DocumentSnapshot> roomDocs, EdgeInsets pad) {
    final rooms = roomDocs.map((doc) {
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
        color1: Color(_parseColor(data['color1'], 0xFF4E54C8)),
        color2: Color(_parseColor(data['color2'], 0xFF8F94FB)),
        isFeatured: false,
        memberCount: data['memberCount'] is int ? data['memberCount'] : null,
        avatarsPreview: (data['avatarsPreview'] is List)
            ? (data['avatarsPreview'] as List).whereType<String>().take(3).toList()
            : null,
      );
    }).toList();

    const rowSpacing = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight - pad.vertical;
        double cardHeight;
        if (rooms.isNotEmpty) {
          cardHeight = (availableHeight - rowSpacing * (rooms.length - 1)) / rooms.length;
        } else {
          cardHeight = 140;
        }
        const minCard = 120.0;
        const maxCard = 220.0;
        cardHeight = cardHeight.clamp(minCard, maxCard);

        return ListView.builder(
          padding: pad,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: rooms.length,
          itemBuilder: (context, i) => Padding(
            padding: EdgeInsets.only(bottom: i == rooms.length - 1 ? 0 : rowSpacing),
            child: SizedBox(
              height: cardHeight,
              child: GroupChatCard(roomInfo: rooms[i], compact: true),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonList(EdgeInsets pad) {
    const count = 3;
    const rowSpacing = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight - pad.vertical;
        double cardHeight = (availableHeight - rowSpacing * (count - 1)) / count;
        const minCard = 120.0;
        const maxCard = 220.0;
        cardHeight = cardHeight.clamp(minCard, maxCard);

        return ListView.builder(
          padding: pad,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: count,
          itemBuilder: (context, i) => Padding(
            padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : rowSpacing),
            child: _SkeletonRoomCard(height: cardHeight),
          ),
        );
      },
    );
  }
}

class _SkeletonRoomCard extends StatelessWidget {
  final double height;
  const _SkeletonRoomCard({required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest.withValues(alpha: theme.brightness == Brightness.dark ? 0.22 : 0.5);
    final fg = theme.colorScheme.onSurface.withValues(alpha: 0.08);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [base, base.withValues(alpha: (theme.brightness == Brightness.dark ? 0.18 : 0.35))],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: fg,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 16, width: 140, decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 200, decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(6))),
                    ],
                  ),
                )
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Container(height: 32, width: 100, decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(16))),
                const Spacer(),
                Container(height: 28, width: 28, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
