// lib/widgets/community_screen/group_chat_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingua_chat/screens/community_screen.dart';
import 'package:lingua_chat/screens/group_chat_screen.dart';

class GroupChatCard extends StatelessWidget {
  final GroupChatRoom room;
  const GroupChatCard({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupChatScreen(
              roomName: room.name,
              roomIcon: room.icon,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [room.color1, room.color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: room.color2.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHeader(),
            _buildDescription(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: Icon(room.icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            room.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      room.description,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontSize: 14,
        height: 1.4,
      ),
    );
  }

  Widget _buildFooter() {
    final avatars = [
      'https://api.dicebear.com/8.x/micah/svg?seed=Leo',
      'https://api.dicebear.com/8.x/micah/svg?seed=Felix',
      'https://api.dicebear.com/8.x/micah/svg?seed=Milo',
    ];

    return Row(
      children: [
        SizedBox(
          width: 70,
          height: 30,
          child: Stack(
            children: List.generate(
              avatars.length,
                  (index) => Positioned(
                left: (index * 20).toDouble(),
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(1.5),
                    child: ClipOval(
                      child: SvgPicture.network(
                        avatars[index],
                        width: 28,
                        height: 28,
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
            '${room.members} üye',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
      ],
    );
  }
}