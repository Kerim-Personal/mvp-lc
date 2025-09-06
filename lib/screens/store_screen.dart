// lib/screens/store_screen.dart
// Mağaza ekranı (Premium + Elmas). Baştan yazıldı.
// Not: Gerçek cihazda test için Play Store / App Store yapılandırması gerekir.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lingua_chat/services/diamond_service.dart';
import 'package:lingua_chat/services/purchase_service.dart';
import 'package:lingua_chat/widgets/store_screen/glassmorphism.dart';
import 'package:lingua_chat/widgets/store_screen/premium_animated_background.dart';

class StoreScreen extends StatefulWidget {
  final bool embedded; // RootScreen sekme içinde kullanırken işaretlemek için (şimdilik davranış değiştirmiyor)
  const StoreScreen({super.key, this.embedded = false});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with TickerProviderStateMixin {
  final PurchaseService _purchaseService = PurchaseService();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  StreamSubscription<int?>? _diamondsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  int? _diamonds;
  DateTime? _premiumUntil;

  bool _loadingProducts = true;
  bool _initTried = false;

  late final TabController _tabController;
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _init();
  }

  Future<void> _init() async {
    if (_initTried) return; // idempotent
    _initTried = true;
    await _purchaseService.init();

    if (!mounted) return;
    setState(() => _loadingProducts = false);

    _listenUser();
    _diamondsSub = DiamondService().diamondsStream().listen((v) {
      if (mounted) setState(() => _diamonds = v);
    });
    _fadeController.forward();
  }

  void _listenUser() {
    final user = _auth.currentUser;
    if (user == null) return;
    _userSub = _firestore.collection('users').doc(user.uid).snapshots().listen((snap) {
      final data = snap.data();
      DateTime? until;
      if (data != null && data['premiumUntil'] is String) {
        until = DateTime.tryParse(data['premiumUntil'] as String);
      }
      if (mounted) setState(() => _premiumUntil = until);
    });
  }

  bool get _isPremiumActive {
    if (_premiumUntil == null) return false;
    return _premiumUntil!.isAfter(DateTime.now().toUtc());
  }

  @override
  void dispose() {
    _diamondsSub?.cancel();
    _userSub?.cancel();
    _tabController.dispose();
    _fadeController.dispose();
    _purchaseService.dispose();
    super.dispose();
  }

