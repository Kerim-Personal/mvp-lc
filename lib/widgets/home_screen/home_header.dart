// lib/widgets/home_screen/home_header.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async'; // Timer için eklendi

class HomeHeader extends StatefulWidget {
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
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Animasyon süresini 4 saniyeye çıkardım
    );

    // Animasyon durumunu dinleyerek döngüyü kontrol ediyoruz
    _shimmerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Animasyon bittikten sonra 1 saniye bekle ve tekrar başlat
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            _shimmerController.forward(from: 0.0);
          }
        });
      }
    });

    // İlk animasyonu başlat
    _shimmerController.forward();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const premiumColor = Color(0xFFE5B53A);
    const premiumIcon = Icons.auto_awesome;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
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
            radius: 24,
            backgroundColor: Colors.white.withOpacity(0.25),
            child: widget.avatarUrl != null
                ? ClipOval(
              child: SvgPicture.network(
                widget.avatarUrl!,
                width: 48,
                height: 48,
                placeholderBuilder: (context) => const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white)),
              ),
            )
                : Text(
              widget.userName.isNotEmpty
                  ? widget.userName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 24,
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
                      child: AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          final baseColor =
                          widget.isPremium ? premiumColor : Colors.white;
                          final highlightColor = Colors.white;

                          // Efektin en soldan başlayıp en sağda bitmesini sağlayan yeni stop değerleri
                          final value = _shimmerController.value;
                          final start = value * 1.5 - 0.5;
                          final end = value * 1.5;

                          return ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [baseColor, highlightColor, baseColor],
                              stops: [start, (start + end) / 2, end],
                            ).createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            ),
                            child: child,
                          );
                        },
                        child: Text(
                          widget.userName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                            widget.isPremium ? premiumColor : Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (widget.isPremium)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(premiumIcon,
                            color: premiumColor, size: 22),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}