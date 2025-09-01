// lib/widgets/profile_screen/section_title.dart

import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Decorative bar at the left of the title
          Container(
            height: 24,
            width: 4,
            decoration: BoxDecoration(
              // OPTIMIZATION: Using withOpacity instead of withAlpha for performance.
              color: Colors.teal.withOpacity(0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // Title text
          // OPTIMIZATION: Opacity handled via Opacity widget.
          Opacity(
            opacity: 0.90,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}