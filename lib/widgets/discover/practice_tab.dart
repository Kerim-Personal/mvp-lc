// lib/widgets/discover/practice_tab.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lingua_chat/screens/practice_writing_screen.dart';
import 'package:lingua_chat/screens/practice_reading_screen.dart';
import 'package:lingua_chat/screens/practice_listening_screen.dart';

// --- VERİ MODELLERİ ---
class _ModeData {
  final String title;
  final String tagline;
  final String description;
  final List<Color> colors;
  final IconData icon;
  final String backgroundImage; // eklendi
  const _ModeData({
    required this.title,
    required this.tagline,
    required this.description,
    required this.colors,
    required this.icon,
    required this.backgroundImage,
  });
}

// --- ANA WIDGET ---
class PracticeTab extends StatelessWidget {
  const PracticeTab({super.key});

  static final List<_ModeData> practiceModes = [
    _ModeData(
      title: 'Writing',
      tagline: 'Düşün – Yaz – Parla',
      description: 'Mini yazma görevleriyle ifade gücünü şımart.',
      colors: const [Color(0xFFFF9A9E), Color(0xFFF76D84)],
      icon: Icons.edit_rounded,
      backgroundImage: 'assets/practice/writing_bg.jpg',
    ),
    _ModeData(
      title: 'Reading',
      tagline: 'Oku – Keşfet',
      description: 'Tatlı kısa pasajlarla anlam avına çık.',
      colors: const [Color(0xFFA18CD1), Color(0xFF915ADB)],
      icon: Icons.menu_book_rounded,
      backgroundImage: 'assets/practice/reading_bg.jpg',
    ),
    _ModeData(
      title: 'Listening',
      tagline: 'Dinle – Yakala',
      description: 'Sevimli seslerle pratik yap, kulağın alışsın.',
      colors: const [Color(0xFF2BC0E4), Color(0xFF84FAB0)],
      icon: Icons.headphones_rounded,
      backgroundImage: 'assets/practice/listening_bg.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _AnimatedBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const _PracticeHeader(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isWide = constraints.maxWidth > 600;
                        if (isWide) {
                          return Row(
                            children: practiceModes
                                .map((mode) => Expanded(
                                      child: _PracticeModeCard(data: mode, compact: false),
                                    ))
                                .toList(),
                          );
                        } else {
                          // Dikey alanı 3 karta böl
                          const spacing = 10.0;
                          final totalSpacing = spacing * 2; // 3 kart arası 2 boşluk
                          final cardHeight = (constraints.maxHeight - totalSpacing).clamp(140.0, 1000.0) / 3;
                          return Column(
                            children: [
                              SizedBox(
                                height: cardHeight,
                                child: _PracticeModeCard(data: practiceModes[0], compact: cardHeight < 200),
                              ),
                              const SizedBox(height: spacing),
                              SizedBox(
                                height: cardHeight,
                                child: _PracticeModeCard(data: practiceModes[1], compact: cardHeight < 200),
                              ),
                              const SizedBox(height: spacing),
                              SizedBox(
                                height: cardHeight,
                                child: _PracticeModeCard(data: practiceModes[2], compact: cardHeight < 200),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- KART WIDGET'I ---
class _PracticeModeCard extends StatelessWidget {
  final _ModeData data;
  final bool compact;
  const _PracticeModeCard({required this.data, this.compact = false});

  void _open(BuildContext context) {
    Widget? target;
    switch (data.title) {
      case 'Writing':
        target = const PracticeWritingScreen();
        break;
      case 'Reading':
        target = const PracticeReadingScreen();
        break;
      case 'Listening':
        target = const PracticeListeningScreen();
        break;
    }
    if (target != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => target!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        // Padding içerik üstüne taşındı (Stack ile resim altında kalacak)
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 22 : 28),
          gradient: LinearGradient(
            colors: data.colors.map((c) => c.withValues(alpha: 0.65)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: data.colors.last.withValues(alpha: 0.38),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(compact ? 22 : 28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Arka plan resmi (hata durumunda degrade görünür)
              Image.asset(
                data.backgroundImage,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
              ),
              // Koyulaştırıcı filtre
              Container(color: Colors.black.withValues(alpha: 0.42)),
              // Üst gradient okunabilirlik
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.30),
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.40),
                        ],
                        stops: const [0, 0.55, 1],
                      ),
                    ),
                  ),
                ),
              ),
              // İçerik
              Padding(
                padding: EdgeInsets.all(compact ? 14 : 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(compact ? 8 : 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                      child: Icon(data.icon, color: Colors.white, size: compact ? 22 : 28),
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    Text(
                      data.title,
                      style: TextStyle(
                        fontSize: compact ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.05,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: compact ? 4 : 6),
                    Text(
                      data.tagline,
                      style: TextStyle(
                        fontSize: compact ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    Expanded(
                      child: Text(
                        data.description,
                        style: TextStyle(
                          fontSize: compact ? 11.5 : 13,
                          color: Colors.white.withValues(alpha: 0.95),
                          height: 1.25,
                        ),
                        maxLines: compact ? 3 : 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(Icons.arrow_forward_rounded, color: Colors.white.withValues(alpha: 0.95), size: compact ? 20 : 22),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- HEADER WIDGET'I ---
class _PracticeHeader extends StatelessWidget {
  const _PracticeHeader();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0ED2F7), Color(0xFFB2FEFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0ED2F7).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pratik Yap',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Günde 10 dakika, düzenli ilerleme. Hadi başlayalım!',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.92)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- ARKA PLAN ANİMASYONU ---
class _AnimatedBackdrop extends StatefulWidget {
  const _AnimatedBackdrop();
  @override
  State<_AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<_AnimatedBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _BlobPainter(_ctrl.value),
          );
        },
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double t;
  _BlobPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c1 = Offset(
      size.width * (0.3 + 0.1 * sin(t * 2 * pi)),
      size.height * 0.4,
    );
    final c2 = Offset(
      size.width * (0.7 + 0.1 * cos(t * 2 * pi)),
      size.height * 0.6,
    );

    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF81D4FA).withValues(alpha: 0.2), Colors.transparent],
      ).createShader(Rect.fromCircle(center: c1, radius: size.width * 0.5));
    final p2 = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFA5D6A7).withValues(alpha: 0.2), Colors.transparent],
      ).createShader(Rect.fromCircle(center: c2, radius: size.width * 0.5));

    canvas.drawCircle(c1, size.width * 0.5, p1);
    canvas.drawCircle(c2, size.width * 0.5, p2);
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}