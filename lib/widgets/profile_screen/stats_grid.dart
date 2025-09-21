// lib/widgets/profile_screen/stats_grid.dart

import 'package:flutter/material.dart';

class StatsGrid extends StatelessWidget {
  final String level;
  final int streak;
  final int totalRoomTimeSeconds; // odalarda geçirilen toplam süre (s)
  // TODO: Placeholder fields for future statistics.
  final int highestStreak;

  const StatsGrid({
    super.key,
    required this.level,
    required this.streak,
    required this.totalRoomTimeSeconds,
    this.highestStreak = 0, // default 0
  });

  String _format(int seconds) {
    if (seconds <= 0) return '0s';
    final d = Duration(seconds: seconds);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '${d.inSeconds.remainder(60)}s';
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 4,
      mainAxisSpacing: 4,
      childAspectRatio: 0.8, // 0.9'dan 0.8'e düşürdüm - biraz daha yüksek kutular
      children: [
        _buildStatCard(Icons.local_fire_department, "$streak d", "Streak", Colors.orange),
        _buildStatCard(Icons.timer, _format(totalRoomTimeSeconds), "Room Time", Colors.blue),
        _buildStatCard(Icons.bar_chart_rounded, level, "Level", Colors.purple),
        _buildStatCard(Icons.military_tech, "$highestStreak d", "Best Streak", Colors.amber.shade700),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(6.0), // 4'ten 6'ya artırdım - biraz daha fazla alan
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color), // 14'ten 16'ya büyüttüm
            const SizedBox(height: 3), // 2'den 3'e artırdım
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), // 9'dan 11'e büyüttüm
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 1), // Küçük boşluk ekledim
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                style: TextStyle(fontSize: 8, color: Colors.grey.shade600), // 6'dan 8'e büyüttüm
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}