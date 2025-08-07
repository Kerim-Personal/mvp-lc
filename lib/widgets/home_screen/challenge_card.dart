// lib/widgets/home_screen/challenge_card.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/models/challenge_model.dart';
import 'package:lingua_chat/screens/challenge_screen.dart';

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Her gün aynı görevin gelmesi için günün sırasını kullanan mantık
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final challengeIndex = dayOfYear % challenges.length;
    final dailyChallenge = challenges[challengeIndex];

    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ChallengeScreen(challenge: dailyChallenge)));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // GÜNCELLEME: Düz beyaz renk yerine gradient eklendi.
            gradient: LinearGradient(
              colors: [Colors.amber.shade400, Colors.orange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            // GÜNCELLEME: Gradient ile uyumlu, daha belirgin bir gölge eklendi.
            boxShadow: [
              BoxShadow(
                  color: Colors.orange.withAlpha(70),
                  blurRadius: 12,
                  offset: const Offset(0, 6))
            ]),
        child: Row(
          children: [
            // GÜNCELLEME: İkon rengi beyaz yapıldı ve boyutu biraz büyütüldü.
            const Icon(Icons.flag_circle_outlined,
                color: Colors.white, size: 44),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Günün Görevi",
                    // GÜNCELLEME: Metin rengi beyaz yapıldı.
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dailyChallenge.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    // GÜNCELLEME: Metin rengi opaklığı ayarlanmış beyaz yapıldı.
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                  ),
                ],
              ),
            ),
            // GÜNCELLEME: İkon rengi beyaz yapıldı.
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16)
          ],
        ),
      ),
    );
  }
}