// lib/widgets/sender_header_label.dart

import 'package:flutter/material.dart';

class SenderHeaderLabel extends StatelessWidget {
  final String name;
  final String? role; // 'admin' | 'moderator' | null
  final bool isPremium;
  final Animation<double> shimmerAnimation;

  const SenderHeaderLabel({
    super.key,
    required this.name,
    required this.role,
    required this.isPremium,
    required this.shimmerAnimation,
  });

  @override
  Widget build(BuildContext context) {
    Color baseColor;
    switch (role) {
      case 'admin':
        baseColor = Colors.red;
        break;
      case 'moderator':
        baseColor = Colors.orange;
        break;
      default:
        baseColor = Colors.grey.shade600;
    }

    Widget child = Text(
      name,
      style: TextStyle(
        fontSize: 12,
        color: (isPremium && !(role == 'admin' || role == 'moderator'))
            ? const Color(0xFFE5B53A)
            : baseColor,
      ),
    );

    if (!isPremium) return child;

    return AnimatedBuilder(
      animation: shimmerAnimation,
      builder: (context, c) {
        final value = shimmerAnimation.value;
        final start = value * 1.5 - 0.5;
        final end = value * 1.5;
        final bool isSpecialRole = (role == 'admin' || role == 'moderator');
        final Color shimmerBase = isSpecialRole ? baseColor : const Color(0xFFE5B53A);
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [shimmerBase, Colors.white, shimmerBase],
            stops: [start, (start + end) / 2, end]
                .map((e) => e.clamp(0.0, 1.0))
                .toList(),
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: c!,
        );
      },
      child: child,
    );
  }
}

