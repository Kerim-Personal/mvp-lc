// lib/widgets/home_screen/profile_summary_content.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vocachat/widgets/profile_screen/achievements_section.dart';
import 'package:vocachat/widgets/profile_screen/section_title.dart';
import 'package:vocachat/widgets/profile_screen/stats_grid.dart';

class ProfileSummaryContent extends StatefulWidget {
  const ProfileSummaryContent({super.key});

  @override
  State<ProfileSummaryContent> createState() => _ProfileSummaryContentState();
}

class _ProfileSummaryContentState extends State<ProfileSummaryContent> {
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

  Widget _heroHeader(Map<String, dynamic> data) {
    final displayName = data['displayName']?.toString() ?? 'Traveler';
    final avatarUrl = data['avatarUrl'] as String?;
    final isPremium = data['isPremium'] as bool? ?? false;
    final role = (data['role'] as String?) ?? 'user';

    Widget buildAvatar() {
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        final lower = avatarUrl.toLowerCase();
        // 1) URL svg içeriyorsa doğrudan Svg yükle
        if (lower.contains('.svg') || lower.contains('format=svg') || lower.startsWith('data:image/svg+xml')) {
          return CircleAvatar(
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
        }
        // 2) Ağırlıklı olarak raster kabul et, hata olursa SVG’ye düş
        return CircleAvatar(
          radius: 34,
          backgroundColor: Colors.transparent,
          child: ClipOval(
            child: Image.network(
              avatarUrl,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
              },
              errorBuilder: (context, error, stackTrace) {
                // Raster başarısızsa SVG dene; o da olmazsa baş harf
                return SvgPicture.network(
                  avatarUrl,
                  width: 68,
                  height: 68,
                  placeholderBuilder: (_) => const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
            ),
          ),
        );
      }
      return CircleAvatar(
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;
        final avatar = buildAvatar();
        final headerMain = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isPremium) premiumChip,
                if (roleChip is! SizedBox) roleChip,
              ],
            ),
          ],
        );

        final content = isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [avatar, const SizedBox(width: 12), Expanded(child: headerMain)]),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  avatar,
                  const SizedBox(width: 14),
                  Expanded(child: headerMain),
                ],
              );

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.10),
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.06),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: content,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = _userData ?? {};
    final level = data['level'] ?? '-';
    final streak = data['streak'] ?? 0;
    final totalPracticeTime = data['totalPracticeTime'] ?? 0;
    final highestStreak = data['highestStreak'] ?? streak;
    final int highestStreakInt = highestStreak is int ? highestStreak : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroHeader(data),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          const SectionTitle('My Stats'),
          const SizedBox(height: 8),
          StatsGrid(
            level: level,
            streak: streak,
            totalPracticeTime: totalPracticeTime,
            highestStreak: highestStreakInt,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          const SectionTitle('Earned Badges'),
          const SizedBox(height: 8),
          AchievementsSection(
            streak: streak,
            highestStreak: highestStreakInt,
            totalPracticeTime: totalPracticeTime,
            level: level,
          ),
          const SizedBox(height: 60),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () {
                if (!mounted) return;
                Navigator.of(context).maybePop();
              },
              child: const Text('OK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
