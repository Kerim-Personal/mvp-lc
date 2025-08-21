// lib/widgets/community_screen/leaderboard_table.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingua_chat/screens/community_screen.dart';

class LeaderboardTable extends StatefulWidget {
  final List<LeaderboardUser> users;

  const LeaderboardTable({super.key, required this.users});

  @override
  State<LeaderboardTable> createState() => _LeaderboardTableState();
}

class _LeaderboardTableState extends State<LeaderboardTable> with TickerProviderStateMixin {
  late final AnimationController _listAnimationController;
  late final List<Animation<Offset>> _slideAnimations;
  late final List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    final totalDuration = 500 + widget.users.length * 30;
    _listAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalDuration > 2000 ? 2000 : totalDuration),
    );

    _slideAnimations = List.generate(
      widget.users.length,
          (index) => Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _listAnimationController,
          curve: Interval(
            (index * 0.015),
            (0.4 + (index * 0.015)).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _fadeAnimations = List.generate(
      widget.users.length,
          (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _listAnimationController,
          curve: Interval(
            (index * 0.015),
            (0.5 + (index * 0.015)).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );


    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.users.length,
      itemBuilder: (context, index) {
        final user = widget.users[index];
        return FadeTransition(
          opacity: _fadeAnimations[index],
          child: SlideTransition(
            position: _slideAnimations[index],
            child: _UserRankCard(user: user),
          ),
        );
      },
    );
  }
}

class _UserRankCard extends StatefulWidget {
  final LeaderboardUser user;
  const _UserRankCard({required this.user});

  @override
  State<_UserRankCard> createState() => _UserRankCardState();
}

class _UserRankCardState extends State<_UserRankCard> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'moderator':
        return Colors.orange;
      default:
        return Colors.black87;
    }
  }

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    if (widget.user.isPremium) {
      _shimmerController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Timer(const Duration(seconds: 1), () {
            if (mounted) {
              _shimmerController.forward(from: 0.0);
            }
          });
        }
      });
      _shimmerController.forward();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<int, dynamic> rankInfo = {
      1: {'color': Colors.amber, 'icon': Icons.emoji_events, 'label': 'Altın'},
      2: {'color': Colors.grey.shade400, 'icon': Icons.military_tech, 'label': 'Gümüş'},
      3: {'color': Colors.brown.shade400, 'icon': Icons.workspace_premium, 'label': 'Bronz'},
    };

    final isTop3 = rankInfo.containsKey(widget.user.rank);
    final rankColor = isTop3 ? rankInfo[widget.user.rank]['color'] : Colors.grey.shade700;
    final rankIcon = isTop3 ? rankInfo[widget.user.rank]['icon'] : null;
    final baseColor = _roleColor(widget.user.role);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: isTop3 ? 4 : 2,
      shadowColor: isTop3 ? rankColor.withOpacity(0.3) : Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isTop3
            ? BorderSide(color: rankColor, width: 1.5)
            : BorderSide.none,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isTop3 ? LinearGradient(
            stops: const [0.02, 0.02],
            colors: [rankColor, Colors.white],
          ) : null,
          color: isTop3 ? null : Colors.white,
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 45,
              child: Column(
                children: [
                  if (isTop3) Icon(rankIcon, color: rankColor, size: 22),
                  Text(
                    '#${widget.user.rank}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rankColor,
                        fontSize: isTop3 ? 18 : 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey.shade200,
              child: ClipOval(
                child: SvgPicture.network(
                  widget.user.avatarUrl,
                  width: 44,
                  height: 44,
                  placeholderBuilder: (context) => const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // User Name and Premium Icon
            Expanded(
              child: widget.user.isPremium
                  ? AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  final highlightColor = Colors.white;
                  final value = _shimmerController.value;
                  final start = value * 1.5 - 0.5;
                  final end = value * 1.5;
                  return ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [baseColor, highlightColor, baseColor],
                      stops: [start, (start + end) / 2, end],
                    ).createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                    child: child,
                  );
                },
                child: Text(
                  widget.user.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: baseColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              )
                  : Text(
                widget.user.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: baseColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Partner Count
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_alt_outlined, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 6),
                Text(
                  widget.user.partnerCount.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}