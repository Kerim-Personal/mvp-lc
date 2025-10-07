// lib/screens/store_screen.dart
// Premium durum kontrolü hatası düzeltildi. Mantık daha sağlam hale getirildi.
// Elmas paketi görünümü, modern, simetrik ve dengeli bir tasarım için tamamen yeniden düzenlendi.

import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:vocachat/services/diamond_service.dart';
import 'package:vocachat/services/purchase_service.dart';
import 'package:vocachat/widgets/shared/animated_background.dart';
import 'package:vocachat/widgets/store_screen/glassmorphism.dart';
import 'package:vocachat/widgets/home_screen/premium_status_panel.dart';
import 'package:shimmer/shimmer.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

enum PremiumPlan { monthly, yearly }

class _StoreScreenState extends State<StoreScreen> with TickerProviderStateMixin {
  final PurchaseService _purchaseService = PurchaseService();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  StreamSubscription<int?>? _diamondsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  // Hata mesajları için abonelik
  StreamSubscription<String>? _purchaseErrorsSub;

  int? _diamonds;
  PremiumPlan _selectedPlan = PremiumPlan.yearly;

  bool _isPremium = false;

  bool _loadingProducts = true;
  bool _initTried = false;

  late final PageController _benefitPageController; // Premium benefits için PageController
  int _currentBenefitPage = 0; // Aktif benefit sayfası

  late final TabController _tabController; // Geri eklendi
  late final VoidCallback _tabListener;    // Geri eklendi

