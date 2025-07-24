// lib/widgets/home_screen/challenge_card.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/screens/goals_screen.dart';

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    const challenges = [
      "Bugün tanıştığın partnere en sevdiğin filmi anlat.",
      "Sohbetinde 5 yeni kelime kullanmayı dene.",
      "Partnerine 'Nasılsın?' demenin 3 farklı yolunu sor.",
    ];
    final randomChallenge = (List.of(challenges)..shuffle()).first;

    return InkWell(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const GoalsScreen()));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 5))
            ]),
        child: Row(
          children: [
            const Icon(Icons.flag_circle_outlined,
                color: Colors.amber, size: 40),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Günün Görevi",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(randomChallenge,
                      style:
                      TextStyle(color: Colors.grey[700], fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16)
          ],
        ),
      ),
    );
  }
}