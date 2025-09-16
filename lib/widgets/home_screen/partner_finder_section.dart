// lib/widgets/home_screen/partner_finder_section.dart

import 'package:flutter/material.dart';

class PartnerFinderSection extends StatefulWidget {
  final VoidCallback onFindPartner;
  final AnimationController pulseAnimationController;

  const PartnerFinderSection({
    super.key,
    required this.onFindPartner,
    required this.pulseAnimationController,
  });

  @override
  State<PartnerFinderSection> createState() => _PartnerFinderSectionState();
}

class _PartnerFinderSectionState extends State<PartnerFinderSection> {
  bool _isPartnerButtonHeldDown = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _isPartnerButtonHeldDown = true),
          onTapUp: (_) {
            setState(() => _isPartnerButtonHeldDown = false);
            widget.onFindPartner();
          },
          onTapCancel: () => setState(() => _isPartnerButtonHeldDown = false),
          child: Hero(
            tag: 'find-partner-hero',
            child: AnimatedBuilder(
              animation: widget.pulseAnimationController,
              builder: (context, child) {
                final scale = _isPartnerButtonHeldDown
                    ? 0.95
                    : 1.0 - (widget.pulseAnimationController.value * 0.05);
                return Transform.scale(
                    scale: scale, child: child ?? const SizedBox());
              },
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [Colors.teal, Colors.cyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    boxShadow: [
                      BoxShadow(
                          color: const Color.fromARGB(102, 0, 150, 136),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 15))
                    ]),
                child: const Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          color: Colors.white, size: 70),
                      SizedBox(height: 8),
                      Text('Rooms',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}