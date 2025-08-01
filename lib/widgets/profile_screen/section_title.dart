// lib/widgets/profile_screen/section_title.dart

import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // HEDEFE YÖNELİK DÜZELTME: Başlık ve içerik arasındaki boşluğu azaltmak için 'bottom' değeri düşürüldü.
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Başlığın solundaki dekoratif çizgi
          Container(
            height: 24,
            width: 4,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // Başlık metni
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.75),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}