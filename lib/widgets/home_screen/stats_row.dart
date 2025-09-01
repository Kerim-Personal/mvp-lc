// lib/widgets/home_screen/stats_row.dart

import 'package:flutter/material.dart';

class StatsRow extends StatelessWidget {
  // YENİ: Dışarıdan veri almak için parametreler eklendi
  final int streak;
  final int totalTime;
  final int partnerCount;

  const StatsRow({
    super.key,
    required this.streak,
    required this.totalTime,
    required this.partnerCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(Icons.local_fire_department_rounded, "$streak d", "Streak", Colors.orange),
        _buildStatItem(Icons.timer_rounded, "$totalTime min", "Total Time", Colors.teal),
        _buildStatItem(Icons.people_alt_rounded, "$partnerCount", "Partners", Colors.blue),
      ],
    );
  }

  Widget _buildStatItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
            radius: 28,
            backgroundColor: color.withAlpha(38),
            child: Icon(icon, color: color, size: 28)),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}