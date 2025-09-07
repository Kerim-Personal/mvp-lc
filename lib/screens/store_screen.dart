// lib/screens/store_screen.dart
// Premium durum kontrolü hatası düzeltildi. Mantık daha sağlam hale getirildi.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lingua_chat/services/diamond_service.dart';
import 'package:lingua_chat/services/purchase_service.dart';
import 'package:lingua_chat/widgets/shared/animated_background.dart';
import 'package:lingua_chat/widgets/store_screen/glassmorphism.dart';
import 'package:lingua_chat/widgets/home_screen/premium_status_panel.dart';
import 'package:shimmer/shimmer.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

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

  int? _diamonds;
  // premiumUntil kaldırıldı; sadece isPremium kullanılacak
  PremiumPlan _selectedPlan = PremiumPlan.yearly;

  bool _isPremium = false;

  bool _loadingProducts = true;
  bool _initTried = false;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _init();
  }

  Future<void> _init() async {
    if (_initTried) return;
    _initTried = true;
    await _purchaseService.init();

    if (!mounted) return;
    setState(() => _loadingProducts = false);

    _listenUser();
    _diamondsSub = DiamondService().diamondsStream().listen((v) {
      if (mounted) setState(() => _diamonds = v);
    });
    // İlk değeri hemen çek ve yayınla
    unawaited(DiamondService().currentDiamonds(refresh: true));
    // 2 sn sonra hala null ise 0 yap (sonsuz spinner engeli)
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

  // Artık bu getter'a ihtiyacımız yok, _isPremium değişkenini kullanacağız.
  // bool get _isPremiumActive { ... }

  @override
  void dispose() {
    _diamondsSub?.cancel();
    _userSub?.cancel();
    _tabController.removeListener(() {});
    _tabController.dispose();
    _purchaseService.dispose();
    super.dispose();
  }

  Future<void> _buy(String productId) async {
    final ok = await _purchaseService.buy(productId);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Satın alma başlatılamadı.'),
            backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
            Text('Satın alma işlendiğinde bakiyeniz güncellenecek.'),
            backgroundColor: Colors.black87),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Shimmer.fromColors(
          baseColor: Colors.white,
          highlightColor: Colors.amber.shade300,
          child: const Text(
            'Store',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 1.2,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black.withOpacity(0.3),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                _tabController.animateTo(0);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.diamond, color: Colors.amber, size: 20),
                    const SizedBox(width: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: _diamonds == null
                          ? const SizedBox(
                        key: ValueKey('loader'),
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        key: const ValueKey('diamonds_count'),
                        _diamonds.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.add, color: Colors.white70, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.diamond, size: 20), text: 'Elmas'),
            Tab(icon: Icon(Icons.workspace_premium, size: 20), text: 'Premium'),
          ],
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: GlassmorphicContainer(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.85,
                borderRadius: 28,
                blur: 18,
                border: Border.all(color: Colors.white.withAlpha(70), width: 1.5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _loadingProducts
                        ? const Center(key: ValueKey('loader'), child: CircularProgressIndicator())
                        : _tabController.index == 0
                        ? _buildDiamondsTab(key: const ValueKey('diamonds'))
                        : _isPremium // DÜZELTME: Getter yerine state değişkenini kullan
                        ? _buildPremiumActiveView(key: const ValueKey('premium_active'))
                        : _buildPremiumUpsellView(key: const ValueKey('premium_upsell')),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiamondsTab({Key? key}) {
    final packs = PurchaseService.diamondProductIds;
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: packs.map((id) => _diamondPack(id)).toList(),
        ),
      ),
    );
  }

  Widget _diamondPack(String id) {
    final amount = PurchaseService.diamondAmountFor(id) ?? 0;
    final product = _purchaseService.product(id);
    final price = product?.price ?? '?';

    return GlassmorphicContainer(
      width: 160,
      height: 150,
      borderRadius: 22,
      blur: 12,
      border: Border.all(color: Colors.white.withAlpha(40), width: 1),
      child: InkWell(
        onTap: product == null ? null : () => _buy(id),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleIcon(Icons.diamond, gradient: true),
              const SizedBox(height: 12),
              Text('$amount Elmas',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
              const SizedBox(height: 4),
              Text(price,
                  style: const TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumUpsellView({Key? key}) {
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
          const Text(
            'Tüm Ayrıcalıkları Aç',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildPlanCard(
                  plan: PremiumPlan.monthly,
                  title: 'Aylık',
                  price: monthlyProduct?.price ?? '...',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPlanCard(
                  plan: PremiumPlan.yearly,
                  title: 'Yıllık',
                  price: yearlyProduct?.price ?? '...',
                  isBestValue: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: (monthlyProduct == null || yearlyProduct == null)
                ? null
                : () => _buy(selectedProductId),
            child: const Text('Şimdi Premium Ol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Premium Avantajları',
            style: TextStyle(
                color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _benefit(icon: Icons.flash_on, title: 'Hızlı Eşleşme', text: 'Öncelikli partner eşleşme kuyruğunda yer al.'),
          _benefit(icon: Icons.auto_awesome, title: 'Gelişmiş Analiz', text: 'Konuşma & yazma yeteneklerin için ileri seviye analizler al.'),
          _benefit(icon: Icons.lock_open, title: 'Tüm İçerik', text: 'Bütün özel hikaye ve quiz setlerine sınırsız erişim kazan.'),
          _benefit(icon: Icons.workspace_premium, title: 'Rozet ve Efektler', text: 'Profilinde havalı premium rozeti ve animasyonlu arka plan sergile.'),
          _benefit(icon: Icons.translate, title: 'Sınırsız Çeviri', text: 'Pratik yaparken kelimeleri sınırsızca çevir.'),
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
              const Flexible(
                child: Text(
                  'Premium Aktif',
                  style: TextStyle(
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
          // FIX: Column + SingleChildScrollView içinde PremiumStatusPanel
          // sınırsız (unbounded) yükseklik alıyordu ve Stack + Positioned.fill
          // kombinasyonu layout exception oluşturup görünmemesine yol açıyordu.
          // Bunu önlemek için makul bir sabit yükseklik veriyoruz.
          SizedBox(
            height: 360,
            child: const PremiumStatusPanel(),
          ),
          const SizedBox(height: 12),
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
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 120,
        borderRadius: 20,
        blur: 10,
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
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    price,
                    style: TextStyle(
                      color: isSelected ? Colors.amber : Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
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
                    'En Avantajlı',
                    style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _benefit({required IconData icon, required String title, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _circleIcon(icon, gradient: false, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(text,
                    style: const TextStyle(color: Colors.white70, height: 1.3, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, {bool gradient = false, double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient
            ? const LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)])
            : LinearGradient(colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05)
        ]),
        border: Border.all(color: Colors.white.withAlpha(40), width: 1),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.55),
    );
  }
}
