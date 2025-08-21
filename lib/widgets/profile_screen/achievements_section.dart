// lib/widgets/profile_screen/achievements_section.dart

import 'package:flutter/material.dart';

class AchievementsSection extends StatelessWidget {
  const AchievementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: const [
          _AchievementBadge(name: 'İlk Adım', icon: Icons.flag, color: Colors.green, earned: true),
          _AchievementBadge(name: 'Konuşkan', icon: Icons.chat_bubble, color: Colors.blue, earned: true),
          _AchievementBadge(name: 'Gezgin', icon: Icons.language, color: Colors.orange, earned: true),
          _AchievementBadge(name: 'Usta', icon: Icons.star, color: Colors.amber, earned: false),
          _AchievementBadge(name: 'Fenomen', icon: Icons.whatshot, color: Colors.red, earned: false),
          _AchievementBadge(name: 'Dilbilimci', icon: Icons.book, color: Colors.purple, earned: false),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool earned;

  const _AchievementBadge({
    required this.name,
    required this.icon,
    required this.color,
    required this.earned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // OPTİMİZASYON: Gölge (BoxShadow) yerine daha performanslı olan çerçeve (Border) kullanıldı.
              border: earned ? Border.all(color: color.withOpacity(0.5), width: 2) : null,
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: earned ? color : Colors.grey.shade200,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: earned ? FontWeight.w600 : FontWeight.normal,
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