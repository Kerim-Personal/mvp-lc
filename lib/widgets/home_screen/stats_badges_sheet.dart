// lib/widgets/home_screen/stats_badges_sheet.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vocachat/widgets/profile_screen/achievements_section.dart';
import 'package:vocachat/widgets/profile_screen/section_title.dart';
import 'package:vocachat/widgets/profile_screen/stats_grid.dart';

class StatsBadgesSheet extends StatefulWidget {
  const StatsBadgesSheet({super.key});
  @override
  State<StatsBadgesSheet> createState() => _StatsBadgesSheetState();
}

class _StatsBadgesSheetState extends State<StatsBadgesSheet> {
  final _currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = _currentUser;
      if (user == null) {
        setState(() { _loading = false; });
        return;
      }
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!mounted) return;
      setState(() {
        _userData = snap.data() ?? {};
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: SafeArea(
        top: false,
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDiamonds(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(v % 1000000 >= 100000 ? 1 : 0)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(v % 1000 >= 100 ? 1 : 0)}K';
    return '$v';
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    final displayName = data['displayName']?.toString() ?? 'Traveler';
    final avatarUrl = data['avatarUrl'] as String?;
    final isPremium = data['isPremium'] as bool? ?? false;
    final role = (data['role'] as String?) ?? 'user';
    final diamonds = data['diamonds'] is int ? data['diamonds'] as int : 0;

    Widget avatar;
    if (avatarUrl != null && avatarUrl.toLowerCase().endsWith('.svg')) {
      avatar = CircleAvatar(
        radius: 34,
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        child: ClipOval(
          child: SvgPicture.network(
            avatarUrl,
            width: 68,
            height: 68,
            placeholderBuilder: (_) => const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      );
    } else if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatar = CircleAvatar(
        radius: 34,
        backgroundImage: NetworkImage(avatarUrl),
      );
    } else {
      avatar = CircleAvatar(
        radius: 34,
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      );
    }

    final premiumChip = isPremium
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE5B53A).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5B53A), width: 1),
            ),
            child: const Text('PREMIUM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          )
        : const SizedBox.shrink();

    final roleChip = (role == 'admin' || role == 'moderator')
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (role == 'admin' ? Colors.red : Colors.orange).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: role == 'admin' ? Colors.red : Colors.orange, width: 1),
            ),
            child: Text(role.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          )
        : const SizedBox.shrink();

    final diamondChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [Color(0xFF7F5DFF), Color(0xFFE5B53A)]),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(_formatDiamonds(diamonds), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          avatar,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(children: [
                  if (isPremium) premiumChip,
                  if (isPremium) const SizedBox(width: 8),
                  if (roleChip is! SizedBox) roleChip,
                ]),
              ],
            ),
          ),
          const SizedBox(width: 10),
          diamondChip,
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final data = _userData ?? {};
    final level = data['level'] ?? '-';
    final streak = data['streak'] ?? 0;
    final totalPracticeTime = data['totalPracticeTime'] ?? 0;
    final highestStreak = data['highestStreak'] ?? streak;
    final int highestStreakInt = highestStreak is int ? highestStreak : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(data),
          const SectionTitle('My Stats'),
          const SizedBox(height: 8),
          StatsGrid(
            level: level,
            streak: streak,
            totalPracticeTime: totalPracticeTime,
            highestStreak: highestStreakInt,
          ),
          const SizedBox(height: 16),
          const SectionTitle('Earned Badges'),
          const SizedBox(height: 8),
          AchievementsSection(
            streak: streak,
            highestStreak: highestStreakInt,
            totalPracticeTime: totalPracticeTime,
            level: level,
          ),
        ],
      ),
    );
  }
}
