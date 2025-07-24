// lib/widgets/home_screen/stats_row.dart

import 'package:flutter/material.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
            Icons.local_fire_department_rounded, "3 Gün", "Seri", Colors.orange),
        _buildStatItem(
            Icons.timer_rounded, "45 dk", "Toplam Süre", Colors.teal),
        _buildStatItem(Icons.people_alt_rounded, "7", "Partner", Colors.blue),
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