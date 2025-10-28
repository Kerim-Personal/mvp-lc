// lib/screens/store_screen.dart
// Premium Store Ekranı - PaywallScreen ile aynı kalitede tasarım

import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vocachat/services/revenuecat_service.dart';
import 'package:vocachat/widgets/home_screen/premium_status_panel.dart';
import 'package:vocachat/widgets/shared/animated_background.dart';

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
  int _selectedPlanIndex = 1; // 0: Monthly, 1: Yearly
  int _currentFeaturePage = 0;
  bool _userInteracting = false;

  late PageController _pageController;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _autoScrollTimer;

  // Premium özellikler
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

  Future<void> _handlePurchase() async {
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
            const Text('Congratulations! 🎉'),
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
      backgroundColor: widget.embedded ? Colors.transparent : (isDark ? Colors.black : Colors.white),
      body: Stack(
        children: [
          // Animated Background - Diğer ekranlar gibi
          const Positioned.fill(child: AnimatedBackground()),

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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Diamond Animation
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

          // Title
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

          // Subtitle
          const Text(
            'Dil öğreniminde sınır tanıma',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 16),

          // Features List
          SizedBox(
            height: 160,
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
                children: _features.map((feature) => _buildFeatureCard(feature)).toList(),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Page Indicator Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_features.length, (index) {
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

          const SizedBox(height: 16),

          // Pricing Plans
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
                    badge: '7 DAYS FREE',
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
          ),

          const SizedBox(height: 12),

          // Get Premium Button
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
          ),

          const SizedBox(height: 6),

          // Restore Purchases
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

          const SizedBox(height: 2),

          // Terms
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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

          const SizedBox(height: 12),
        ],
      ),
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
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: PremiumStatusPanel(),
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

