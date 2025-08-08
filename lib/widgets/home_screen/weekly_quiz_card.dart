// lib/widgets/home_screen/weekly_quiz_card.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/screens/weekly_quiz_screen.dart';

class WeeklyQuizCard extends StatelessWidget {
  const WeeklyQuizCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WeeklyQuizScreen()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade300, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.indigo.withAlpha(70),
                  blurRadius: 12,
                  offset: const Offset(0, 6))
            ]),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_outlined, color: Colors.white, size: 44),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Haftalık Yarışma",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Premium ödüllü online bilgi yarışmasına katıl!",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    // ÇÖZÜLDÜ: 'withOpacity' uyarısını gidermek için 'withAlpha' kullanıldı.
                    // (255 * 0.9 ~= 230)
                    style: TextStyle(color: Colors.white.withAlpha(230), fontSize: 14),
                  ),
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