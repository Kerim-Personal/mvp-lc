// lib/widgets/profile_screen/stats_grid.dart

import 'package:flutter/material.dart';

class StatsGrid extends StatelessWidget {
  final String level;
  final int streak;
  final int totalPracticeTime;
  final int partnerCount;
  // TODO: Placeholder fields for future statistics.
  final int newWords;
  final int highestStreak;

  const StatsGrid({
    super.key,
    required this.level,
    required this.streak,
    required this.totalPracticeTime,
    required this.partnerCount,
    this.newWords = 0, // default 0
    this.highestStreak = 0, // default 0
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1,
      children: [
        _buildStatCard(Icons.local_fire_department, "$streak d", "Streak", Colors.orange),
        _buildStatCard(Icons.timer, "$totalPracticeTime min", "Practice Time", Colors.blue),
        _buildStatCard(Icons.people, "$partnerCount", "Partners", Colors.green),
        _buildStatCard(Icons.bar_chart_rounded, level, "Level", Colors.purple),
        _buildStatCard(Icons.translate, "$newWords", "New Words", Colors.redAccent),
        _buildStatCard(Icons.military_tech, "$highestStreak d", "Best Streak", Colors.amber.shade700),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}