// lib/widgets/profile_screen/profile_sliver_app_bar.dart

import 'dart:ui';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// ProfileSliverAppBar: Enhanced with advanced animations and aesthetic details,
/// a dynamic and interactive SliverAppBar.
///
/// Features:
///   - Parallax effect responsive to scroll.
///   - Smooth scale & fade animations for avatar and texts.
///   - Continuously, slowly moving "cosmic" background animation.
///   - Breathing, lively glow effect around the avatar (premium).
///   - Modular code optimized for readability & performance.
class ProfileSliverAppBar extends StatefulWidget {
  final String displayName;
  final String email;
  final String? avatarUrl;
  final bool isPremium;
  final String role; // admin/moderator/user

  const ProfileSliverAppBar({
    super.key,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.isPremium = false,
    this.role = 'user',
  });

  @override
  State<ProfileSliverAppBar> createState() => _ProfileSliverAppBarState();
}

class _ProfileSliverAppBarState extends State<ProfileSliverAppBar> with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    if (widget.isPremium) {
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
  void didUpdateWidget(covariant ProfileSliverAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isPremium && widget.isPremium) {
      // Premium activated: start shimmer animation
      _shimmerController.forward(from: 0);
    } else if (oldWidget.isPremium && !widget.isPremium) {
      // Premium deactivated: stop shimmer animation
      _shimmerController.stop();
      _shimmerController.reset();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double collapsedHeight = kToolbarHeight + topPadding;
    const double expandedHeight = 350.0;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.teal.shade800,
      elevation: 0,
      centerTitle: true,
      title: _buildCollapsedTitle(),
      flexibleSpace: FlexibleSpaceBar(
        background: LayoutBuilder(
          builder: (context, constraints) {
            final double currentHeight = constraints.maxHeight;
            final double scrollProgress = ((currentHeight - collapsedHeight) / (expandedHeight - collapsedHeight)).clamp(0.0, 1.0);
            return Stack(
              fit: StackFit.expand,
              children: [
                _CosmicBackground(scrollProgress: scrollProgress),
                _buildUserInfo(scrollProgress),
              ],
            );
          },
        ),
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
          StretchMode.fadeTitle,
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'moderator':
        return Colors.orange;
      default:
        return Colors.white;
    }
  }

  Widget _buildCollapsedTitle() {
    final baseColor = _roleColor(widget.role);
    if (widget.isPremium) {
      return AnimatedBuilder(
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
              stops: [start, (start + end) / 2, end].map((e)=>e.clamp(0.0,1.0)).toList(),
            ).createShader(Rect.fromLTWH(0,0,bounds.width,bounds.height)),
            child: child,
          );
        },
        child: Text(
          widget.displayName,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0, color: baseColor),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    return Text(
      widget.displayName,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0, color: baseColor),
    );
  }

  Widget _buildUserInfo(double scrollProgress) {
    final avatarScale = lerpDouble(0.4, 1.0, scrollProgress) ?? 1.0;
    final contentOpacity = Curves.easeIn.transform(scrollProgress);
    final contentVerticalOffset = lerpDouble(0, 40, 1 - scrollProgress) ?? 0.0;
    final baseColor = _roleColor(widget.role);

    return Opacity(
      opacity: contentOpacity,
      child: Transform.translate(
        offset: Offset(0, contentVerticalOffset),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            _buildAnimatedAvatar(avatarScale),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: widget.isPremium
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
                                stops: [start, (start + end)/2, end].map((e)=>e.clamp(0.0,1.0)).toList(),
                              ).createShader(Rect.fromLTWH(0,0,bounds.width,bounds.height)),
                              child: child,
                            );
                          },
                          child: Text(
                            widget.displayName,
                            style: TextStyle(
                              color: baseColor,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              shadows: const [Shadow(blurRadius: 8, color: Colors.black38)],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : Text(
                          widget.displayName,
                          style: TextStyle(
                            color: baseColor,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            shadows: const [Shadow(blurRadius: 8, color: Colors.black38)],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.email,
              style: TextStyle(
                color: Colors.white.withAlpha(217),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedAvatar(double scale) {
    return Transform.scale(
      scale: scale,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          final glowValue = (1 + sin(_glowController.value * 2 * pi)) / 2;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                if (widget.isPremium)
                  BoxShadow(
                    color: const Color(0xFFE5B53A).withAlpha((lerpDouble(50, 150, glowValue)!).round()),
                    blurRadius: lerpDouble(20, 30, glowValue)!,
                    spreadRadius: lerpDouble(3, 6, glowValue)!,
                  ),
              ],
            ),
            child: child,
          );
        },
        child: CircleAvatar(
          radius: 55,
          backgroundColor: Colors.white.withAlpha(230),
          child: CircleAvatar(
            radius: 52,
            backgroundColor: Colors.teal.shade100,
            child: widget.avatarUrl != null
                ? ClipOval(
              child: SvgPicture.network(
                widget.avatarUrl!,
                // Önceden: spinner placeholder. Artık statik yarı saydam daire.
                placeholderBuilder: (context) => Container(
                  width: 104,
                  height: 104,
                  color: Colors.teal.shade200.withAlpha(40),
                  alignment: Alignment.center,
                  child: Icon(Icons.person, color: Colors.teal.shade700.withAlpha(180), size: 42),
                ),
                width: 104,
                height: 104,
                fit: BoxFit.cover,
              ),
            )
                : Text(
              widget.displayName.isNotEmpty ? widget.displayName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 52,
                color: Colors.teal.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aesthetic layer that moves slowly in the background and reacts to scroll.
class _CosmicBackground extends StatelessWidget {
  final double scrollProgress;
  const _CosmicBackground({required this.scrollProgress});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade600,
            Color.lerp(Colors.cyan.shade900, Colors.teal.shade900, 1 - scrollProgress)!
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, lerpDouble(0.7, 1.0, scrollProgress)!],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.1)),
      ),
    );
  }
}