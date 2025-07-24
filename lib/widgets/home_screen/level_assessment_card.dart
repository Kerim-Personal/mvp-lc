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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade300, Colors.deepPurple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.deepPurple.withAlpha(50),
                  blurRadius: 10,
                  offset: const Offset(0, 5))
            ]),
        child: const Row(
          children: [
            Icon(Icons.school_outlined, color: Colors.white, size: 40),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Seviyeni Keşfet",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white)),
                  SizedBox(height: 4),
                  Text("Hemen teste başla ve dil seviyeni öğren!",
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16)
          ],
        ),
      ),
    );
  }
}