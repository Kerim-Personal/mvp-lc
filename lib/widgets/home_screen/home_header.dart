// lib/widgets/home_screen/home_header.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async'; // Timer için eklendi
import 'dart:math' as math; // sin dalgası için

class HomeHeader extends StatefulWidget {
  const HomeHeader({
    super.key,
    required this.userName,
    required this.avatarUrl,
    required this.streak,
    this.isPremium = false,
    required this.currentUser,
    this.role = 'user',
  });

  final String userName;
  final String? avatarUrl;
  final int streak;
  final bool isPremium;
  final User? currentUser;
  final String? role;

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _bgController; // arka plan animasyonu

  Color _roleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'moderator':
        return Colors.orange;
      default:
        return Colors.white;
    }
  }

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _shimmerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            _shimmerController.forward(from: 0.0);
          }
        });
      }
    });

    if (widget.isPremium) {
      _shimmerController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant HomeHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isPremium && widget.isPremium) {
      // Premium’a geçildiyse shimmer’ı başlat
      _shimmerController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _roleColor(widget.role);
    final now = DateTime.now();
    final palette = _selectAdaptivePalette(now, widget.isPremium, widget.role);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28.0),
      child: Stack(
        children: [
          // Arka plan gradient (animasyonlu)
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              // Kesintisiz döngü için sinüs tabanlı kaydırma
              final phase = _bgController.value; // 0..1
              final wave1 = math.sin(phase * 2 * math.pi); // -1..1
              final wave2 = math.sin(phase * 2 * math.pi + math.pi / 2);
              final tLight = (wave1 * 0.5 + 0.5); // 0..1
              final modulated = _modulatePalette(palette, tLight);
              final begin = Alignment(-0.65 + 0.35 * wave1, -0.75 + 0.30 * wave2);
              final end = Alignment(0.65 + 0.25 * wave2, 0.75 - 0.35 * wave1);
              final gradient = LinearGradient(
                colors: modulated,
                begin: begin,
                end: end,
              );
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                decoration: BoxDecoration(gradient: gradient),
                child: _buildContent(baseColor),
              );
            },
          ),
          // Gloss overlay (üst kısımda hafif parlaklık)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.04),
                      Colors.black.withValues(alpha: 0.10),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // İnce kenar ışık & gölge
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color baseColor) {
    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: 16),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: _buildAnimatedName(baseColor)),
                  const SizedBox(width: 8),
                  _buildStreakChip(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    final bool premium = widget.isPremium;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: premium
            ? [
                BoxShadow(
                  color: const Color(0xFFE5B53A).withValues(alpha: 0.55),
                  blurRadius: 18,
                  spreadRadius: 1.5,
                ),
                BoxShadow(
                  color: const Color(0xFF8F6A00).withValues(alpha: 0.35),
                  blurRadius: 32,
                  spreadRadius: 10,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        child: widget.avatarUrl != null
            ? ClipOval(
                child: SvgPicture.network(
                  widget.avatarUrl!,
                  width: 56,
                  height: 56,
                  placeholderBuilder: (context) => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                ),
              )
            : Text(
                widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildAnimatedName(Color baseColor) {
    if (!widget.isPremium) {
      return Text(
        widget.userName,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: baseColor),
        overflow: TextOverflow.ellipsis,
      );
    }
    final bool isSpecialRole = (widget.role == 'admin' || widget.role == 'moderator');
    final Color shimmerBase = isSpecialRole ? baseColor : const Color(0xFFE5B53A);
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final highlightColor = Colors.white;
        final value = _shimmerController.value;
        final start = value * 1.5 - 0.5;
        final end = value * 1.5;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [shimmerBase, highlightColor, shimmerBase],
            stops: [start, (start + end) / 2, end].map((e) => e.clamp(0.0, 1.0)).toList(),
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: child,
        );
      },
      child: Text(
        widget.userName,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: shimmerBase,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStreakChip() {
    if (widget.streak <= 0) return const SizedBox.shrink();
    final bool hot = widget.streak >= 7;
    return AnimatedScale(
      duration: const Duration(milliseconds: 400),
      scale: 1.0 + (hot ? 0.03 : 0.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: hot
                ? const [Color(0xFFFFB347), Color(0xFFFF7050)]
                : const [Color(0xFFBBBEC1), Color(0xFF9DA0A3)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(hot ? Icons.local_fire_department : Icons.whatshot_outlined,
                size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              '${widget.streak}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Gradient _selectAdaptiveGradient(DateTime now, bool isPremium, String? role) {
    final hour = now.hour;
    // Time-based palette
    if (isPremium) {
      if (role == 'admin') {
        return const LinearGradient(
          colors: [Color(0xFF5A0000), Color(0xFFB30000), Color(0xFFFF6A00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      if (role == 'moderator') {
        return const LinearGradient(
          colors: [Color(0xFF4E2E00), Color(0xFFCC7A00), Color(0xFFFFC773)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      // Premium normal kullanıcı altın + derinlik
      return const LinearGradient(
        colors: [Color(0xFF3B2A00), Color(0xFF8B6300), Color(0xFFE5B53A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (hour >= 5 && hour < 12) {
      // Sabah
      return const LinearGradient(
        colors: [Color(0xFFFFECD2), Color(0xFFFCCF8A), Color(0xFFEFA45C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (hour >= 12 && hour < 18) {
      // Öğlen
      return const LinearGradient(
        colors: [Color(0xFF0093E9), Color(0xFF38B2AC), Color(0xFF006F7A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (hour >= 18 && hour < 22) {
      // Akşamüstü / Gün batımı
      return const LinearGradient(
        colors: [Color(0xFF41295A), Color(0xFF6F2F84), Color(0xFFD66D75)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // Gece
      return const LinearGradient(
        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  List<Color> _selectAdaptivePalette(DateTime now, bool isPremium, String? role) {
    final g = _selectAdaptiveGradient(now, isPremium, role) as LinearGradient;
    return g.colors;
  }

  List<Color> _modulatePalette(List<Color> base, double t) {
    if (base.isEmpty) return [Colors.grey];
    // Hafif nefes alma efekti: renkleri sırayla azıcık aydınlat / koyulaştır.
    return List<Color>.generate(base.length, (i) {
      final c = base[i];
      // i ile faz kaydırmalı sinüs; süreklilik için sin kullanılır.
      final wave = math.sin((t + i * 0.33) * math.pi * 2) * 0.09; // ~ -0.09..0.09 light adjust
       // Yalın lighten/darken: Color.lerp ile beyaza veya siyaha çek.
       final Color target = wave >= 0 ? Colors.white : Colors.black;
       final factor = wave.abs();
       return Color.lerp(c, target, factor) ?? c;
    });
  }
}