// lib/widgets/home_screen/stats_row.dart

import 'package:flutter/material.dart';

class StatsRow extends StatelessWidget {
  // YENİ: Dışarıdan veri almak için parametreler eklendi
  final int streak;
  final int totalTime;
  // Yeni: Tüm stats row'u tıklanabilir yapmak için genel onTap callback'i
  final VoidCallback? onTap;

  const StatsRow({
    super.key,
    required this.streak,
    required this.totalTime,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(Icons.local_fire_department_rounded, "$streak d", "Streak", Colors.orange),
        _buildStatItem(Icons.timer_rounded, "$totalTime min", "Total Time", Colors.teal),
      ],
    );

    if (onTap == null) return content;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: content,
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
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