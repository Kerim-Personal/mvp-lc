// lib/screens/store_screen.dart
// Premium Store Ekranı - PaywallScreen ile aynı kalitede tasarım

import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vocachat/services/revenuecat_service.dart';
import 'package:vocachat/widgets/shared/animated_background.dart';
import 'package:vocachat/screens/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  bool _isPremium = false;
  bool _isLoading = false;
  bool _hasUsedFreeTrial = false;
  int _selectedPlanIndex = 1; // 0: Monthly, 1: Yearly
  int _currentFeaturePage = 0;
  bool _userInteracting = false;

  late PageController _pageController;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _autoScrollTimer;

  // İndirim yüzdesini hesapla
  String get _discountPercentage {
    final monthlyPrice = RevenueCatService.instance.monthlyPrice;
    final annualPrice = RevenueCatService.instance.annualPrice;

    if (monthlyPrice != null && annualPrice != null && monthlyPrice > 0) {
      final yearlyEquivalent = monthlyPrice * 12;
      final discount = ((yearlyEquivalent - annualPrice) / yearlyEquivalent * 100).round();
      return '$discount% OFF';
    }
    return '30% OFF'; // Fallback
  }

  // Premium özellikler - Dosya isimleri güvenli hale getirildi (snake_case)
  static const List<_FeatureData> _features = [
    _FeatureData(
      'assets/animations/no ads icon.json',
      'Ad-Free Experience',
      'Learn without interruptions. Focus better with a completely ad-free interface.',
    ),
    _FeatureData(
      'assets/animations/Translate.json',
      'Instant Translation',
      'Translate messages instantly without switching apps. Keep learning seamlessly.',
    ),
    _FeatureData(
      'assets/animations/Flags.json',
      'Language Diversity',
      'VocaBot supports 100+ languages for speech, translation, and grammar analysis.',
    ),
    _FeatureData(
      'assets/animations/Support.json',
      'Priority Support',
      'Fast solutions to your problems with direct communication and premium support.',
    ),
    _FeatureData(
      'assets/animations/Data Analysis.json',
      'Grammar Analysis',
      'Real-time grammar and clarity suggestions to improve every message you write.',
    ),
    _FeatureData(
      'assets/animations/Robot says hello.json',
      'VocaBot AI Assistant',
      'AI practice companion offering contextual responses and gentle guidance.',
    ),
    _FeatureData(
      'assets/animations/olympicsports.json',
      'Practice Modes',
      'Writing, Reading, Listening, Speaking practices to master all language skills.',
    ),
    _FeatureData(
      'assets/animations/Happy SUN.json',
      'Shimmer Effect',
      'Exclusive visual polish and subtle premium animations that reinforce progress and motivation.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
    _initializeServices();
    _startAutoScroll();
  }

  Future<void> _initializeServices() async {
    final user = _auth.currentUser;
    if (user != null) {
      await RevenueCatService.instance.init();
      await RevenueCatService.instance.onLogin(user.uid);
      await RevenueCatService.instance.refreshOfferings();

      // Ücretsiz deneme durumunu kontrol et
      final hasUsedTrial = RevenueCatService.instance.hasUsedFreeTrial;
      if (mounted) {
        setState(() {
          _hasUsedFreeTrial = hasUsedTrial;
        });
      }

      _userSub = _firestore.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (mounted && doc.exists) {
          final data = doc.data();
          setState(() {
            _isPremium = data?['isPremium'] == true;
          });
        }
      });
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || _userInteracting) return;
      if (!_pageController.hasClients) return;

      final nextPage = (_currentFeaturePage + 1) % _features.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _restartAutoScroll() {
    _stopAutoScroll();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_userInteracting) {
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<bool> _ensureLoggedIn() async {
    final user = _auth.currentUser;
    if (user != null) return true;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Giriş gerekli'),
        content: const Text('Satın alma işlemi için lütfen önce hesabınıza giriş yapın.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(false);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Giriş Yap'),
          ),
        ],
      ),
    );

    return proceed == true;
  }

  Future<void> _handlePurchase() async {
    // Giriş kontrolü
    if (!await _ensureLoggedIn()) return;

    setState(() => _isLoading = true);

    try {
      final outcome = _selectedPlanIndex == 0
          ? await RevenueCatService.instance.purchaseMonthly()
          : await RevenueCatService.instance.purchaseAnnual();

      if (!mounted) return;

      if (outcome.success) {
        _showSuccessDialog();
      } else if (!outcome.userCancelled) {
        _showErrorDialog(outcome.message ?? 'Purchase failed.');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Lottie.asset('assets/animations/success.json', width: 50, height: 50, repeat: false),
            const SizedBox(width: 12),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Congratulations! 🎉',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Your Premium membership has been successfully activated. Enjoy all the features!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Notice'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRestore() async {
    // Giriş kontrolü
    if (!await _ensureLoggedIn()) return;

    setState(() => _isLoading = true);

    try {
      final restored = await RevenueCatService.instance.restorePurchases();
      if (!mounted) return;

      if (restored) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('No purchases found to restore.');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Restore failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated Background - Tam ekran
          const AnimatedBackground(),

          // Main Content with Glassmorphism Container
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: -2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _isPremium ? _buildPremiumActiveView() : _buildPremiumInfoView(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumInfoView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Üst bölüm
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Lottie.asset(
                          'assets/animations/diamond_icon.json',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'VocaChat Premium',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Go beyond limits in language learning',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),

                  // Orta bölüm: özellikler + planlar + buton
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: Listener(
                          onPointerDown: (_) {
                            setState(() => _userInteracting = true);
                            _stopAutoScroll();
                          },
                          onPointerUp: (_) {
                            setState(() => _userInteracting = false);
                            _restartAutoScroll();
                          },
                          child: PageView(
                            controller: _pageController,
                            physics: const BouncingScrollPhysics(),
                            onPageChanged: (index) {
                              setState(() => _currentFeaturePage = index);
                            },
                            children: _features.map((f) => _buildFeatureCard(f)).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_features.length, (index) {
                          final active = _currentFeaturePage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: active ? 20 : 6,
                            decoration: BoxDecoration(
                              color: active ? Colors.white : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildPlanCard(
                                index: 0,
                                title: 'Monthly',
                                price: RevenueCatService.instance.monthlyPriceString ?? r'$9.99',
                                period: '/mo',
                                badge: _hasUsedFreeTrial ? null : '7 DAYS FREE',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPlanCard(
                                index: 1,
                                title: 'Yearly',
                                price: RevenueCatService.instance.annualPriceString ?? r'$79.99',
                                period: '/yr',
                                badge: _discountPercentage,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handlePurchase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6C63FF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 6,
                              shadowColor: Colors.black.withValues(alpha: 0.3),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                              ),
                            )
                                : const Text(
                              'Get Premium',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Alt bölüm: restore + şartlar
                  Column(
                    children: [
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: _isLoading ? null : _handleRestore,
                        child: const Text(
                          'Restore Purchases',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'By continuing, you agree to our Terms of Service and Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9, height: 1.3),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard(_FeatureData feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Lottie.asset(
                feature.animation,
                width: 56,
                height: 56,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              feature.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              feature.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11.5,
                height: 1.3,
                letterSpacing: 0.1,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String title,
    required String price,
    required String period,
    String? badge,
  }) {
    final isSelected = _selectedPlanIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 18,
              child: badge != null
                  ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? const Color(0xFF6C63FF).withValues(alpha: 0.7)
                          : Colors.white70,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumActiveView() {
    // Burada direkt içeriği döndürüyoruz.
    // StoreScreen'in kendi container'ı arka plan görevi görecek.
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: _PremiumStatusPanel(),
    );
  }
}

// Feature Data Model
class _FeatureData {
  final String animation;
  final String title;
  final String description;

  const _FeatureData(this.animation, this.title, this.description);
}

// ============================================================================
// PREMIUM STATUS PANEL - İÇ İÇE KUTU SORUNU DÜZELTİLDİ
// ============================================================================
// Gold Background (İçteki kutu) tamamen kaldırıldı.
// Sadece içerik (Yazı, Liste, Buton) döndürülüyor.

class _PremiumStatusPanel extends StatefulWidget {
  const _PremiumStatusPanel();

  @override
  State<_PremiumStatusPanel> createState() => _PremiumStatusPanelState();
}

class _PremiumStatusPanelState extends State<_PremiumStatusPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3500))
      ..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SADELEŞTİRİLDİ: Arka plan container'ı ve Stack kaldırıldı.
    // Direkt içeriği döndürüyoruz.
    return LayoutBuilder(builder: (context, constraints) {
      return Padding(
        // İçeriği biraz ortalamak ve sıkışıklığı önlemek için padding
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: _PanelContent(
          shimmerController: _shimmerController,
        ),
      );
    });
  }
}

// _AnimatedGoldBackground SINIFI SİLİNDİ (Teke indirildi)

class _PanelContent extends StatelessWidget {
  final AnimationController shimmerController;
  const _PanelContent({required this.shimmerController});

  // Dosya isimleri güvenli hale getirildi
  List<_PremiumBenefit> get _benefits => const [
    _PremiumBenefit('assets/animations/no ads icon.json', 'Ad-free'),
    _PremiumBenefit('assets/animations/Translate.json', 'Instant Translation'),
    _PremiumBenefit('assets/animations/Flags.json', 'Language Diversity'),
    _PremiumBenefit('assets/animations/Support.json', 'Priority Support'),
    _PremiumBenefit('assets/animations/Data Analysis.json', 'Grammar Analysis'),
    _PremiumBenefit('assets/animations/Robot says hello.json', 'VocaBot'),
    _PremiumBenefit('assets/animations/olympicsports.json', 'Practice'),
    _PremiumBenefit('assets/animations/Happy SUN.json', 'Shimmer'),
  ];

  @override
  Widget build(BuildContext context) {
    final shimmerSize = 13.5;
    final bodySize = 11.0;
    final chipFont = 10.5;

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _ShimmerTitle(controller: shimmerController, fontSize: shimmerSize),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                'A faster, focused, and enjoyable learning experience with Pro.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: bodySize.clamp(11, 12),
                  height: 1.3,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _BenefitGrid(benefits: _benefits, chipFontSize: chipFont),
            const SizedBox(height: 10),
            const _ThanksRow(), // Düzeltilmiş Row yapısı
            const SizedBox(height: 12),
            const _ManageSubscriptionButton(),
          ],
        ),
      );
    });
  }
}

class _ShimmerTitle extends StatelessWidget {
  final AnimationController controller;
  final double fontSize;
  const _ShimmerTitle({required this.controller, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final v = controller.value;
        double start = (v * 1.4 - 0.4).clamp(0.0, 1.0);
        double end = (start + 0.35).clamp(0.0, 1.0);
        if (end - start < 0.05) {
          end = (start + 0.05).clamp(0.0, 1.0);
        }
        final mid = start + (end - start) / 2;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (b) => LinearGradient(
            colors: const [
              Color(0xFFFFE8A3),
              Colors.white,
              Color(0xFFFFE8A3)
            ],
            stops: [start, mid, end],
          ).createShader(b),
          child: Text(
            'You are a VocaChat Pro Member',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }
}

class _BenefitGrid extends StatelessWidget {
  final List<_PremiumBenefit> benefits;
  final double chipFontSize;
  const _BenefitGrid({required this.benefits, required this.chipFontSize});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < benefits.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == benefits.length - 1 ? 0 : 6),
            child: _BenefitChip(
              benefit: benefits[i],
              fontSize: chipFontSize,
              index: i,
            ),
          ),
      ],
    );
  }
}

