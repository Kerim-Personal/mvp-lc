// lib/widgets/home_screen/challenge_card.dart

import 'package:flutter/material.dart';
import 'package:vocachat/models/challenge_model.dart';
import 'package:vocachat/screens/challenge_screen.dart';

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Logic to keep the same challenge for each day using day-of-year index
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
          // UPDATE: Added gradient instead of solid white color.
            gradient: LinearGradient(
              colors: [Colors.amber.shade400, Colors.orange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            // UPDATE: Stronger shadow matching the gradient.
            boxShadow: [
              BoxShadow(
                  color: Colors.orange.withAlpha(70),
                  blurRadius: 12,
                  offset: const Offset(0, 6))
            ]),
        child: Row(
          children: [
            // UPDATE: Icon color set to white and size increased slightly.
            const Icon(Icons.flag_circle_outlined,
                color: Colors.white, size: 44),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Daily Challenge",
                    // UPDATE: Text color set to white.
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
                    // UPDATE: Text color white with adjusted opacity.
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                  ),
                ],
              ),
            ),
            // UPDATE: Icon color set to white.
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16)
          ],
        ),
      ),
    );
  }
}