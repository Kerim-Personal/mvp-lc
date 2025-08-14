// lib/widgets/shared/animated_background.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -150,
          child: CircleAvatar(
              radius: 220,
              backgroundColor: const Color.fromARGB(77, 156, 39, 176)),
        ),
        Positioned(
          bottom: -180,
          left: -150,
          child: CircleAvatar(
              radius: 250,
              backgroundColor: const Color.fromARGB(77, 0, 188, 212)),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }
}