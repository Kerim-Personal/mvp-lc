// lib/widgets/community_screen/leaderboard_list_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingua_chat/screens/community_screen.dart'; // Modelleri ana dosyadan almak için import ediyoruz

class LeaderboardListItem extends StatelessWidget {
  final LeaderboardUser user;
  const LeaderboardListItem({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Text(
              '#${user.rank}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: user.rank <= 3 ? Colors.amber.shade700 : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              child: ClipOval(
                child: SvgPicture.network(
                  user.avatarUrl,
                  placeholderBuilder: (context) =>
                  const CircularProgressIndicator(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user.name,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    color: Colors.orange.shade600, size: 20),
                const SizedBox(width: 4),
                Text(
                  user.streak.toString(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}