// lib/widgets/home_screen/premium_upsell_dialog.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vocachat/main.dart';

class PremiumUpsellDialog extends StatefulWidget {
  const PremiumUpsellDialog({super.key});

  @override
  State<PremiumUpsellDialog> createState() => _PremiumUpsellDialogState();
}

class _PremiumUpsellDialogState extends State<PremiumUpsellDialog> with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final PageController _pageController;
  int _currentPage = 0;

  static const List<_FeatureData> _features = [
    _FeatureData(
      'Ad-free',
      'Zero distractions. Completely ad‑free interface for uninterrupted focus.',
      'assets/animations/no ads icon.json',
    ),
    _FeatureData(
      'Instant Translation',
      'Inline, instant message translation—stay immersed without switching apps.',
      'assets/animations/Translate.json',
    ),
    _FeatureData(
      'Language Diversity',
      'Over 100 languages supported in Vocabot for speech synthesis, translation and grammar analysis',
      'assets/animations/Flags.json',
    ),
    _FeatureData(
      'Priority Support',
      'Priority issue resolution: faster responses and direct escalation when something breaks.',
      'assets/animations/Support.json',
    ),
    _FeatureData(
      'Grammar Analysis',
      'Real‑time grammar and clarity suggestions to tighten every message as you type.',
      'assets/animations/Data Analysis.json',
    ),
    _FeatureData(
      'VocaBot',
      'AI practice companion offering contextual replies and gentle guidance while you learn.',
      'assets/animations/Robot says hello.json',
    ),
    _FeatureData(
      'Shimmer',
      'Exclusive visual polish and subtle premium animations that reinforce progress and motivation.',
      'assets/animations/Happy SUN.json',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnimation = CurvedAnimation(parent: _entryController, curve: Curves.elasticOut);
    _fadeAnimation = CurvedAnimation(parent: _entryController, curve: Curves.easeIn);
    _entryController.forward();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.85; // Yüksekliği artırdım
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40), // Dikey padding artırdım
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxHeight,
                maxWidth: 500,
                minWidth: 300,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade800.withValues(alpha: 0.85),
                      Colors.deepPurple.shade900.withValues(alpha: 0.95)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Üst boşluk
                    const SizedBox(height: 16),
                    // Shimmer efektli başlık
                    Shimmer.fromColors(
                      baseColor: Colors.white,
                      highlightColor: Colors.amber.shade300,
                      period: const Duration(milliseconds: 1500),
                      child: const Text(
                        'VocaChat Pro',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Unlock powerful features for better learning',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Büyütülmüş özellik kartları
                    Flexible(child: _buildFeaturePager()), // Flexible ekledi
                    const SizedBox(height: 12),
                    _PageDots(count: _features.length, current: _currentPage),
                    const SizedBox(height: 16),
                    // Butonlar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                                elevation: 7,
                                shadowColor: Colors.amber.withValues(alpha: 0.45),
                                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                rootScreenKey.currentState?.changeTab(0);
                              },
                              child: const Text('Discover VocaChat Pro'),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Not Now', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16), // Alt boşluk
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Tekli sayfa düzeni (her sayfada 1 özellik)
  // Kartları daha kompakt hale getiriyorum
  Widget _buildFeaturePager() {
    const cardHeight = 180.0; // Yüksekliği azalttım - daha kompakt görünüm
    return SizedBox(
      height: cardHeight,
      width: double.infinity,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _features.length,
        onPageChanged: (i) => setState(() => _currentPage = i),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16), // Yanlarda boşluk
            child: _FeatureRow(data: _features[index], index: index),
          );
        },
      ),
    );
  }
}

class _FeatureData {
  final String label;
  final String description;
  final String animationPath; // Yeni alan
  const _FeatureData(this.label, this.description, this.animationPath);
}

class _FeatureRow extends StatelessWidget {
  final _FeatureData data;
  final int index;
  const _FeatureRow({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index % 3) * 110),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 14),
          child: child,
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 160, // Minimum yüksekliği azalttım
          maxHeight: 170, // Maksimum yükseklik sınırı
          maxWidth: 400,  // Genişliği biraz azalttım
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), // Köşeleri biraz daha az yuvarlak
          color: const Color(0xFF1A1A2E),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15), // Gölgeyi hafifleştirdim
              blurRadius: 6,
              offset: const Offset(0, 1),
            )
          ],
        ),
        padding: const EdgeInsets.all(16), // Padding'i azalttım
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Daha küçük Lottie animasyonu
            Container(
              width: 70, // Boyutu küçülttüm
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5F5DC),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Lottie.asset(
                data.animationPath,
                width: 70,
                height: 70,
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
              ),
            ),
            const SizedBox(height: 12), // Boşluğu azalttım
            // Metin kısmı - daha kompakt
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    data.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16, // Font boyutunu küçülttüm
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6), // Boşluğu azalttım
                  Expanded(
                    child: Text(
                      data.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11, // Font boyutunu küçülttüm
                        fontWeight: FontWeight.w400,
                        height: 1.2, // Satır yüksekliğini azalttım
                        letterSpacing: 0.05,
                      ),
                      maxLines: 3, // Maksimum 3 satır
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;
  const _PageDots({required this.count, required this.current});
  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            width: i == current ? 18 : 6,
            decoration: BoxDecoration(
              color: i == current ? Colors.amber : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              boxShadow: i == current
                  ? [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
          ),
      ],
    );
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) => child;
}