class _BenefitChip extends StatelessWidget {
  final _PremiumBenefit benefit;
  final double fontSize;
  final int index;
  const _BenefitChip(
      {required this.benefit, required this.fontSize, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 40),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 6),
            child: child,
          ),
        );
      },
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.18),
              Colors.white.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              benefit.animationPath,
              width: 20,
              height: 20,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 10),
            Text(
              benefit.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize.clamp(11, 12),
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// BU KISIM DÜZELTİLDİ (Gri Kutu Hatası Giderildi)
class _ThanksRow extends StatelessWidget {
  const _ThanksRow();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 1.2,
            width: 100,
            margin: const EdgeInsets.only(bottom: 5),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFE8A3),
                  Color(0xFFE5B53A),
                  Color(0xFFFFE8A3)
                ],
              ),
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            // Wrap yerine Row kullanıldı ve Flexible doğru yere kondu
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium,
                    color: Color(0xFFFFE8A3), size: 15),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Your support strengthens the learning community. Thank you, Pro member!',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                    ),
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

class _ManageSubscriptionButton extends StatelessWidget {
  const _ManageSubscriptionButton();

  Future<void> _openSubscriptionManagement(BuildContext context) async {
    const url = 'https://play.google.com/store/account/subscriptions';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open subscription management'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openSubscriptionManagement(context),
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.25),
              Colors.white.withValues(alpha: 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings,
              color: Colors.white.withValues(alpha: 0.95),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Manage Subscription',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.95),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumBenefit {
  final String animationPath;
  final String label;
  const _PremiumBenefit(this.animationPath, this.label);
}