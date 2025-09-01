// lib/widgets/discover/practice_tab.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lingua_chat/screens/practice_writing_screen.dart';
import 'package:lingua_chat/screens/practice_reading_screen.dart';
import 'package:lingua_chat/screens/practice_listening_screen.dart';
import 'package:lingua_chat/screens/practice_speaking_screen.dart';

// --- VERİ MODELLERİ ---
// Sınıf, "private type in a public API" hatasını çözmek için herkese açık hale getirildi.
class ModeData {
  final String title;
  final String tagline;
  final String description;
  final List<Color> colors;
  final IconData icon;
  final String backgroundImage;
  const ModeData({
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

  static final List<ModeData> practiceModes = [
    ModeData(
      title: 'Writing',
      tagline: 'Düşün – Yaz – Parla',
      description: 'Mini yazma görevleriyle ifade gücünü şımart.',
      colors: const [Color(0xFFFF9A9E), Color(0xFFF76D84)],
      icon: Icons.edit_rounded,
      backgroundImage: 'assets/practice/writing_bg.jpg',
    ),
    ModeData(
      title: 'Reading',
      tagline: 'Oku – Keşfet',
      description: 'Tatlı kısa pasajlarla anlam avına çık.',
      colors: const [Color(0xFFA18CD1), Color(0xFF915ADB)],
      icon: Icons.menu_book_rounded,
      backgroundImage: 'assets/practice/reading_bg.jpg',
    ),
    ModeData(
      title: 'Listening',
      tagline: 'Dinle – Yakala',
      description: 'Sevimli seslerle pratik yap, kulağın alışsın.',
      colors: const [Color(0xFF2BC0E4), Color(0xFF84FAB0)],
      icon: Icons.headphones_rounded,
      backgroundImage: 'assets/practice/listening_bg.jpg',
    ),
    ModeData(
      title: 'Speaking',
      tagline: 'Konuş – Akıcı Ol',
      description: 'Sesli tekrarlarla konuşma pratiği.',
      colors: const [Color(0xFFFFCF71), Color(0xFF2376DD)],
      icon: Icons.mic_rounded,
      backgroundImage: 'assets/practice/speaking_bg.jpg',
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
                  // Header kaldırıldı
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isWide = constraints.maxWidth > 600;
                        if (isWide) {
                          return Row(
                            children: practiceModes
                                .map((mode) => Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: _PracticeModeCard(data: mode, compact: false),
                                      ),
                                    ))
                                .toList(),
                          );
                        } else {
                          const spacing = 12.0;
                          final count = practiceModes.length;
                          final totalSpacing = spacing * (count - 1);
                          final cardHeight = (constraints.maxHeight - totalSpacing).clamp(140.0, 2000.0) / count;
                          return Column(
                            children: [
                              for (int i = 0; i < practiceModes.length; i++) ...[
                                Expanded(
                                  child: _PracticeModeCard(
                                    data: practiceModes[i],
                                    compact: cardHeight < 200,
                                  ),
                                ),
                                if (i != practiceModes.length - 1) const SizedBox(height: spacing),
                              ]
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
  final ModeData data;
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
      case 'Speaking':
        target = const PracticeSpeakingScreen();
        break;
    }
    if (target != null) {
      final screen = target; // null değil, local değişkene al
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => screen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 22 : 28),
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
              Image.asset(
                data.backgroundImage,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: data.colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              // Düzeltme: Linter kurallarına uymak için .withValues() kullanılıyor.
              Container(color: Colors.black.withValues(alpha: 0.42)),
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.30),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.40),
                        ],
                        stops: const [0, 0.5, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(compact ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(compact ? 8 : 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.22),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Icon(data.icon, color: Colors.white, size: compact ? 22 : 28),
                    ),
                    SizedBox(height: compact ? 10 : 16),
                    Text(
                      data.title,
                      style: TextStyle(
                        fontSize: compact ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(Icons.arrow_forward_rounded, color: Colors.white.withValues(alpha: 0.95), size: compact ? 22 : 24),
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