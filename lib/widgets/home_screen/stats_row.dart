// lib/widgets/home_screen/stats_row.dart

import 'package:flutter/material.dart';

class StatsRow extends StatelessWidget {
  final int streak;
  final int totalTime; // saniye cinsinden toplam oda süresi

  const StatsRow({
    super.key,
    required this.streak,
    required this.totalTime,
  });

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0s';
    final d = Duration(seconds: seconds);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(Icons.local_fire_department_rounded, "$streak d", "Streak", Colors.orange),
        _buildStatItem(Icons.timer_rounded, _formatDuration(totalTime), "Total Time", Colors.teal),
      ],
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