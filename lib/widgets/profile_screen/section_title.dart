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
          // Başlığın solundaki dekoratif çizgi
          Container(
            height: 24,
            width: 4,
            decoration: BoxDecoration(
              // ÇÖZÜLDÜ: withOpacity uyarısını gidermek için withAlpha kullanıldı.
              // 204 değeri, %80 opaklığa denk gelir (255 * 0.8).
              color: Colors.teal.withAlpha(204),
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
              // ÇÖZÜLDÜ: withOpacity uyarısını gidermek için withAlpha kullanıldı.
              // 191 değeri, %75 opaklığa denk gelir (255 * 0.75).
              color: Colors.black.withAlpha(191),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}