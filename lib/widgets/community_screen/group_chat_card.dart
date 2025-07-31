// lib/widgets/community_screen/group_chat_card.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingua_chat/screens/community_screen.dart';
import 'package:lingua_chat/screens/group_chat_screen.dart';

// GÜNCELLEME: Widget tamamen sadeleştirildi, animasyon ve efektler kaldırıldı.
class GroupChatCard extends StatelessWidget {
  final GroupChatRoomInfo roomInfo;
  const GroupChatCard({super.key, required this.roomInfo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupChatScreen(
              roomName: roomInfo.name,
              roomIcon: roomInfo.icon,
              roomId: roomInfo.id,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [roomInfo.color1, roomInfo.color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          // GÜNCELLEME: Tüm gölge ve parlama efektleri kaldırıldı.
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Canlı üye verisini çekmek için StreamBuilder kullanıyoruz
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('group_chats')
                  .doc(roomInfo.id)
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
                      roomInfo.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withAlpha(230),
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
    );
  }

  Widget _buildHeader(int memberCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(51),
            shape: BoxShape.circle,
          ),
          child: Icon(roomInfo.icon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            roomInfo.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              // GÜNCELLEME: Yazı gölgesi de kaldırıldı.
            ),
          ),
        ),
        if (memberCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(20),
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
                          placeholderBuilder: (context) => const SizedBox.shrink(),
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
            style: TextStyle(color: Colors.white.withAlpha(204)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
      ],
    );
  }
}