  final Set<String> _purchasing = {};
  Timer? _benefitsAutoScrollTimer; // 5 sn'de bir otomatik kaydırma

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
    _tabController = TabController(length: 1, vsync: this); // Tek sekme
    _tabListener = () => setState(() {});
    _tabController.addListener(_tabListener);
    _benefitPageController = PageController();
    // 5 saniyede bir faydaları döngüsel kaydır
    _benefitsAutoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _autoScrollBenefits());

    // PurchaseService hata akışını dinle ve kullanıcıya göster
    _purchaseErrorsSub = _purchaseService.errors.listen((msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    });

    _init();
  }

  void _autoScrollBenefits() {
    if (!mounted) return;
    if (!_benefitPageController.hasClients) return;
    final total = _premiumBenefits.length;
    if (total <= 1) return;
    final next = (_currentBenefitPage + 1) % total;
    _benefitPageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _init() async {
    if (_initTried) return;
    _initTried = true;
    await _purchaseService.init();
    if (!mounted) return;
    if (mounted) setState(() => _loadingProducts = false);

    _listenUser();
    _diamondsSub = DiamondService().diamondsStream().listen((v) {
      if (mounted) setState(() => _diamonds = v);
    });
    // isteğe bağlı: mevcut değeri yenile
    unawaited(DiamondService().currentDiamonds(refresh: true));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _diamonds == null) {
        setState(() => _diamonds = 0);
      }
    });
  }

  void _listenUser() {
    final user = _auth.currentUser;
    if (user == null) return;
    _userSub = _firestore.collection('users').doc(user.uid).snapshots().listen((snap) {
      final data = snap.data();
      final isPremiumFlag = (data?['isPremium'] as bool?) ?? false;
      if (mounted) {
        setState(() {
          _isPremium = isPremiumFlag;
        });
      }
    });
  }

  @override
  void dispose() {
    _diamondsSub?.cancel();
    _userSub?.cancel();
    _purchaseErrorsSub?.cancel();
    _benefitsAutoScrollTimer?.cancel();
    try { _tabController.removeListener(_tabListener); } catch (_) {}
    _tabController.dispose();
    _benefitPageController.dispose();
    _purchaseService.dispose();
    super.dispose();
  }

  Future<void> _buy(String productId) async {
    if (_purchasing.contains(productId)) return;
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _purchasing.add(productId));
    bool ok = false;
    try {
      ok = await _purchaseService.buy(productId);
    } catch (e, st) {
      debugPrint('Purchase error: $e\n$st');
      ok = false;
    }

    if (!mounted) {
      debugPrint('StoreScreen disposed before purchase completed.');
      return;
    }

    if (mounted) setState(() => _purchasing.remove(productId));

    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start purchase.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Başarılı işlem -> mesajı ürün tipine göre göster
    if (mounted) {
      final isPremium = productId == PurchaseService.monthlyProductId || productId == PurchaseService.yearlyProductId;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPremium ? 'Activating Premium...' : 'Adding diamonds to your account...'),
          backgroundColor: Colors.black87,
        ),
      );
    }
  }

  Future<void> _restorePurchases() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restoring purchases...'), backgroundColor: Colors.black87),
      );
    }
    try {
      await _purchaseService.restorePurchases();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checked existing purchases.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _segmentedTabs(),
        const SizedBox(height: 8),
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
                            child: _loadingProducts
                                ? const Center(child: CircularProgressIndicator())
                                : TabBarView(
                                    controller: _tabController,
                                    physics: const BouncingScrollPhysics(),
                                    children: [
                                      _isPremium ? _buildPremiumActiveView() : _buildPremiumUpsellView(),
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

  Widget _buildPremiumUpsellView({Key? key}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthlyProduct = _purchaseService.product(PurchaseService.monthlyProductId);
    final yearlyProduct = _purchaseService.product(PurchaseService.yearlyProductId);
    final selectedProductId = _selectedPlan == PremiumPlan.monthly
        ? PurchaseService.monthlyProductId
        : PurchaseService.yearlyProductId;

    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Premium Benefits başlığı kaldırıldı
          // const SizedBox(height: 20), // ek boşluk gereksiz
          // Premium faydaları için sayfa görünümü - daha büyük
          SizedBox(
            height: 220, // Yüksekliği artırdım
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
          const SizedBox(height: 16),
          // Sayfa göstergesi
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _premiumBenefits.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == _currentBenefitPage ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentBenefitPage ? Colors.amber : Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: index == _currentBenefitPage
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
            ),
          ),
          const SizedBox(height: 20),
          // Fiyat/planlar
          Row(
            children: [
              Expanded(
                child: _buildPlanCard(
                  plan: PremiumPlan.monthly,
                  title: 'Monthly',
                  price: monthlyProduct?.price ?? '...',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPlanCard(
                  plan: PremiumPlan.yearly,
                  title: 'Yearly',
                  price: yearlyProduct?.price ?? '...',
                  isBestValue: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Vurgulu tek buton
          DecoratedBox(
            decoration: BoxDecoration(
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
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.workspace_premium, color: Colors.black, size: 20),
                label: const Text(
                  'Go Premium Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () {
                  final selectedProduct = _selectedPlan == PremiumPlan.monthly
                      ? monthlyProduct
                      : yearlyProduct;
                  final selectedProductIdLocal = _selectedPlan == PremiumPlan.monthly
                      ? PurchaseService.monthlyProductId
                      : PurchaseService.yearlyProductId;
                  if (selectedProduct != null) {
                    _buy(selectedProductIdLocal);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Opacity(
            opacity: 0.75,
            child: Column(
              children: [
                Text(
                  'Subscription renews automatically and is charged to your store account. You can cancel anytime.',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 11.5,
                    height: 1.3
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Benefits activate within a few seconds after purchase.',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 10.5
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _restorePurchases,
                  child: const Text('Restore purchases'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumActiveView({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.amber,
                highlightColor: Colors.white,
                child: const Icon(Icons.workspace_premium, size: 60, color: Colors.amber),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  'Premium Active',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const SizedBox(
            height: 420, // Sabit yükseklik eski hali
            child: PremiumStatusPanel(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: _restorePurchases,
              child: const Text('Restore purchases'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required PremiumPlan plan,
    required String title,
    required String price,
    bool isBestValue = false,
  }) {
    final bool isSelected = _selectedPlan == plan;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? const LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
        ),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 132,
          borderRadius: 20,
          blur: 12,
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.white.withAlpha(40),
            width: isSelected ? 2.5 : 1,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [
                        Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 1))
                      ]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (plan == PremiumPlan.yearly)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Save ~45% monthly',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.black87 : Colors.amber,
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Best Value',
                      style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitCard(_BenefitData benefit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Daha büyük ve ortalı Lottie animasyonu
                Center(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Lottie.asset(
                      benefit.iconPath,
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                      repeat: true,
                      animate: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Başlık - ortalı
                Text(
                  benefit.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),
                // Açıklama - ortalı ve esnek
                Flexible(
                  child: Text(
                    benefit.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85),
                      height: 1.3,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: null,
                    overflow: TextOverflow.visible,
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

class _BenefitData {
  final String iconPath;
  final String title;
  final String description;

  const _BenefitData(this.iconPath, this.title, this.description);
}
