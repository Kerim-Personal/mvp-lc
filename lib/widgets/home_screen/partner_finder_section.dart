// lib/widgets/home_screen/partner_finder_section.dart

import 'package:flutter/material.dart';

class PartnerFinderSection extends StatefulWidget {
  final VoidCallback onFindPartner;
  final VoidCallback onShowGenderFilter;
  final VoidCallback onShowLevelFilter;
  final String? selectedGenderFilter;
  final String? selectedLevelGroupFilter;
  final AnimationController pulseAnimationController;

  const PartnerFinderSection({
    super.key,
    required this.onFindPartner,
    required this.onShowGenderFilter,
    required this.onShowLevelFilter,
    required this.selectedGenderFilter,
    required this.selectedLevelGroupFilter,
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
                      Icon(Icons.language_sharp,
                          color: Colors.white, size: 70),
                      SizedBox(height: 8),
                      Text('Partner Bul',
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFilterButton(
              icon: Icons.wc,
              label: 'Cinsiyet',
              onTap: widget.onShowGenderFilter,
              value: widget.selectedGenderFilter == 'Male'
                  ? 'Erkek'
                  : widget.selectedGenderFilter == 'Female'
                  ? 'Kadın'
                  : null,
            ),
            const SizedBox(width: 20),
            _buildFilterButton(
              icon: Icons.bar_chart_rounded,
              label: 'Seviye',
              onTap: widget.onShowLevelFilter,
              value: widget.selectedLevelGroupFilter,
            ),
          ],
        )
      ],
    );
  }

  Widget _buildFilterButton(
      {required IconData icon,
        required String label,
        required VoidCallback onTap,
        String? value}) {
    final bool isActive = value != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.teal.withAlpha(26) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border:
          Border.all(color: isActive ? Colors.teal : Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(20, 0, 0, 0),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.teal, size: 20),
            const SizedBox(width: 8),
            Text(
              isActive ? '$label: $value' : label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.teal.shade800 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}