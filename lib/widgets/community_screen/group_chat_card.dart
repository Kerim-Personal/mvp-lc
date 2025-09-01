// lib/widgets/community_screen/group_chat_card.dart
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingua_chat/screens/community_screen.dart';
import 'package:lingua_chat/screens/group_chat_screen.dart';

class GroupChatCard extends StatefulWidget {
  final GroupChatRoomInfo roomInfo;
  const GroupChatCard({super.key, required this.roomInfo});

  @override
  State<GroupChatCard> createState() => _GroupChatCardState();
}

class _GroupChatCardState extends State<GroupChatCard> {
  Offset _offset = Offset.zero;
  // --- Maliyet azaltımı için eklenen cache alanları ---
  bool _loadingMembers = true;
  int _memberCount = 0;
  List<String> _avatarUrls = [];
  DateTime? _lastFetch;

  @override
  void initState() {
    super.initState();
    // Denormalize veriler geldiyse doğrudan kullan, ek okuma yapma
    final initialCount = widget.roomInfo.memberCount;
    final initialAvatars = widget.roomInfo.avatarsPreview;
    if (initialCount != null) {
      _memberCount = initialCount;
      _avatarUrls = (initialAvatars ?? []).take(3).toList();
      _loadingMembers = false;
    } else {
      _fetchMembers();
    }
  }

  Future<void> _fetchMembers({bool force = false}) async {
    // Eğer zaten denormalize veri gelmişse ve force değilse okuma yapma
    if (!force && widget.roomInfo.memberCount != null) return;
    // Basit throttle: 30 sn içinde yeniden istenirse atla.
    if (!force && _lastFetch != null && DateTime.now().difference(_lastFetch!) < const Duration(seconds: 30)) return;
    try {
      setState(() => _loadingMembers = true);
      final snapshot = await FirebaseFirestore.instance
          .collection('group_chats')
          .doc(widget.roomInfo.id)
          .collection('members')
          .limit(5) // Limit maliyeti azaltır
          .get(); // Tek seferlik okuma – real-time listener yok

      final docs = snapshot.docs;
      final avatars = <String>[];
      for (final d in docs) {
        final data = d.data(); // unnecessary cast kaldırıldı
        final url = data['avatarUrl'];
        if (url is String && url.isNotEmpty) avatars.add(url);
      }
      if (mounted) {
        setState(() {
          _memberCount = docs.length; // İleride aggregate count ile değiştirilebilir
          _avatarUrls = avatars;
          _loadingMembers = false;
          _lastFetch = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingMembers = false; // Hata durumunda da UI dursun
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => setState(() => _offset += details.delta),
      onPanEnd: (_) => setState(() => _offset = Offset.zero),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupChatScreen(
              roomName: widget.roomInfo.name,
              roomIcon: widget.roomInfo.icon,
              roomId: widget.roomInfo.id,
            ),
          ),
        );
      },
      // Kullanıcı uzun basarsa manuel yenile (isteğe bağlı basit etkileşim)
      onLongPress: () => _fetchMembers(force: true),
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_offset.dy * -0.002)
          ..rotateY(_offset.dx * 0.002),
        alignment: FractionalOffset.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 220,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [widget.roomInfo.color1, widget.roomInfo.color2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.roomInfo.color2.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  )
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Önceki StreamBuilder kaldırıldı; tek seferlik fetch verileri kullanılıyor.
                  // Basit durum yönetimi:
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeader(_memberCount),
                      const SizedBox(height: 12),
                      Text(
                        widget.roomInfo.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loadingMembers)
                        Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.8)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('Loading...', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                          ],
                        )
                      else
                        _buildFooter(_memberCount, _avatarUrls),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int memberCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(widget.roomInfo.icon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.roomInfo.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4)]),
          ),
        ),
        if (memberCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.redAccent.withValues(alpha: 0.5), blurRadius: 8)
              ],
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(int memberCount, List<String> avatarUrls) {
    final avatarsToShow = avatarUrls.take(3).toList();

    return Row(
      children: [
        if (avatarsToShow.isNotEmpty)
          SizedBox(
            width: 70,
            height: 30,
            child: Stack(
              children: List.generate(
                avatarsToShow.length,
                    (index) => Positioned(
                  left: (index * 20).toDouble(),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(1.5),
                      child: ClipOval(
                        child: SvgPicture.network(
                          avatarsToShow[index],
                          width: 28,
                          height: 28,
                          placeholderBuilder: (context) =>
                          const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: Text(
            memberCount > 0
                ? '$memberCount members here'
                : 'Be the first to join the room!',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
      ],
    );
  }
}