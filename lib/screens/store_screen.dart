// lib/screens/store_screen.dart
// Premium UI gösterimi - satın alma backend mantığı kaldırıldı

import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vocachat/widgets/shared/animated_background.dart';
import 'package:vocachat/services/revenuecat_service.dart';
import 'package:vocachat/widgets/home_screen/premium_status_panel.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  bool _isPremium = false;
  PremiumPlan _selectedPlan = PremiumPlan.yearly;

  late final PageController _benefitPageController;
  int _currentBenefitPage = 0;
  late final TabController _tabController;
  late final VoidCallback _tabListener;
  Timer? _benefitsAutoScrollTimer;

  // CTA butonu için hafif nabız (scale) animasyonu
  late final AnimationController _ctaPulseController;
  late final Animation<double> _ctaPulse;

  // Premium benefits data
  static const List<_BenefitData> _premiumBenefits = [
    _BenefitData(
      'assets/animations/no ads icon.json',
      'Ad-free',
      'Zero distractions. Completely ad‑free interface for uninterrupted focus.',
    ),
    _BenefitData(
      'assets/animations/Translate.json',
      'Instant Translation',
      'Inline, instant message translation—stay immersed without switching apps.',
    ),
    _BenefitData(
      'assets/animations/Flags.json',
      'Language Diversity',
      'Over 100 languages supported in Vocabot for speech synthesis, translation and grammar analysis.',
    ),
    _BenefitData(
      'assets/animations/Support.json',
      'Priority Support',
      'Priority issue resolution: faster responses and direct escalation when something breaks.',
    ),
    _BenefitData(
      'assets/animations/Data Analysis.json',
      'Grammar Analysis',
      'Real‑time grammar and clarity suggestions to tighten every message as you type.',
    ),
    _BenefitData(
      'assets/animations/Robot says hello.json',
      'VocaBot',
      'AI practice companion offering contextual replies and gentle guidance while you learn.',
    ),
    _BenefitData(
      'assets/animations/Happy SUN.json',
      'Shimmer',
      'Exclusive visual polish and subtle premium animations that reinforce progress and motivation.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _tabListener = () => setState(() {});
    _tabController.addListener(_tabListener);
    _benefitPageController = PageController();

    // CTA için nabız animasyonu (subtle)
    _ctaPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _ctaPulse = Tween<double>(begin: 0.985, end: 1.015).animate(
      CurvedAnimation(parent: _ctaPulseController, curve: Curves.easeInOut),
    );
    _ctaPulseController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    // Kullanıcı durumunu dinle
    final user = _auth.currentUser;
    if (user != null) {
      // RevenueCat'i başlat ve kullanıcıyla ilişkilendir
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

    _startBenefitsAutoScroll();
  }

  void _startBenefitsAutoScroll() {
    _benefitsAutoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_benefitPageController.hasClients) return;

      final nextPage = (_currentBenefitPage + 1) % _premiumBenefits.length;
      _benefitPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _benefitsAutoScrollTimer?.cancel();
    try { _tabController.removeListener(_tabListener); } catch (_) {}
    _tabController.dispose();
    _benefitPageController.dispose();
    // CTA animasyon controller'ını kapat
    _ctaPulseController.dispose();
    super.dispose();
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _segmentedTabs(),
        const SizedBox(height: 6), // 8 -> 6 daha kompakt
      ],
    );
  }

  Widget _segmentedTabs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1
            ),
          ),
          child: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: EdgeInsets.zero,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                )
              ],
              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
            ),
            labelColor: Colors.black,
            unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [
              Tab(text: 'Premium', icon: Icon(Icons.workspace_premium, size: 18)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: widget.embedded ? Colors.transparent : (isDark ? Colors.black : Colors.white),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(42),
                  color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: -2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(42),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(42),
                        color: isDark ? Colors.black.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
                            child: _header(),
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _isPremium ? _buildPremiumActiveView() : _buildPremiumInfoView(),
                              ],
                            ),
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
    );
  }

  Widget _buildPremiumInfoView({Key? key}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: RevenueCatService.instance,
      builder: (context, _) {
        final monthlyText = RevenueCatService.instance.monthlyPriceString ?? '\$4.99/mo';
        final annualText = RevenueCatService.instance.annualPriceString ?? '\$29.99/yr';

        // Kaydırmasız kompakt düzen, faydalar alanı eski boyutunda (220)
        return LayoutBuilder(
          key: key,
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            const double benefitsH = 220.0; // eski sabit yükseklik
            const double dotsBlockH = 26.0; // üst/alt boşluklar dahil yaklaşık
            double planCardH = 110.0; // hedef
            double ctaH = 50.0; // hedef
            bool showDisclaimer = true;

            // Toplamı tahmini hesapla ve alan dar ise kademeli küçült
            double total(double planH, double btnH, bool disclaimer) =>
                benefitsH + dotsBlockH + planH + 12 + btnH + 8 + (disclaimer ? 56 : 0);

            // 1) Planı sıkıştır
            if (total(planCardH, ctaH, showDisclaimer) > h) {
              planCardH = (h - (benefitsH + dotsBlockH + 12 + ctaH + 8 + 56)).clamp(72.0, 116.0);
            }
            // 2) Butonu kısalt
            if (total(planCardH, ctaH, showDisclaimer) > h) {
              ctaH = 44.0;
            }
            // 3) Açıklamayı gerekirse gizle
            if (total(planCardH, ctaH, showDisclaimer) > h) {
              showDisclaimer = false;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Premium faydaları (eski yükseklikte ve görünür)
                  SizedBox(
                    height: benefitsH,
                    child: PageView.builder(
                      controller: _benefitPageController,
                      itemCount: _premiumBenefits.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentBenefitPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final benefit = _premiumBenefits[index];
                        return _buildBenefitCard(benefit);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Sayfa göstergesi (daha küçük)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _premiumBenefits.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: index == _currentBenefitPage ? 14 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: index == _currentBenefitPage
                              ? Colors.amber
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: index == _currentBenefitPage
                              ? [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.45),
                                    blurRadius: 5,
                                    spreadRadius: 0.5,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Fiyat/planlar (dinamik yükseklik)
                  SizedBox(
                    height: planCardH,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildPlanCard(
                            plan: PremiumPlan.monthly,
                            title: 'Monthly',
                            price: monthlyText,
                            height: planCardH,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPlanCard(
                            plan: PremiumPlan.yearly,
                            title: 'Yearly',
                            price: annualText,
                            isBestValue: true,
                            height: planCardH,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Vurgulu tek buton (dinamik yükseklik)
                  ScaleTransition(
                    scale: _ctaPulse,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        // Restore purchases TextButton rengini temel al: primary
                        color: Theme.of(context).colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: ctaH,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.workspace_premium, color: Theme.of(context).colorScheme.onPrimary, size: 18),
                          label: Text(
                            'Go Premium Now',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onPrimary),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: RevenueCatService.instance.isSupportedPlatform
                              ? _purchasePremium
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Purchases are not supported on this platform.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (showDisclaimer)
                    Opacity(
                      opacity: 0.8,
                      child: Column(
                        children: [
                          Text(
                            'Auto‑renewing. Cancel anytime in your store account settings.',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontSize: 10.5,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 28),
                            ),
                            onPressed: _restorePurchases,
                            child: const Text('Restore purchases'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlanCard({
    required PremiumPlan plan,
    required String title,
    required String price,
    bool isBestValue = false,
    double? height,
  }) {
    final bool isSelected = _selectedPlan == plan;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: Container(
        width: double.infinity,
        height: height ?? 132,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2.0 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 4, offset: const Offset(0, 1))
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    price,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (plan == PremiumPlan.yearly)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Save ~45% monthly',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.black87 : Colors.amber,
                          letterSpacing: 0.2,
                        ),
                      ),
                    )
                  else if (plan == PremiumPlan.monthly)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '7‑day free trial',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.black87 : Colors.cyanAccent,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isBestValue)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Best Value',
                    style: TextStyle(color: Colors.black, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumActiveView({Key? key}) {
    // Kaydırmasız kompakt aktif görünüm
    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final panelH = (maxH - 80).clamp(260.0, 360.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium, size: 42, color: Colors.amber),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Premium Active',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: panelH,
                child: const PremiumStatusPanel(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBenefitCard(_BenefitData benefit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Lottie.asset(
                      benefit.iconPath,
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                      repeat: true,
                      animate: true,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  benefit.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.25,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    benefit.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.85),
                      height: 1.25,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Placeholder metodlar - UI için
  // Rezervasyon: Satın alma akışı RevenueCat ile
  Future<void> _purchasePremium() async {
    try {
      final plan = _selectedPlan;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing purchase...'), behavior: SnackBarBehavior.floating),
      );
      final res = plan == PremiumPlan.monthly
          ? await RevenueCatService.instance.purchaseMonthly()
          : await RevenueCatService.instance.purchaseAnnual();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase successful!'), behavior: SnackBarBehavior.floating),
        );
      } else if (res.userCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase cancelled.'), behavior: SnackBarBehavior.floating),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: ${res.message ?? 'Unknown error'}'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _restorePurchases() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restoring purchases...'), behavior: SnackBarBehavior.floating),
    );
    final ok = await RevenueCatService.instance.restorePurchases();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Restored successfully.' : 'No purchases to restore.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _BenefitData {
  final String iconPath;
  final String title;
  final String description;

  const _BenefitData(this.iconPath, this.title, this.description);
}

enum PremiumPlan { monthly, yearly }
