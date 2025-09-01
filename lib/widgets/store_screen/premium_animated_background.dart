// lib/widgets/store_screen/premium_animated_background.dart

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// Premium kullanıcılar için zengin aurora/parçacık efektli arka plan.
class PremiumAnimatedBackground extends StatefulWidget {
  const PremiumAnimatedBackground({super.key});

  @override
  State<PremiumAnimatedBackground> createState() => _PremiumAnimatedBackgroundState();
}

class _PremiumAnimatedBackgroundState extends State<PremiumAnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _AuroraPainter(time: _controller.value),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double time; // 0..1 döngü
  _AuroraPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final t = time * 2 * math.pi;
    _paintGradientBlobs(canvas, size, t);
    _paintWaves(canvas, size, t);
    _paintSparkles(canvas, size, t);
    _applyBlurOverlay(canvas, size);
  }

  void _paintGradientBlobs(Canvas canvas, Size size, double t) {
    final centers = [
      Offset(size.width * (0.2 + 0.05 * math.sin(t * 0.7)), size.height * 0.15),
      Offset(size.width * (0.85 + 0.04 * math.cos(t * 0.6)), size.height * 0.25),
      Offset(size.width * (0.1 + 0.03 * math.cos(t * 0.9)), size.height * 0.8),
    ];
    final radii = [size.width * 0.35, size.width * 0.28, size.width * 0.32];
    final colors = [
      [const Color(0xFFFFF3C0), const Color(0xFFFFC107)], // açık altın -> amber
      [const Color(0xFFE1BEE7), const Color(0xFF9C27B0)], // lila -> mor
      [const Color(0xFFB3E5FC), const Color(0xFF00BCD4)], // açık mavi -> camgöbeği
    ];

    for (int i = 0; i < centers.length; i++) {
      final rect = Rect.fromCircle(center: centers[i], radius: radii[i]);
      final gradient = RadialGradient(
        colors: [colors[i][1].withOpacity(0.55), colors[i][0].withOpacity(0.0)],
      );
      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..blendMode = BlendMode.srcOver;
      canvas.drawCircle(centers[i], radii[i], paint);
    }
  }

  void _paintWaves(Canvas canvas, Size size, double t) {
    final path = Path();
    final baseY = size.height * 0.68 + 10 * math.sin(t * 0.8);
    path.moveTo(0, baseY);
    for (double x = 0; x <= size.width; x += 8) {
      final y = baseY + 14 * math.sin((x / size.width * 2 * math.pi) + t * 0.6);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x66FFD54F),
          const Color(0x338BC34A),
          const Color(0x2200BCD4),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, baseY - 40, size.width, 120))
      ..blendMode = BlendMode.plus;

    canvas.drawPath(path, paint);
  }

  void _paintSparkles(Canvas canvas, Size size, double t) {
    final rnd = math.Random(42); // deterministik
    final int count = 70;

    for (int i = 0; i < count; i++) {
      final px = size.width * rnd.nextDouble();
      final py = size.height * rnd.nextDouble();
      final twinkle = 0.5 + 0.5 * math.sin(t * (1.0 + rnd.nextDouble() * 2.0) + i);
      final alpha = (0.10 + 0.35 * twinkle).clamp(0.0, 1.0);
      final r = 0.6 + 1.6 * twinkle;
      final paint = Paint()..color = Colors.white.withOpacity(alpha);
      canvas.drawCircle(Offset(px, py), r, paint);
    }
  }

  void _applyBlurOverlay(Canvas canvas, Size size) {
    // Hafif bir üst blur/parlaklık katmanı (cam etkisini zenginleştirir)
    final overlayPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.06),
          Colors.transparent,
          Colors.white.withOpacity(0.04),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) => oldDelegate.time != time;
}
