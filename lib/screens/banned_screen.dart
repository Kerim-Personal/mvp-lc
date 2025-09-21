// lib/screens/banned_screen.dart
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vocachat/widgets/shared/animated_background.dart';

class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF000000),
        body: Center(
          child: Text(
            'No active session.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF000000),
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.red,
                strokeWidth: 3,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorScreen(context);
        }

        if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
          return const Scaffold(
            backgroundColor: Color(0xFF000000),
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.red,
                strokeWidth: 3,
              ),
            ),
          );
        }

        final data = snapshot.data!.data();
        final reason = (data?['bannedReason'] as String?)?.trim();
        final details = (data?['bannedDetails'] as String?)?.trim();
        final bannedAt = data?['bannedAt'] as Timestamp?;
        final formattedDate = bannedAt != null
            ? DateFormat('d MMM y HH:mm', 'en_US').format(bannedAt.toDate())
            : null;
        final isPremium = (data?['isPremium'] as bool?) == true;

        return _buildBannedScreen(context, currentUser, reason, details, formattedDate, isPremium);
      },
    );
  }

  Widget _buildErrorScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF330000), // Koyu kırmızı merkez
              Color(0xFF1a0000), // Daha koyu kırmızı
              Color(0xFF000000), // Siyah kenarlar
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background tüm ekranı kaplasın
            const Positioned.fill(
              child: AnimatedBackground(),
            ),
            // Korkunç kırmızı partiküller efekti
            const Positioned.fill(
              child: _HorrorParticles(),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.black.withValues(alpha: 0.8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    Colors.red,
                                    Color(0xFF8B0000),
                                    Color(0xFF330000),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.8),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.dangerous_rounded,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'FATAL ERROR',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'System connection failed',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            _buildHorrorButton(
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                              },
                              icon: Icons.exit_to_app_rounded,
                              label: 'EXIT',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannedScreen(
    BuildContext context,
    User currentUser,
    String? reason,
    String? details,
    String? formattedDate,
    bool isPremium
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF330000), // Koyu kırmızı merkez
              Color(0xFF1a0000), // Daha koyu kırmızı
              Color(0xFF000000), // Siyah kenarlar
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background tüm ekranı kaplasın
            const Positioned.fill(
              child: AnimatedBackground(),
            ),
            // Korkunç kırmızı partiküller efekti
            const Positioned.fill(
              child: _HorrorParticles(),
            ),
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.8),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.5),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.only(
                top: 60, // Status bar için üst padding
                left: 32,
                right: 32,
                bottom: 32,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Korkunç ban skull icon'u
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [
                            Colors.red,
                            Color(0xFF8B0000),
                            Color(0xFF330000),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.8),
                            blurRadius: 60,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.block_rounded,
                        size: 70,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Korkunç başlık
                    const Text(
                      'ACCESS DENIED',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.red,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: Colors.red,
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Korkunç alt başlık
                    const Text(
                      'YOUR ACCOUNT HAS BEEN BANNED',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have violated our terms of service',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    if (reason != null && reason.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _buildHorrorInfoCard('VIOLATION', reason.toUpperCase()),
                    ],

                    if (details != null && details.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildHorrorInfoCard('DETAILS', details),
                    ],

                    if (formattedDate != null) ...[
                      const SizedBox(height: 16),
                      _buildHorrorInfoCard('BANNED ON', formattedDate),
                    ],

                    // Butonları büyük kutunun içine ekliyoruz
                    const SizedBox(height: 32),

                    // Korkunç aksiyon butonları
                    Column(
                      children: [
                        _buildHorrorButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                          },
                          icon: Icons.exit_to_app_rounded,
                          label: 'EXIT',
                        ),

                        const SizedBox(height: 16),

                        if (isPremium)
                          _buildHorrorButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/support');
                            },
                            icon: Icons.support_agent_rounded,
                            label: 'CONTACT SUPPORT',
                            isSecondary: true,
                          )
                        else
                          _buildHorrorButton(
                            onPressed: () => _sendAppealEmail(context, currentUser, reason, details, formattedDate),
                            icon: Icons.email_rounded,
                            label: 'APPEAL BAN',
                            isSecondary: true,
                          ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorrorInfoCard(String title, String content) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.6),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.red,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorrorButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isSecondary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSecondary
            ? LinearGradient(
                colors: [
                  Colors.grey.shade800.withValues(alpha: 0.8),
                  Colors.grey.shade900.withValues(alpha: 0.8),
                ],
              )
            : const LinearGradient(
                colors: [
                  Color(0xFF8B0000),
                  Color(0xFF330000),
                ],
              ),
          border: Border.all(
            color: isSecondary
              ? Colors.grey.withValues(alpha: 0.5)
              : Colors.red.withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSecondary
                ? Colors.grey.withValues(alpha: 0.3)
                : Colors.red.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendAppealEmail(
    BuildContext context,
    User currentUser,
    String? reason,
    String? details,
    String? formattedDate,
  ) async {
    final uid = currentUser.uid;
    final subject = 'Ban Appeal - $uid';
    final body = [
      'Hello, I would like to appeal the ban on my account.',
      if (reason != null && reason.isNotEmpty) 'Reason: $reason',
      if (formattedDate != null) 'Date: $formattedDate',
      if (details != null && details.isNotEmpty) 'Details: $details',
      '',
      'Please review and respond.\nThank you.'
    ].join('\n');
    final uri = Uri(
      scheme: 'mailto',
      path: 'info@codenzi.com',
      query: Uri.encodeFull('subject=$subject&body=$body'),
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open email app.'),
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

// Korkunç partiküller efekti için yeni widget
class _HorrorParticles extends StatefulWidget {
  const _HorrorParticles();

  @override
  State<_HorrorParticles> createState() => _HorrorParticlesState();
}

class _HorrorParticlesState extends State<_HorrorParticles>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _HorrorParticlesPainter(_controller.value),
        );
      },
    );
  }
}

class _HorrorParticlesPainter extends CustomPainter {
  final double animation;

  _HorrorParticlesPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Korkunç kırmızı partiküller çiz
    for (int i = 0; i < 20; i++) {
      final x = (size.width * 0.1 * i + animation * 50) % size.width;
      final y = (size.height * 0.05 * i + animation * 30) % size.height;
      final radius = 2.0 + (i % 3);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
