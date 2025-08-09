// lib/widgets/home_screen/home_header.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.userName,
    required this.avatarUrl,
    required this.streak,
    this.isPremium = false,
    required this.currentUser,
  });

  final String userName;
  final String? avatarUrl;
  final int streak;
  final bool isPremium;
  final User? currentUser;

  @override
  Widget build(BuildContext context) {
    const premiumColor = Color(0xFFE5B53A);
    const premiumIcon = Icons.auto_awesome;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
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
        children: [
          // 1. AVATAR (SOLDA)
          CircleAvatar(
            radius: 28, // Avatarı biraz büyüttük
            backgroundColor: Colors.white.withOpacity(0.25),
            child: avatarUrl != null
                ? ClipOval(
              child: SvgPicture.network(
                avatarUrl!,
                width: 56,
                height: 56,
                placeholderBuilder: (context) => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white)),
              ),
            )
                : Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 2. METİN ALANI (SAĞDA)
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // KULLANICI ADI VE PREMIUM İKONU
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        userName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isPremium ? premiumColor : Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPremium)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child:
                        Icon(premiumIcon, color: premiumColor, size: 22),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // SERİ BİLGİSİ ALT BAŞLIĞI
                Text(
                  '$streak günlük serinle devam et!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}