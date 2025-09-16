// lib/widgets/home_screen/premium_upsell_dialog.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lingua_chat/main.dart';

class PremiumUpsellDialog extends StatefulWidget {
  const PremiumUpsellDialog({super.key});

  @override
  State<PremiumUpsellDialog> createState() => _PremiumUpsellDialogState();
}

class _PremiumUpsellDialogState extends State<PremiumUpsellDialog> with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _shimmerController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

    _scaleAnimation = CurvedAnimation(parent: _entryController, curve: Curves.elasticOut);
    _fadeAnimation = CurvedAnimation(parent: _entryController, curve: Curves.easeIn);

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade800.withValues(alpha: 0.85),
                    Colors.deepPurple.shade900.withValues(alpha: 0.95)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => LinearGradient(
                          colors: const [Colors.amber, Colors.white, Colors.amber],
                          stops: [_shimmerController.value - 0.5, _shimmerController.value, _shimmerController.value + 0.5],
                          transform: const GradientRotation(0.5),
                        ).createShader(bounds),
                        child: child,
                      );
                    },
                    child: const Icon(Icons.auto_awesome, size: 50),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unlock Your Potential',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black38)],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unlock great perks with Lingua Pro and take your learning experience to the next level.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Filtering özelliği kaldırıldı
                  _buildFeatureRow(Icons.translate, 'In-Chat Instant Translation'),
                  _buildFeatureRow(Icons.ads_click, 'Completely Ad-Free Experience'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      elevation: 8,
                      shadowColor: Colors.amber.withValues(alpha: 0.5),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      rootScreenKey.currentState?.changeTab(0);
                    },
                    child: const Text('Discover Lingua Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Not Now', style: TextStyle(color: Colors.white70)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.amber.shade300, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}