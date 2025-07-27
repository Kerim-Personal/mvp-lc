// lib/widgets/profile_screen/stats_grid.dart

import 'package:flutter/material.dart';

class StatsGrid extends StatelessWidget {
  final String level;
  final int streak;
  final int totalPracticeTime;
  final int partnerCount;
  // TODO: Gelecekte eklenecek istatistikler için alanlar
  final int newWords;
  final int highestStreak;

  const StatsGrid({
    super.key,
    required this.level,
    required this.streak,
    required this.totalPracticeTime,
    required this.partnerCount,
    this.newWords = 24, // Şimdilik varsayılan değer
    this.highestStreak = 12, // Şimdilik varsayılan değer
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
        _buildStatCard(Icons.local_fire_department, "$streak Gün", "Seri", Colors.orange),
        _buildStatCard(Icons.timer, "$totalPracticeTime dk", "Pratik Süresi", Colors.blue),
        _buildStatCard(Icons.people, "$partnerCount", "Partner", Colors.green),
        _buildStatCard(Icons.bar_chart_rounded, level, "Seviye", Colors.purple),
        _buildStatCard(Icons.translate, "$newWords", "Yeni Kelime", Colors.redAccent),
        _buildStatCard(Icons.military_tech, "$highestStreak Gün", "En Yüksek Seri", Colors.amber.shade700),
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