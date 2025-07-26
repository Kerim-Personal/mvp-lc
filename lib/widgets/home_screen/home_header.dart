// lib/widgets/home_screen/home_header.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.userNameFuture,
    required this.currentUser,
  });

  final Future<String?> userNameFuture;
  final User? currentUser;

  // YENİ: Avatar URL'sini almak için Future
  Future<String?> _getAvatarUrl(String? uid) async {
    if (uid == null) return null;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['avatarUrl'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String?>>(
      // Aynı anda hem kullanıcı adını hem de avatar URL'sini bekliyoruz
      future: Future.wait([userNameFuture, _getAvatarUrl(currentUser?.uid)]),
      builder: (context, snapshot) {
        final userName = snapshot.data?[0] ?? 'Gezgin';
        final avatarUrl = snapshot.data?[1];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28.0),
            gradient: LinearGradient(
              colors: [Colors.teal.shade600, Colors.teal.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Merhaba, $userName',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.25),
                child: avatarUrl != null
                    ? ClipOval(
                  child: SvgPicture.network(
                    avatarUrl,
                    width: 48,
                    height: 48,
                    placeholderBuilder: (context) => const SizedBox(
                        width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    ),
                  ),
                )
                    : Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}