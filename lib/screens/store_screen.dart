// lib/screens/store_screen.dart
// Premium durum kontrolü hatası düzeltildi. Mantık daha sağlam hale getirildi.
// Elmas paketi görünümü, modern, simetrik ve dengeli bir tasarım için tamamen yeniden düzenlendi.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingua_chat/services/diamond_service.dart';
import 'package:lingua_chat/services/purchase_service.dart';
import 'package:lingua_chat/widgets/shared/animated_background.dart';
import 'package:lingua_chat/widgets/store_screen/glassmorphism.dart';
import 'package:lingua_chat/widgets/home_screen/premium_status_panel.dart';
import 'package:lingua_chat/widgets/store_screen/diamond_pack_grid_tile.dart';
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
  PremiumPlan _selectedPlan = PremiumPlan.yearly;

  bool _isPremium = false;

  bool _loadingProducts = true;
  bool _initTried = false;

  late final TabController _tabController;

  final Set<String> _purchasing = {};
  Map<String, String> _priceMap = {};
  Color _headerAccentStart = const Color(0x22FFD54F);
  Color _headerAccentEnd = const Color(0x2200172A);

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
    _buildPriceMap();
    setState(() => _loadingProducts = false);

    _listenUser();
    _diamondsSub = DiamondService().diamondsStream().listen((v) {
      if (mounted) setState(() => _diamonds = v);
    });
    unawaited(DiamondService().currentDiamonds(refresh: true));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _diamonds == null) {
        setState(() => _diamonds = 0);
      }
    });
  }

  void _buildPriceMap() {
    final map = <String, String>{};
    for (final id in PurchaseService.diamondProductIds) {
      final p = _purchaseService.product(id);
      if (p != null) map[id] = p.price;
    }
    _priceMap = map;
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
    _tabController.removeListener(() {});
    _tabController.dispose();
    _purchaseService.dispose();
    super.dispose();
  }

  Future<void> _buy(String productId) async {
    if (_purchasing.contains(productId)) return;
    HapticFeedback.lightImpact();
    setState(() => _purchasing.add(productId));
    bool ok = false;
    try {
      ok = await _purchaseService.buy(productId);
    } catch (e) {
      debugPrint('Purchase error: $e');
      ok = false;
    }
    if (!mounted) return;
    setState(() => _purchasing.remove(productId));

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satın alma başlatılamadı.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Başarılıysa optimistik local artış (Firestore gecikmesine karşı)
    if (PurchaseService.diamondProductIds.contains(productId)) {
      final add = PurchaseService.diamondAmountFor(productId) ?? 0;
      setState(() => _diamonds = (_diamonds ?? 0) + add);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Satın alma işlendiğinde bakiyeniz güncellenecek.'), backgroundColor: Colors.black87),
    );
  }

  Future<void> _restorePurchases() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Satın alımlar geri yükleniyor...'), backgroundColor: Colors.black87),
    );
    try {
      await _purchaseService.restorePurchases();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mevcut satın alımlar kontrol edildi.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Widget _storeSectionHeader({
    required String title,
    required String subtitle,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Colors.amber.withOpacity(0.35),
              Colors.deepOrange.withOpacity(0.25),
              Colors.purple.withOpacity(0.20),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            if (icon != null)
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(rect),
                child: Icon(icon, size: 42, color: Colors.white),
              ),
            if (icon != null) const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.82),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final diamondsText = (_diamonds == null) ? '...' : _diamonds.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Shimmer.fromColors(
                baseColor: Colors.white,
                highlightColor: Colors.amber.shade300,
                child: const Text(
                  'Store',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            _diamondBalanceChip(diamondsText),
          ],
        ),
        const SizedBox(height: 18),
        _segmentedTabs(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _diamondBalanceChip(String value) {
    return InkWell(
      onTap: () => _tabController.animateTo(0),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.black.withOpacity(0.28),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedDiamondIcon(value: _diamonds),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 42),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _DiamondCountAnimated(value: _diamonds),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.add, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _segmentedTabs() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.04),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (i){
          setState(() {
            // header accent renkleri sekmeye göre değişsin
            if (i == 0) {
              _headerAccentStart = const Color(0x22FFD54F);
              _headerAccentEnd = const Color(0x22101724);
            } else {
              _headerAccentStart = const Color(0x22458AFF);
              _headerAccentEnd = const Color(0x22121C40);
            }
          });
        },
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.zero,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: _tabController.index == 0
                ? const [Color(0xFFFFD54F), Color(0xFFFF8F00)]
                : const [Color(0xFF66CCFF), Color(0xFF3366FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (_tabController.index == 0 ? Colors.amber : Colors.blueAccent).withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'Elmas', icon: Icon(Icons.diamond, size: 18)),
          Tab(text: 'Premium', icon: Icon(Icons.workspace_premium, size: 18)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                  gradient: const LinearGradient(
                    colors: [Color(0x66121C27), Color(0x66101724)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.55),
                      blurRadius: 42,
                      spreadRadius: -4,
                      offset: const Offset(0, 28),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                ),
                child: Container(
                  margin: const EdgeInsets.all(2.2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(38),
                    gradient: LinearGradient(
                      colors: [
                        _headerAccentStart,
                        _headerAccentEnd,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(38),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
                          child: _header(),
                        ),
                        Expanded(
                          child: _loadingProducts
                              ? const Center(child: CircularProgressIndicator())
                              : IndexedStack(
                                  index: _tabController.index,
                                  children: [
                                    // Elmas Grid
                                    _diamondsGrid(),
                                    // Premium içerik
                                    _isPremium
                                        ? _buildPremiumActiveView()
                                        : _buildPremiumUpsellView(),
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
        ],
      ),
    );
  }

  Widget _diamondsGrid() {
    final ids = PurchaseService.diamondProductIds;
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 3;
        if (constraints.maxWidth < 380) crossAxisCount = 2;
        final itemWidth = (constraints.maxWidth - (16 * (crossAxisCount - 1))) / crossAxisCount;
        final itemHeight = 168.0;
        final aspectRatio = itemWidth / itemHeight;
        return GridView.builder(
          key: const PageStorageKey('diamonds_grid'),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          physics: const ClampingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          itemCount: ids.length,
          itemBuilder: (context, index) {
            final id = ids[index];
            final amount = PurchaseService.diamondAmountFor(id) ?? 0;
            final price = _priceMap[id] ?? '...';
            String? badge; Color? badgeColor;
            if (id == 'diamonds_large') { badge = 'EN İYİ DEĞER'; badgeColor = Colors.greenAccent; }
            else if (id == 'diamonds_medium') { badge = 'POPÜLER'; badgeColor = Colors.amber; }
            else if (id == 'diamonds_mega') { badge = 'DEV PAKET'; badgeColor = Colors.deepPurpleAccent; }
            return DiamondPackGridTile(
              productId: id,
              title: '$amount Elmas',
              price: price,
              badge: badge,
              badgeColor: badgeColor,
              loading: _purchasing.contains(id),
              onTap: _priceMap[id] == null ? null : () => _buy(id),
            );
          },
        );
      },
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
          _storeSectionHeader(
            title: 'Premium ile Kilidi Aç',
            subtitle: 'Tüm sınırsız özellikler, reklamsız deneyim ve ayrıcalıklı hız.',
            icon: Icons.workspace_premium,
          ),
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
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: (monthlyProduct == null || yearlyProduct == null)
                      ? null
                      : () => _buy(selectedProductId),
                  child: const Text('Şimdi Premium Ol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.35), width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _restorePurchases,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Geri Yükle', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              )
            ],
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
          const SizedBox(height: 12),
          Opacity(
            opacity: 0.75,
            child: Column(
              children: const [
                Text(
                  'Abonelik yenilemesi otomatik olarak mağaza hesabından tahsil edilir. İstediğin zaman iptal edebilirsin.',
                  style: TextStyle(color: Colors.white54, fontSize: 11.5, height: 1.3),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6),
                Text(
                  'Satın alma işleminden sonra avantajlar birkaç saniye içinde etkinleşir.',
                  style: TextStyle(color: Colors.white38, fontSize: 10.5),
                  textAlign: TextAlign.center,
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
                        Shadow(color: Colors.black.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 1))
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
                          'Aylık ~%45 tasarruf',
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
                      'En Avantajlı',
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
          colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : LinearGradient(colors: [
          Colors.white.withOpacity(0.12),
          Colors.white.withOpacity(0.05),
        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: Colors.white.withAlpha(50), width: 1),
        boxShadow: gradient
            ? [
          BoxShadow(
            color: Colors.amber.withOpacity(0.55),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          )
        ]
            : null,
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.55),
    );
  }
}

// ================= Animasyonlu Elmas Sayaç Bileşenleri =================
class _DiamondCountAnimated extends StatefulWidget {
  final int? value;
  const _DiamondCountAnimated({required this.value});

  @override
  State<_DiamondCountAnimated> createState() => _DiamondCountAnimatedState();
}

class _DiamondCountAnimatedState extends State<_DiamondCountAnimated> with SingleTickerProviderStateMixin {
  late int _displayFrom;
  late int _displayTo;
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _displayFrom = widget.value ?? 0;
    _displayTo = widget.value ?? 0;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  }

  @override
  void didUpdateWidget(covariant _DiamondCountAnimated oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newVal = widget.value;
    if (newVal == null) return;
    final oldVal = oldWidget.value ?? 0;
    if (newVal != oldVal) {
      _displayFrom = oldVal;
      _displayTo = newVal;
      if (newVal > oldVal) {
        _ctrl.forward(from: 0);
      } else {
        // Azalma: direkt göster (animasyonsuz)
        _ctrl.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value == null) {
      return const Text('...', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 17));
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_ctrl.value);
        final current = (_displayFrom + ( (_displayTo - _displayFrom) * t )).round();
        final Color color = Color.lerp(Colors.amberAccent, Colors.white, t) ?? Colors.white;
        return Text(
          current.toString(),
          softWrap: false,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17 + (1.5 * (1 - t)),
            letterSpacing: 0.6,
            color: color,
            shadows: [
              Shadow(
                color: Colors.amber.withOpacity((1 - t) * 0.6),
                blurRadius: 6 * (1 - t) + 2,
              )
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedDiamondIcon extends StatefulWidget {
  final int? value;
  const _AnimatedDiamondIcon({required this.value});
  @override
  State<_AnimatedDiamondIcon> createState() => _AnimatedDiamondIconState();
}

class _AnimatedDiamondIconState extends State<_AnimatedDiamondIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int? _old;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _old = widget.value;
  }

  @override
  void didUpdateWidget(covariant _AnimatedDiamondIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null && oldWidget.value != null) {
      if ((widget.value ?? 0) > (oldWidget.value ?? 0)) {
        _ctrl.forward(from: 0);
      }
    }
    _old = widget.value;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeOutBack.transform(_ctrl.value);
        final scale = 1 + 0.35 * (1 - t);
        final glowOpacity = (1 - t) * 0.8;
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: glowOpacity,
              child: Container(
                width: 28 + 18 * (1 - t),
                height: 28 + 18 * (1 - t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(glowOpacity),
                      blurRadius: 22 * (1 - t) + 4,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
            ),
            Transform.scale(
              scale: scale,
              child: const Icon(Icons.diamond, color: Colors.amber, size: 20),
            ),
          ],
        );
      },
    );
  }
}
