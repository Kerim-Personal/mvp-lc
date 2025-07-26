import 'package:flutter/material.dart';

class AchievementsSection extends StatelessWidget {
  const AchievementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildAchievementBadge('İlk Adım', Icons.flag, Colors.green, true),
          _buildAchievementBadge('Konuşkan', Icons.chat_bubble, Colors.blue, true),
          _buildAchievementBadge('Gezgin', Icons.language, Colors.orange, true),
          _buildAchievementBadge('Usta', Icons.star, Colors.amber, false),
          _buildAchievementBadge('Fenomen', Icons.whatshot, Colors.red, false),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(String name, IconData icon, Color color, bool earned) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: earned ? color : Colors.grey.shade300,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              color: earned ? Colors.black87 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}