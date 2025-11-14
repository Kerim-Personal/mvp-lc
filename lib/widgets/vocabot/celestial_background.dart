// lib/widgets/vocabot/celestial_background.dart
import 'dart:math';
import 'package:flutter/material.dart';

class CelestialBackground extends StatefulWidget {
  final Animation<double> controller;
  const CelestialBackground({super.key, required this.controller});

  @override
  State<CelestialBackground> createState() => _CelestialBackgroundState();
}

class _CelestialBackgroundState extends State<CelestialBackground> {
  List<Star> stars = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.size != null) {
        _createStars(context.size!);
      }
    });
  }

  void _createStars(Size size) {
    final random = Random();
    if (mounted) {
      // Build sırasında setState çağrısını önlemek için
      // postFrameCallback kullan
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            stars = List.generate(300, (index) {
              return Star(
                position: Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
                radius: random.nextDouble() * 1.2 + 0.4,
                baseOpacity: random.nextDouble() * 0.4 + 0.1,
                twinkleSpeed: random.nextDouble() * 0.4 + 0.1,
                twinkleOffset: random.nextDouble() * 2 * pi,
              );
            });
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        if (stars.isEmpty && MediaQuery.of(context).size.width > 0) {
          _createStars(MediaQuery.of(context).size);
        }
        return CustomPaint(
          size: Size.infinite,
          painter: CelestialPainter(widget.controller.value, stars),
        );
      },
    );
  }
}

class Star {
  final Offset position;
  final double radius;
  final double baseOpacity;
  final double twinkleSpeed;
  final double twinkleOffset;
  Star({required this.position, required this.radius, required this.baseOpacity, required this.twinkleSpeed, required this.twinkleOffset});
}

class CelestialPainter extends CustomPainter {
  final double time;
  final List<Star> stars;
  final Random _random = Random();
  CelestialPainter(this.time, this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    final spacePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.8, -0.6),
        radius: 1.5,
        colors: [Color(0xFF1a0a2a), Color(0xFF0b0213)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), spacePaint);

    final starPaint = Paint();
    for (var star in stars) {
      final sineValue = sin((time * 2 * pi * star.twinkleSpeed) + star.twinkleOffset);
      double currentOpacity = star.baseOpacity + (sineValue + 1) / 2 * 0.3;
      double currentRadius = star.radius;

      if (_random.nextDouble() < 0.001) {
        currentOpacity += 0.5;
        currentRadius += 0.5;
      }

      starPaint.color = Colors.white.withAlpha((currentOpacity.clamp(0.0, 1.0) * 255).round());
      canvas.drawCircle(star.position, currentRadius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CelestialPainter oldDelegate) => true;
}

