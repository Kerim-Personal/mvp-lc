// lib/widgets/home_screen/home_header.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.userNameFuture,
    required this.currentUser,
  });

  final Future<String?> userNameFuture;
  final User? currentUser;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: userNameFuture,
      builder: (context, snapshot) {
        final userName = snapshot.data ?? 'Gezgin';
        return Card(
          elevation: 4.0, // Gölgeyi biraz azalttık
          shadowColor: Colors.grey.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Daha yumuşak kenarlar
          ),
          child: Container(
            padding:
            // DÜZELTME: İç boşluklar azaltıldı
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.teal.shade50.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10), // Boşluk azaltıldı
                  decoration: BoxDecoration(
                    color: Colors.teal.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.waving_hand_rounded,
                    color: Colors.teal,
                    // DÜZELTME: İkon boyutu küçültüldü
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Merhaba,",
                        style: TextStyle(
                          // DÜZELTME: Font boyutu küçültüldü
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userName,
                        style: TextStyle(
                          // DÜZELTME: Font boyutu küçültüldü
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}