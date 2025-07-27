// lib/widgets/community_screen/group_chat_card.dart
import 'package:flutter/material.dart';
import 'package:lingua_chat/screens/community_screen.dart'; // Modelleri ana dosyadan almak için import ediyoruz
import 'package:lingua_chat/screens/group_chat_screen.dart';

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
              builder: (context) =>
                  GroupChatScreen(roomName: room.name, roomIcon: room.icon),
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
                style:
                TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      color: Colors.white.withOpacity(0.8), size: 18),
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