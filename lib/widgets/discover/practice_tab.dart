// lib/widgets/discover/practice_tab.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vocachat/screens/practice_writing_screen.dart';
import 'package:vocachat/screens/practice_reading_screen.dart';
import 'package:vocachat/screens/practice_listening_screen.dart';
import 'package:vocachat/screens/practice_speaking_screen.dart';
// Yeni: premium kontrolü ve upsell için gerekli importlar
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocachat/widgets/home_screen/premium_upsell_dialog.dart';
import 'package:vocachat/screens/store_screen.dart';

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
      tagline: 'Think • Write • Shine',
      description: 'Boost expression with mini writing tasks.',
      colors: const [Color(0xFFFF9A9E), Color(0xFFF76D84)],
      icon: Icons.edit_rounded,
      backgroundImage: 'assets/practice/writing_bg.jpg',
    ),
    ModeData(
      title: 'Reading',
      tagline: 'Read • Explore',
      description: 'Short passages to build comprehension.',
      colors: const [Color(0xFFA18CD1), Color(0xFF915ADB)],
      icon: Icons.menu_book_rounded,
      backgroundImage: 'assets/practice/reading_bg.jpg',
    ),
    ModeData(
      title: 'Listening',
      tagline: 'Listen • Catch',
      description: 'Friendly audio to train your ear.',
      colors: const [Color(0xFF2BC0E4), Color(0xFF84FAB0)],
      icon: Icons.headphones_rounded,
      backgroundImage: 'assets/practice/listening_bg.jpg',
    ),
    ModeData(
      title: 'Speaking',
      tagline: 'Speak • Be Fluent',
      description: 'Voice repetitions to improve speaking.',
      colors: const [Color(0xFFFFCF71), Color(0xFF2376DD)],
      icon: Icons.mic_rounded,
      backgroundImage: 'assets/practice/speaking_bg.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Kullanıcının premium durumunu Firestore'dan dinle
    final user = FirebaseAuth.instance.currentUser;
    final Stream<bool> premiumStream = (user == null)
        ? Stream<bool>.value(false)
        : FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => (doc.data()?['isPremium'] == true));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _AnimatedBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<bool>(
                stream: premiumStream,
                initialData: false,
                builder: (context, snapshot) {
                  final isPremium = snapshot.data == true;
                  return Column(
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
                                    child: _PracticeModeCard(
                                      data: mode,
                                      compact: false,
                                      isPremium: isPremium,
                                    ),
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
                                        isPremium: isPremium,
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
                  );
                },
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
  final bool isPremium; // Premium ise rozet gösterme
  const _PracticeModeCard({required this.data, this.compact = false, this.isPremium = false});

  Future<void> _handleTap(BuildContext context) async {
    // 1) Kullanıcı premium mu kontrol et
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    bool isPremium = false;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server));
        isPremium = (doc.data()?['isPremium'] == true);
      } catch (_) {
        // Sunucudan alınamazsa, önbellekten dene
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          isPremium = (doc.data()?['isPremium'] == true);
        } catch (_) {}
      }
    }

    if (!isPremium) {
      // 2) Premium değilse upsell dialog aç
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const PremiumUpsellDialog(),
      );
      if (result == 'discover') {
        // 3) Kullanıcı keşfet dedi -> StoreScreen'e yönlendir
        if (context.mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StoreScreen()),
          );
        }
        // PremiumUpsellDialog, Discover seçildiğinde PaywallScreen'i açar.
        // Burada ekstra bir yönlendirme yapmaya gerek yok.
        return;
      }
      return; // erişim yok, çık
    }

    // 4) Premium ise hedef ekrana geç
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
    if (target != null && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => target!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Semantics(
        button: true,
        label: 'Open ${data.title} mode',
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
                // Daha parlak görünüm için overlay alpha değeri azaltıldı
                Container(color: Colors.black.withValues(alpha: 0.20)),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.25),
                          ],
                          stops: const [0, 0.5, 1],
                        ),
                      ),
                    ),
                  ),
                ),
                // İçerik
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
                // Premium değilse sağ üstte küçük bir PRO rozeti/kilit işareti (overlay)
                if (!isPremium)
                  Positioned(
                    top: compact ? 8 : 10,
                    right: compact ? 8 : 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 4 : 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, size: compact ? 12 : 14, color: Colors.amberAccent),
                          SizedBox(width: compact ? 4 : 6),
                          Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: compact ? 10 : 11.5,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
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
