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
                    color: widget.roomInfo.color2.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  )
                ],
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Canlı üye verisini çekmek için StreamBuilder kullanıyoruz
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('group_chats')
                        .doc(widget.roomInfo.id)
                        .collection('members')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final memberDocs = snapshot.data?.docs ?? [];
                      final memberCount = memberDocs.length;

                      final avatarUrls = memberDocs
                          .map((doc) {
                        final data = doc.data() as Map<String, dynamic>?;
                        return data?['avatarUrl'] as String?;
                      })
                          .where((url) => url != null && url.isNotEmpty)
                          .cast<String>()
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildHeader(memberCount),
                          const SizedBox(height: 12),
                          Text(
                            widget.roomInfo.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildFooter(memberCount, avatarUrls),
                        ],
                      );
                    },
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
            color: Colors.white.withOpacity(0.2),
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
                BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 8)
              ],
            ),
            child: const Text(
              'CANLI',
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
                ? '$memberCount üye burada'
                : 'Odaya ilk giren sen ol!',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
      ],
    );
  }
}