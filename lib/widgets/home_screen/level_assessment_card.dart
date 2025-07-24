// lib/widgets/home_screen/level_assessment_card.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/screens/level_assessment_screen.dart';

class LevelAssessmentCard extends StatelessWidget {
  const LevelAssessmentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const LevelAssessmentScreen()));
      },
      borderRadius: BorderRadius.circular(16), // Kenar yuvarlaklığı ayarlandı
      child: Container(
        // DÜZELTME: İç boşluklar azaltıldı
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade300, Colors.deepPurple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.deepPurple.withAlpha(50),
                  blurRadius: 10,
                  offset: const Offset(0, 5))
            ]),
        child: Row(
          children: [
            // DÜZELTME: İkon boyutu küçültüldü
            const Icon(Icons.school_outlined, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Seviyeni Keşfet",
                      style: TextStyle(
                        // DÜZELTME: Font boyutu küçültüldü
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text("Hemen teste başla ve dil seviyeni öğren!",
                      // DÜZELTME: Font boyutu küçültüldü
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16)
          ],
        ),
      ),
    );
  }
}