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
  late final VoidCallback _tabListener; // Eklenen: listener referansı

  final Set<String> _purchasing = {};
  Map<String, String> _priceMap = {};
  // Dinamik accent renkleri kaldırıldı
  // Color _headerAccentStart = const Color(0x22FFD54F);
  // Color _headerAccentEnd = const Color(0x2200172A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabListener = () => setState(() {}); // Listener referansını sakla
    _tabController.addListener(_tabListener); // Anonim yerine referans ekle
    _init();
  }

  Future<void> _init() async {
    if (_initTried) return;
    _initTried = true;
    await _purchaseService.init();
    if (!mounted) return;
    _buildPriceMap();
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

  void _buildPriceMap() {
    final map = <String, String>{};
    for (final id in PurchaseService.diamondProductIds) {
      final p = _purchaseService.product(id);
      if (p != null && p.price != null) map[id] = p.price;
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
    try {
      _tabController.removeListener(_tabListener); // Doğru şekilde kaldır
    } catch (_) {}
    _tabController.dispose();
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
      // Eğer widget artık mount değilse, satın alma işlemi tamamlanmış olsa da
      // UI üzerinde değişiklik yapma. Burada yine de log tut.
      debugPrint('StoreScreen disposed before purchase completed.');
      return;
    }

    // satın alma bitince UI'daki loading durumunu kaldır
    if (mounted) setState(() => _purchasing.remove(productId));

    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Satın alma başlatılamadı.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Başarılı işlem -> DiamondService güncellemesi artık servis tarafından yapılmalı.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elmaslar hesabına ekleniyor...'), backgroundColor: Colors.black87),
      );
    }
  }

  Future<void> _restorePurchases() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satın alımlar geri yükleniyor...'), backgroundColor: Colors.black87),
      );
    }
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
          // Daha sade tek ton cam efekti
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.06),
              Colors.white.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            if (icon != null)
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Icon(icon, size: 26, color: Colors.black87),
              ),
            if (icon != null) const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.70),
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
    final diamondsText = _formatDiamonds(_diamonds);
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
            Flexible(child: _diamondBalanceChip(diamondsText)),
          ],
        ),
        const SizedBox(height: 18),
        _segmentedTabs(),
        const SizedBox(height: 8),
      ],
    );
  }

  String _formatDiamonds(int? v) {
    if (v == null) return '...';
    if (v < 1000) return v.toString();
    if (v < 1000000) {
      final k = v / 1000;
      return k.toStringAsFixed(k >= 100 ? 0 : 1) + 'K';
    }
    if (v < 1000000000) {
      final m = v / 1000000;
      return m.toStringAsFixed(m >= 100 ? 0 : 1) + 'M';
    }
    final b = v / 1000000000;
    return b.toStringAsFixed(b >= 100 ? 0 : 1) + 'B';
  }

  Widget _diamondBalanceChip(String value) {
    return InkWell(
      onTap: () => _tabController.animateTo(0),
      borderRadius: BorderRadius.circular(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 170),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.black.withOpacity(0.28),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
          ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.diamond, color: Colors.amber, size: 20),
                const SizedBox(width: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.6,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.add, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _segmentedTabs() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
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
              color: Colors.amber.withOpacity(0.45),
              blurRadius: 14,
              offset: const Offset(0, 5),
            )
          ],
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
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
                    colors: [Color(0x99121C27), Color(0x98101724)],
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
                  border: Border.all(color: Colors.white.withOpacity(0.04), width: 1),
                ),
                child: Container(
                  margin: const EdgeInsets.all(2.2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(38),
                    // İç panel sabit koyu cam
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.04),
                        Colors.white.withOpacity(0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
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
                              : TabBarView(
                                  controller: _tabController,
                                  physics: const BouncingScrollPhysics(),
                                  children: [
                                    _diamondsGrid(),
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

  Widget _diamondsGrid({bool shrinkWrap = false, bool outerScroll = false}) {
    final ids = PurchaseService.diamondProductIds;
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 3;
        if (constraints.maxWidth < 380) crossAxisCount = 2;
        final usableWidth = constraints.maxWidth.clamp(0.0, double.infinity);
        final itemWidth = (usableWidth - (16 * (crossAxisCount - 1))).clamp(1.0, double.infinity) / crossAxisCount;
        final itemHeight = 168.0;
        final aspectRatio = (itemWidth.isFinite && itemHeight > 0) ? (itemWidth / itemHeight) : 1.0;
        return GridView.builder(
          key: const PageStorageKey('diamonds_grid'),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            physics: const BouncingScrollPhysics(parent: ClampingScrollPhysics()),
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
            String? badge;
            Color? badgeColor;
            if (id == 'diamonds_large') {
              badge = 'EN İYİ DEĞER';
              badgeColor = Colors.greenAccent;
            } else if (id == 'diamonds_medium') {
              badge = 'POPÜLER';
              badgeColor = Colors.amber;
            } else if (id == 'diamonds_mega') {
              badge = 'DEV PAKET';
              badgeColor = Colors.deepPurpleAccent;
            }
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
              Flexible(
                child: Text(
                  'Premium Aktif',
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
            height: 360,
            child: PremiumStatusPanel(),
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

