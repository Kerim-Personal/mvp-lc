// lib/screens/paywall_screen.dart
// Kaliteli Paywall Ekranı - Her uygulama açılışında gösterilir

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vocachat/services/revenuecat_service.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocachat/screens/login_screen.dart';

class PaywallScreen extends StatefulWidget {
  final VoidCallback? onClose;
  final bool canDismiss;

  const PaywallScreen({
    super.key,
    this.onClose,
    this.canDismiss = true,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late PageController _pageController;

  int _selectedPlanIndex = 1;
  int _currentFeaturePage = 0;
  bool _isLoading = false;
  bool _isPremium = false;
  bool _userInteracting = false;
  bool _hasUsedFreeTrial = false;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
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

    _pageController = PageController();
    _animController.forward();
    _checkPremiumStatus();
    RevenueCatService.instance.addListener(_onRevenueCatUpdate);
    _startAutoScroll();
  }

  void _onRevenueCatUpdate() {
    final premium = RevenueCatService.instance.isPremiumActive;
    final hasUsedTrial = RevenueCatService.instance.hasUsedFreeTrial;
    if (mounted) {
      setState(() {
        _isPremium = premium;
        _hasUsedFreeTrial = hasUsedTrial;
      });
      if (premium && widget.onClose != null) {
        widget.onClose!();
      }
    }
  }

  Future<void> _checkPremiumStatus() async {
    // RevenueCat'i başlat ve varsa oturumu bağla
    final user = FirebaseAuth.instance.currentUser;
    await RevenueCatService.instance.init();
    if (user != null) {
      await RevenueCatService.instance.onLogin(user.uid);
    }

    // Firestore'dan da premium durumunu kontrol et (web veya RC gecikmesi için yedek)
    bool firestorePremium = false;
    if (user != null) {
      try {
        final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (snap.exists && snap.data() != null) {
          firestorePremium = snap.data()!['isPremium'] == true;
        }
      } catch (_) {
        // sessizce yoksay
      }
    }

    if (mounted) {
      final rcPremium = RevenueCatService.instance.isPremiumActive;
      final premium = rcPremium || firestorePremium;
      final hasUsedTrial = RevenueCatService.instance.hasUsedFreeTrial;

      setState(() {
        _isPremium = premium;
        _hasUsedFreeTrial = hasUsedTrial;
      });

      if (premium && widget.onClose != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) widget.onClose!();
        });
      }
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || _userInteracting) return;
      if (!_pageController.hasClients) return;

      final nextPage = (_currentFeaturePage + 1) % 6;
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
    _autoScrollTimer?.cancel();
    RevenueCatService.instance.removeListener(_onRevenueCatUpdate);
    _animController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _ensureLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
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

    return PopScope(
      canPop: widget.canDismiss,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                  ]
                      : [
                    const Color(0xFF6C63FF),
                    const Color(0xFF8B5CF6),
                    const Color(0xFFEC4899),
                  ],
                ),
              ),
            ),

            // Animated Background Elements
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Close Button
                      if (widget.canDismiss)
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              onPressed: widget.onClose,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 8),

                      // Scrollable Content
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),

                              // Gradient Diamond Animation
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: Lottie.asset(
                                  'assets/animations/diamond_icon.json',
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.contain,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Title
                              const Text(
                                'VocaChat Premium',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),

                              const SizedBox(height: 6),

                              // Subtitle
                              const Text(
                                'Push your limits in language learning',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Features List - DÜZELTME: Timer ile kontrol edilir
                              SizedBox(
                                height: 170,
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
                                    children: [
                                      _buildFeatureCard(
                                        animation: 'assets/animations/no ads icon.json',
                                        title: 'Ad-Free Experience',
                                        description: 'Learn without interruptions. Focus better with a completely ad-free interface.',
                                      ),
                                      _buildFeatureCard(
                                        animation: 'assets/animations/Translate.json',
                                        title: 'Instant Translation',
                                        description: 'Translate messages instantly without switching apps. Keep learning seamlessly.',
                                      ),
                                      _buildFeatureCard(
                                        animation: 'assets/animations/Flags.json',
                                        title: 'Language Diversity',
                                        description: 'VocaBot supports 100+ languages for speech, translation, and grammar analysis.',
                                      ),
                                      _buildFeatureCard(
                                        animation: 'assets/animations/Support.json',
                                        title: 'Priority Support',
                                        description: 'Fast solutions to your problems with direct communication and premium support.',
                                      ),
                                      _buildFeatureCard(
                                        animation: 'assets/animations/Data Analysis.json',
                                        title: 'Grammar Analysis',
                                        description: 'Real-time grammar and clarity suggestions to improve every message you write.',
                                      ),
                                      _buildFeatureCard(
                                        animation: 'assets/animations/Robot says hello.json',
                                        title: 'VocaBot AI Assistant',
                                        description: 'AI practice companion offering contextual responses and gentle guidance.',
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Page Indicator Dots
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(6, (index) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    height: 6,
                                    width: _currentFeaturePage == index ? 20 : 6,
                                    decoration: BoxDecoration(
                                      color: _currentFeaturePage == index
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  );
                                }),
                              ),

                              const SizedBox(height: 20),

                              // Pricing Plans
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  children: [
                                    Row(
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
                                            badge: '30% OFF',
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 14),

                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _handlePurchase,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFF6C63FF),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
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
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    TextButton(
                                      onPressed: _isLoading ? null : _handleRestore,
                                      child: const Text(
                                        'Restore Purchases',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        'By continuing, you agree to our Terms of Service and Privacy Policy.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 9,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),
                                  ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String animation,
    required String title,
    required String description,
  }) {
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
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
                animation,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
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
        height: 100,
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
              height: 20,
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
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 18,
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
                      fontSize: 11,
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
}
