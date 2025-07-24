// lib/widgets/home_screen/home_header.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/screens/profile_screen.dart';
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
        return InkWell(
          onTap: () {
            if (currentUser != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: currentUser!.uid),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.teal.withAlpha(26),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : "G",
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hoş Geldin,",
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400)),
                    Text(userName,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.grey, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}