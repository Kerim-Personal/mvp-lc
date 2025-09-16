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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color baseColor;
    FontWeight fontWeight = FontWeight.bold;

    switch (role) {
      case 'admin':
        baseColor = isDark ? Colors.red.shade400 : Colors.red.shade600;
        break;
      case 'moderator':
        baseColor = isDark ? Colors.orange.shade400 : Colors.orange.shade500;
        break;
      default:
        baseColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
        fontWeight = FontWeight.w600;
    }

    final premiumColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFFE5B53A);

    Widget child = Text(
      name,
      style: TextStyle(
        fontSize: 13,
        fontWeight: fontWeight,
        color: (isPremium && !(role == 'admin' || role == 'moderator'))
            ? premiumColor
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

