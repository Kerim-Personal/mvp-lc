// lib/widgets/store_screen/glassmorphism.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final double width;
  // ÇÖZÜM: 'height' parametresi artık zorunlu değil, opsiyonel (nullable) yapıldı.
  final double? height;
  final double borderRadius;
  final double blur;
  final Border border;
  final LinearGradient gradient;
  final Widget child;

  const GlassmorphicContainer({
    super.key,
    required this.width,
    this.height, // 'required' kaldırıldı.
    required this.child,
    this.borderRadius = 20,
    this.blur = 10,
    this.border = const Border(),
    this.gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.fromARGB(138, 255, 255, 255),
        Color.fromARGB(61, 255, 255, 255),
      ],
      stops: [0.0, 1.0],
    ),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height, // Artık null olabilir, bu durumda içeriğe göre boyutlanır.
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border,
          ),
          child: child,
        ),
      ),
    );
  }
}