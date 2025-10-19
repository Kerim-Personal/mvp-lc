// lib/widgets/home_screen/home_header.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'dart:math' as math;

class HomeHeader extends StatefulWidget {
  const HomeHeader({
    super.key,
    required this.userName,
    required this.avatarUrl,
    required this.diamonds,
    this.isPremium = false,
    required this.currentUser,
    this.role = 'user',
    this.onTap, // Tıklanabilirlik için onTap parametresi eklendi
  });

  final String userName;
  final String? avatarUrl;
  final int diamonds; // diamonds gösteriyoruz
  final bool isPremium;
  final User? currentUser;
  final String? role;
  final VoidCallback? onTap; // Tıklama callback'i

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final AnimationController _bgController;

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
          if (mounted) _shimmerController.forward(from: 0);
        });
      }
    });

    if (widget.isPremium) _shimmerController.forward();
  }

  @override
  void didUpdateWidget(covariant HomeHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isPremium && widget.isPremium) _shimmerController.forward(from: 0);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _bgController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final baseColor = _roleColor(widget.role);
    final now = DateTime.now();
    final palette = _selectAdaptivePalette(now, widget.isPremium, widget.role);

    final header = ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          // Animasyonlu arka plan (blur kaldırıldı)
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) {
              final phase = _bgController.value;
              final wave1 = math.sin(phase * 2 * math.pi);
              final wave2 = math.sin(phase * 2 * math.pi + math.pi / 2);
              final tLight = (wave1 * 0.5 + 0.5);
              final modulated = _modulatePalette(palette, tLight);

              final begin = Alignment(-0.65 + 0.35 * wave1, -0.75 + 0.3 * wave2);
              final end = Alignment(0.65 + 0.25 * wave2, 0.75 - 0.35 * wave1);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: modulated,
                    begin: begin,
                    end: end,
                  ),
                ),
                child: _buildContent(baseColor),
              );
            },
          ),
          // Hafif parlaklık (gloss)
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

    // Eğer onTap varsa GestureDetector ile sarmalayalım
    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: header,
      );
    }

    return header;
  }

  Widget _buildContent(Color baseColor) {
    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildAnimatedName(baseColor)),
              const SizedBox(width: 8),
              _buildCompactDiamondsChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    final premium = widget.isPremium;
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
            placeholderBuilder: (_) =>
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
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
      return FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: Text(
          widget.userName,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: baseColor),
          maxLines: 1,
          softWrap: false,
        ),
      );
    }

    final isSpecialRole = (widget.role == 'admin' || widget.role == 'moderator');
    final shimmerBase = isSpecialRole ? baseColor : const Color(0xFFE5B53A);

    return FittedBox(
      alignment: Alignment.centerLeft,
      fit: BoxFit.scaleDown,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          final value = _shimmerController.value;
          final start = value * 1.5 - 0.5;
          final end = value * 1.5;
          return ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [shimmerBase, Colors.white, shimmerBase],
                stops: [start, (start + end) / 2, end].map((e) => e.clamp(0.0, 1.0)).toList(),
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
            },
            child: child,
          );
        },
        child: Text(
          widget.userName,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: shimmerBase),
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }

  // Eski streak chip kaldırıldı
  // Diamond format fonksiyonu + compact chip
  String _formatDiamonds(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(v % 1000000 >= 100000 ? 1 : 0)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(v % 1000 >= 100 ? 1 : 0)}K';
    return '$v';
  }

  Widget _buildCompactDiamondsChip() {
    final isPremiumUser = widget.isPremium;
    final statusText = isPremiumUser ? 'Premium' : 'Starter';
    final statusIcon = isPremiumUser ? Icons.workspace_premium : Icons.stars;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _openStore,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          constraints: const BoxConstraints(minHeight: 32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: isPremiumUser
                  ? const [Color(0xFF7F5DFF), Color(0xFFE5B53A)]
                  : const [Color(0xFF545B62), Color(0xFF6B7280)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openStore() {
    if (!mounted) return;
    Navigator.of(context).pushNamed('/store');
  }

  List<Color> _selectAdaptivePalette(DateTime now, bool isPremium, String? role) {
    if (isPremium) {
      if (role == 'admin') return [const Color(0xFF5A0000), const Color(0xFFB30000), const Color(0xFFFF6A00)];
      if (role == 'moderator') return [const Color(0xFF4E2E00), const Color(0xFFCC7A00), const Color(0xFFFFC773)];
      return [const Color(0xFF3B2A00), const Color(0xFF8B6300), const Color(0xFFE5B53A)];
    }
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return [const Color(0xFFFFECD2), const Color(0xFFFCCF8A), const Color(0xFFEFA45C)];
    if (hour >= 12 && hour < 18) return [const Color(0xFF0093E9), const Color(0xFF38B2AC), const Color(0xFF006F7A)];
    if (hour >= 18 && hour < 22) return [const Color(0xFF41295A), const Color(0xFF6F2F84), const Color(0xFFD66D75)];
    return [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)];
  }

  List<Color> _modulatePalette(List<Color> base, double t) {
    if (base.isEmpty) return [Colors.grey];
    return List<Color>.generate(base.length, (i) {
      final c = base[i];
      final wave = math.sin((t + i * 0.33) * math.pi * 2) * 0.09;
      final target = wave >= 0 ? Colors.white : Colors.black;
      return Color.lerp(c, target, wave.abs()) ?? c;
    });
  }
}