  Future<void> _buy(String productId) async {
    final ok = await _purchaseService.buy(productId);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satın alma başlatılamadı.'), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satın alma işlendiğinde bakiyeniz güncellenecek.'), backgroundColor: Colors.black87),
      );
    }
  }

  Future<void> _restore() async {
    await _purchaseService.restorePurchases();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Geri yükleme isteği gönderildi.'), backgroundColor: Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Mağaza'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Satın Alma Geri Yükle',
            icon: const Icon(Icons.restore),
            onPressed: _purchaseService.isAvailable ? _restore : null,
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
      body: FadeTransition(
        opacity: _fadeController.drive(CurveTween(curve: Curves.easeIn)),
        child: Stack(
          children: [
            Positioned.fill(child: _isPremiumActive ? const PremiumAnimatedBackground() : Container(color: const Color(0xFF0F0F17))),
            TabBarView(
              controller: _tabController,
              children: [
                _buildDiamondsTab(theme),
                _buildPremiumTab(theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiamondsTab(ThemeData theme) {
    if (_loadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    final packs = PurchaseService.diamondProductIds;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _balanceCard(),
          const SizedBox(height: 16),
          Text('Elmas Paketleri', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: packs.map((id) => _diamondPack(id)).toList(),
          ),
          const SizedBox(height: 32),
          _infoBox(
            icon: Icons.info_outline,
            title: 'Nasıl Kullanılır?',
            text: 'Elmasları ek özellikler ve içerik açmak için kullanabilirsiniz. Satın almalar otomatik tüketilir.',
          ),
        ],
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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _circleIcon(Icons.diamond, gradient: true),
              const Spacer(),
              Text('$amount Elmas', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 4),
              Text(price, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTab(ThemeData theme) {
    if (_loadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }
    final active = _isPremiumActive;
    final until = _premiumUntil;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _premiumStatusCard(active: active, until: until),
          const SizedBox(height: 20),
          Text('Plan Seç', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _subPlan(
                  id: PurchaseService.monthlyProductId,
                  title: 'Aylık',
                  highlight: !active,
                  desc: '1 ay premium erişim.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _subPlan(
                  id: PurchaseService.yearlyProductId,
                  title: 'Yıllık',
                  highlight: true,
                  desc: '12 ay (en avantajlı).',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Premium Avantajları', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _benefit(icon: Icons.flash_on, title: 'Hızlı Eşleşme', text: 'Öncelikli partner eşleşme kuyruğu.'),
          _benefit(icon: Icons.auto_awesome, title: 'Gelişmiş Analiz', text: 'Konuşma & yazma için ileri seviye analiz.'),
          _benefit(icon: Icons.lock_open, title: 'Tüm İçerik', text: 'Özel hikaye ve quiz setleri.'),
          _benefit(icon: Icons.workspace_premium, title: 'Rozet ve Efektler', text: 'Profilde premium rozeti ve animasyonlu arka plan.'),
          const SizedBox(height: 36),
          _infoBox(
            icon: Icons.security,
            title: 'Güvenli Ödeme',
            text: 'Ödemeler mağaza (Play / App Store) altyapısı ile güvenle işlenir. Kart bilgileri uygulamaya ulaşmaz.',
          ),
          const SizedBox(height: 16),
          _infoBox(
            icon: Icons.refresh,
            title: 'Abonelik Yenileme',
            text: 'Abonelik dönem sonunda otomatik yenilenebilir. Dilediğiniz zaman iptal edebilirsiniz.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _premiumStatusCard({required bool active, required DateTime? until}) {
    final remaining = active && until != null ? until.difference(DateTime.now().toUtc()) : null;
    String subtitle;
    if (active && remaining != null) {
      final days = remaining.inDays;
      subtitle = days > 0 ? '$days gün kaldı' : 'Son gün';
    } else {
      subtitle = 'Tüm premium özellikleri aç';
    }

    return GlassmorphicContainer(
      width: double.infinity,
      height: 150,
      borderRadius: 26,
      blur: 15,
      border: Border.all(color: Colors.white.withAlpha(50), width: 1.2),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _circleIcon(Icons.workspace_premium, gradient: true, size: 56),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    active ? 'Premium Aktif' : 'Premium Pasif',
                    style: TextStyle(
                      color: active ? Colors.amber : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (active && until != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Bitiş: ${until.toLocal().toString().substring(0, 16)}',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subPlan({
    required String id,
    required String title,
    required bool highlight,
    required String desc,
  }) {
    final product = _purchaseService.product(id);
    final price = product?.price ?? '?';
    final isYearly = id == PurchaseService.yearlyProductId;
    final savings = isYearly ? 'Tasarruf ~%35' : '';

    return GlassmorphicContainer(
      width: double.infinity,
      height: 190,
      borderRadius: 24,
      blur: 14,
      border: Border.all(color: highlight ? Colors.amber.withAlpha(120) : Colors.white.withAlpha(40), width: 1.4),
      child: InkWell(
        onTap: product == null ? null : () => _buy(id),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _circleIcon(isYearly ? Icons.calendar_month : Icons.calendar_view_month, gradient: highlight),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: highlight
                            ? [const Shadow(color: Colors.amber, blurRadius: 12, offset: Offset(0, 0))]
                            : null,
                      ),
                    ),
                  ),
                  if (savings.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(70),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        savings,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(desc, style: const TextStyle(color: Colors.white70, height: 1.2)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(price, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: highlight ? Colors.amber : Colors.white12,
                      foregroundColor: highlight ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    onPressed: product == null ? null : () => _buy(id),
                    child: const Text('Satın Al'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _balanceCard() {
    final d = _diamonds;
    return GlassmorphicContainer(
      width: double.infinity,
      height: 120,
      borderRadius: 26,
      blur: 14,
      border: Border.all(color: Colors.white.withAlpha(50), width: 1.2),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _circleIcon(Icons.savings, gradient: true, size: 56),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Elmas Bakiyesi', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    d == null ? '...' : d.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                // Manuel yenileme
                final val = await DiamondService().currentDiamonds(refresh: true);
                if (mounted) setState(() => _diamonds = val);
              },
              icon: const Icon(Icons.refresh, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefit({required IconData icon, required String title, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _circleIcon(icon, gradient: false, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: Colors.white70, height: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox({required IconData icon, required String title, required String text}) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: null,
      borderRadius: 24,
      blur: 10,
      border: Border.all(color: Colors.white.withAlpha(30), width: 1),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _circleIcon(icon, gradient: true, size: 46),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(text, style: const TextStyle(color: Colors.white70, height: 1.25)),
                ],
              ),
            ),
          ],
        ),
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
            ? const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)])
            : const LinearGradient(colors: [Color(0x33212121), Color(0x66121212)]),
        border: Border.all(color: Colors.white.withAlpha(40), width: 1),
        boxShadow: gradient
            ? [
                BoxShadow(color: Colors.amber.withAlpha(120), blurRadius: 20, spreadRadius: 1),
              ]
            : null,
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.55),
    );
  }
}

