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
          elevation: 8.0,
          shadowColor: Colors.grey.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container( // InkWell kaldırıldı
            padding:
            const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.teal.shade50.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.waving_hand_rounded,
                    color: Colors.teal,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Merhaba,",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                // Yönlendirme oku kaldırıldı
              ],
            ),
          ),
        );
      },
    );
  }
}