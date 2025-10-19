// lib/widgets/community_screen/leaderboard_table.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vocachat/screens/leaderboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vocachat/screens/report_user_screen.dart';
import 'package:vocachat/screens/user_profile_summary_screen.dart';

class LeaderboardTable extends StatefulWidget {
  final List<LeaderboardUser> users;
  final bool animate;

  const LeaderboardTable({super.key, required this.users, this.animate = true});

  @override
  State<LeaderboardTable> createState() => _LeaderboardTableState();
}

class _LeaderboardTableState extends State<LeaderboardTable> with TickerProviderStateMixin {
  AnimationController? _listAnimationController;
  List<Animation<Offset>> _slideAnimations = const [];
  List<Animation<double>> _fadeAnimations = const [];

  bool get _useAnimation => widget.animate && widget.users.isNotEmpty;

  void _initListAnimations() {
    _listAnimationController?.dispose();
    final totalDuration = 500 + widget.users.length * 30;
    _listAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalDuration > 1600 ? 1600 : totalDuration),
    );
    _slideAnimations = List.generate(
      widget.users.length,
          (index) => Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _listAnimationController!,
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
          parent: _listAnimationController!,
          curve: Interval(
            (index * 0.015),
            (0.5 + (index * 0.015)).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );
    _listAnimationController!.forward();
  }

  @override
  void initState() {
    super.initState();
    if (_useAnimation) {
      _initListAnimations();
    }
  }

  @override
  void didUpdateWidget(covariant LeaderboardTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_useAnimation) {
      final needsReinit = _listAnimationController == null || _slideAnimations.length != widget.users.length;
      if (needsReinit) {
        _initListAnimations();
      }
    } else {
      // Animasyon artık kullanılmıyorsa controller'ı bırak.
      if (_listAnimationController != null) {
        _listAnimationController!.dispose();
        _listAnimationController = null;
        _slideAnimations = const [];
        _fadeAnimations = const [];
      }
    }
  }

  @override
  void dispose() {
    _listAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_useAnimation || _listAnimationController == null) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: widget.users.length,
        itemBuilder: (context, index) => _UserRankCard(user: widget.users[index]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.users.length,
      itemBuilder: (context, index) {
        final user = widget.users[index];
        // Güvenlik: animasyon listesi boyutu tutmuyorsa fallback
        if (index >= _fadeAnimations.length || index >= _slideAnimations.length) {
          return _UserRankCard(user: user);
        }
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
  // Shimmer sadece premium ve admin/moderator olmayanlarda kullanılacak.
  AnimationController? _shimmerController;
  bool get _isSpecialRole => widget.user.role == 'admin' || widget.user.role == 'moderator';
  bool get _shouldShimmer => widget.user.isPremium; // Artık rol ayırt etmeksizin premiumsa shimmer

  // Shimmer kaldırıldı; sadece renk değişimi kullanılıyor.
  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'moderator':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87);
    }
  }

  @override
  void initState() {
    super.initState();
    if (_shouldShimmer) {
      _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
      _shimmerController!.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted && _shimmerController != null) _shimmerController!.forward(from: 0);
          });
        }
      });
      _shimmerController!.forward();
    }
  }

  @override
  void dispose() {
    _shimmerController?.dispose();
    super.dispose();
  }

  // Yeni: Süreyi puana çevir (artık 1 sn = 1 puan)
  int _secondsToPoints(int totalSeconds) {
    if (totalSeconds <= 0) return 0;
    return totalSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final Map<int, dynamic> rankInfo = {
      1: {'color': Colors.amber, 'icon': Icons.emoji_events, 'label': 'Gold'},
      2: {'color': Colors.grey.shade400, 'icon': Icons.military_tech, 'label': 'Silver'},
      3: {'color': Colors.brown.shade400, 'icon': Icons.workspace_premium, 'label': 'Bronze'},
    };

    final isTop3 = rankInfo.containsKey(widget.user.rank);
    final rankColor = isTop3 ? rankInfo[widget.user.rank]['color'] : Theme.of(context).colorScheme.primary.withValues(alpha: 0.75);
    final rankIcon = isTop3 ? rankInfo[widget.user.rank]['icon'] : null;
    final baseColor = _roleColor(widget.user.role);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: isTop3 ? 4 : 2,
      shadowColor: isTop3 ? rankColor.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isTop3
            ? BorderSide(color: rankColor, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserProfileSummaryScreen(user: widget.user),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isTop3 ? LinearGradient(
              stops: const [0.02, 0.02],
              colors: [rankColor, Theme.of(context).colorScheme.surface],
            ) : null,
            color: isTop3 ? null : Theme.of(context).colorScheme.surface,
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
              // User Name and Premium Icon + Points
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildName(baseColor),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${_secondsToPoints(widget.user.totalRoomSeconds)} points',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              _ReportUserButton(targetUser: widget.user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildName(Color baseColor) {
    final isPremium = widget.user.isPremium;
    final bool normalPremium = isPremium && !_isSpecialRole;
    final color = normalPremium ? const Color(0xFFE5B53A) : baseColor;

    final textWidget = Text(
      widget.user.name,
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: color,
        shadows: (isPremium && !_isSpecialRole) ? const [Shadow(blurRadius: 6, color: Colors.black26)] : null,
      ),
      overflow: TextOverflow.ellipsis,
    );

    if (!_shouldShimmer || _shimmerController == null) return textWidget;

    return AnimatedBuilder(
      animation: _shimmerController!,
      builder: (context, child) {
        final v = _shimmerController?.value ?? 0.0; // 0..1
        final start = (v - 0.3).clamp(0.0, 1.0);
        final mid = v.clamp(0.0, 1.0);
        final end = (v + 0.3).clamp(0.0, 1.0);
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: normalPremium
                ? const [Color(0xFFE5B53A), Colors.white, Color(0xFFE5B53A)]
                : [baseColor, Colors.white, baseColor],
             stops: [start, mid, end],
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
           ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: child,
        );
      },
      child: textWidget,
    );
  }
}

class _ReportUserButton extends StatelessWidget {
  final LeaderboardUser targetUser;
  const _ReportUserButton({required this.targetUser});
  @override
  Widget build(BuildContext context) {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null || current.uid == targetUser.userId) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Report',
      icon: const Icon(Icons.flag_outlined, size: 20, color: Colors.redAccent),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReportUserScreen(
              reportedUserId: targetUser.userId,
              reportedContent: targetUser.name,
              reportedContentId: 'leaderboard_${targetUser.userId}',
              reportedContentType: 'leaderboard',
              reportedContentParentId: null,
            ),
          ),
        );
      },
    );
  }
}
