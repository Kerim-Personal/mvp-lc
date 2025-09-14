// lib/widgets/linguabot/holographic_header.dart
import 'dart:math';
import 'package:flutter/material.dart';

class HolographicHeader extends StatefulWidget {
  final bool isBotThinking;
  const HolographicHeader({super.key, required this.isBotThinking});

  @override
  State<HolographicHeader> createState() => _HolographicHeaderState();
}

class _HolographicHeaderState extends State<HolographicHeader> with TickerProviderStateMixin {
  late AnimationController _thinkingController;

  @override
  void initState() {
    super.initState();
    _thinkingController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void didUpdateWidget(covariant HolographicHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBotThinking) {
      _thinkingController.repeat();
    } else {
      _thinkingController.stop();
    }
  }

  @override
  void dispose() {
    _thinkingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white70)),
          AnimatedBuilder(
            animation: _thinkingController,
            builder: (context, child) {
              final angle = widget.isBotThinking ? _thinkingController.value * 2 * pi : 0.0;
              final color = widget.isBotThinking ? Colors.cyanAccent : Colors.white;
              return Transform.rotate(
                angle: angle,
                child: Icon(
                  widget.isBotThinking ? Icons.psychology_alt_sharp : Icons.smart_toy_outlined,
                  color: color,
                  size: 30,
                  shadows: [Shadow(color: color, blurRadius: 15)],
                ),
              );
            },
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, color: Colors.white70)),
        ],
      ),
    );
  }
}

