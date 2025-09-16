// lib/widgets/shared/animated_background.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    // Daha düşük sigma ile GPU yükü azaltıldı
    return RepaintBoundary(
      child: Stack(
        children: [
          const Positioned(
            top: -100,
            right: -150,
            child: CircleAvatar(
                radius: 220,
                backgroundColor: Color.fromARGB(77, 156, 39, 176)),
          ),
          const Positioned(
            bottom: -180,
            left: -150,
            child: CircleAvatar(
                radius: 250,
                backgroundColor: Color.fromARGB(77, 0, 188, 212)),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), // 120 -> 60
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }
}