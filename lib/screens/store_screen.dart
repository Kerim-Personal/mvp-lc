// lib/screens/store_screen.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/widgets/shared/animated_background.dart';
import 'package:lingua_chat/services/purchase_service.dart';
import 'package:lingua_chat/services/stone_service.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key, this.embedded = false, this.replayTrigger = 0});
  final bool embedded;
  final int replayTrigger; // sekme yeniden seçildiğinde artar

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with TickerProviderStateMixin {
  // Abonelik değişkenleri kaldırıldı, yeni yapı: tab + taş sistemi
  late TabController _tabController;
  final PurchaseService _purchaseService = PurchaseService();
  StreamSubscription<PurchaseStateUpdate>? _purchaseSub;
  bool _productsLoaded = false;
  String? _purchaseError;
  String? _pendingProductId;
  int _currentStones = 0;
  StreamSubscription<int?>? _stonesSub;

  // Premium özellikleri ve taş maliyetleri
  static const List<Map<String, dynamic>> _premiumFeatures = [
    {'id': 'instant_translation', 'title': 'Instant Translation', 'desc': 'Translate a message instantly', 'cost': 3},
    {'id': 'partner_filter_gender', 'title': 'Partner Gender Filter', 'desc': 'Filter partners by gender', 'cost': 5},
    {'id': 'partner_filter_level', 'title': 'Partner Level Filter', 'desc': 'Filter partners by level', 'cost': 5},
    {'id': 'ad_free_session', 'title': 'Ad‑Free Session', 'desc': 'Ad-free experience for 30 minutes', 'cost': 8},
    {'id': 'linguabot_pro', 'title': 'LinguaBot Pro Question', 'desc': 'Ask one advanced bot question', 'cost': 2},
    {'id': 'grammar_analysis', 'title': 'Advanced Grammar Analysis', 'desc': 'Detailed analysis for one text', 'cost': 4},
    {'id': 'custom_theme', 'title': 'Custom Theme Save', 'desc': 'Save a personalized theme', 'cost': 6},
  ];

  late AnimationController _animationController; // eklendi
  late Animation<double> _fadeAnimation; // eklendi

  bool _demoActive = false; // demo modu
  static const Map<String, Map<String, String>> _demoStoneMeta = {
    PurchaseService.stonePackSmallId: {
      'price': '₺19,99',
      'desc': 'Demo küçük paket'
    },
    PurchaseService.stonePackMediumId: {
      'price': '₺44,99',
      'desc': 'Demo orta paket'
    },
    PurchaseService.stonePackLargeId: {
      'price': '₺89,99',
      'desc': 'Demo büyük paket'
    },
  };

  // Fallback (görüntü) fiyatlar – mağaza fiyatı yüklenmezse kullanılır
  static const Map<String, String> _fallbackSubPrices = {
    PurchaseService.monthlyProductId: '₺89.99',
    PurchaseService.yearlyProductId: '₺899.99',
    PurchaseService.lifetimeProductId: '₺2,499.00',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3. sekme eklendi
    _setupAnimations();
    _initIap();
    _listenStones();
  }

  void _setupAnimations() {
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic);
    _animationController.forward();
  }

  void _listenStones() {
    _stonesSub = StoneService().stonesStream().listen((val) {
      if (!mounted) return;
      setState(() => _currentStones = val ?? 0);
    });
  }

  Future<void> _initIap() async {
    try {
      // Önce dinle ki init/load sırasında gelen productsLoaded event kaçmasın
      _purchaseSub ??= _purchaseService.stateStream.listen((event) {
        if (!mounted) return;
        setState(() {
          if (event.productsLoaded) _productsLoaded = true;
          if (event.error != null) {
            _purchaseError = event.error;
            _pendingProductId = null;
            if (!_productsLoaded) _productsLoaded = true;
            // Ürünler alınamadıysa demo'ya geç
            if (_purchaseService.products.isEmpty) {
              _activateDemo();
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(event.error!, style: const TextStyle(fontWeight: FontWeight.w600)), backgroundColor: Colors.redAccent),
            );
          }
          if (event.successProductId != null) {
            _pendingProductId = null;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Satın alma başarılı: ${event.successProductId}')),
            );
          }
        });
      });

      await _purchaseService.init();
      await _purchaseService.loadProducts();

      if (mounted && !_productsLoaded) {
        setState(() => _productsLoaded = true);
      }
      // Ürün listesi boşsa demo modu
      if (_purchaseService.products.isEmpty) {
        _activateDemo();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _purchaseError = 'IAP init failed: $e';
        _productsLoaded = true;
        _activateDemo();
      });
    }
  }

  void _activateDemo() {
    if (_demoActive) return;
    setState(() {
      _demoActive = true;
      _productsLoaded = true;
      _purchaseError = null; // demo'da hata göstermeyelim
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _purchaseSub?.cancel();
    _stonesSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  bool _isPending(String productId) => _pendingProductId == productId;

  void _buyStonePack(String productId) {
    if (_demoActive) {
      final amount = PurchaseService.stoneAmountFor(productId) ?? 0;
      StoneService().add(amount);
      setState(() => _pendingProductId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added +$amount stones')),
      );
      return;
    }
    setState(() {
      _pendingProductId = productId;
      _purchaseError = null;
    });
    _purchaseService.startPurchase(productId);
  }

  Future<void> _useFeature(Map<String, dynamic> feature) async {
    final cost = feature['cost'] as int;
    final ok = await StoneService().spend(cost);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Used: ${feature['title']} (-$cost)')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough stones'), backgroundColor: Colors.redAccent));
    }
  }

  // Palette & style helpers
  Color get _primaryGradA => const Color(0xFF7B2FF7);
  Color get _primaryGradB => const Color(0xFF9F62FF);
  Color get _warn => const Color(0xFFF6A545);
  Color get _ok => const Color(0xFF3BB273);
  TextStyle get _smallMuted => Theme.of(context).textTheme.bodySmall!.copyWith(
        fontSize: 11,
        letterSpacing: .2,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55),
      );

  // Arayüz
  @override
  Widget build(BuildContext context) {
    final bool isPushedAsSeparatePage = Navigator.of(context).canPop();

    final body = Column(
      children: [
        const SizedBox(height: 4),
        _buildHeader(),
        Container(
          margin: const EdgeInsets.fromLTRB(18, 4, 18, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF342646)
                : const Color(0xFFEDE3F8),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: [_primaryGradA, _primaryGradB]),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            labelColor: Colors.white,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: .60),
            tabs: const [
              Tab(icon: Icon(Icons.local_mall_outlined, size: 20), text: 'Stone Shop'),
              Tab(icon: Icon(Icons.auto_awesome, size: 20), text: 'Premium Features'),
              Tab(icon: Icon(Icons.workspace_premium_outlined, size: 20), text: 'Subscription'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildStoneStore(),
              _buildFeatureUsage(),
              _buildSubscriptionTab(),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded && !isPushedAsSeparatePage) {
      return Scaffold(backgroundColor: Colors.transparent, body: SafeArea(child: body));
    }

    if (isPushedAsSeparatePage) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(children: [const AnimatedBackground(), SafeArea(child: body)]),
      );
    }

    return Scaffold(backgroundColor: Colors.transparent, body: Stack(children: [const AnimatedBackground(), SafeArea(child: body)]));
  }

  Widget _buildHeader() {
    final onTop = Colors.white;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => LinearGradient(
                  colors: [_primaryGradA, _primaryGradB],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                child: Text(
                  'Lingua Market',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: onTop,
                    letterSpacing: .8,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: .30),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                ),
              ),
            ),
            _stoneChip(),
          ],
        ),
      ),
    );
  }

  Widget _stoneChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: LinearGradient(colors: [_primaryGradA, _primaryGradB]),
        boxShadow: [
          BoxShadow(
            color: _primaryGradA.withValues(alpha: .40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            _currentStones.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: .5,
            ),
          ),
        ],
      ),
    );
  }

  // Polished stone shop
  Widget _buildStoneStore() {
    final stoneIds = PurchaseService.stoneProductIds;
    final showEmptyMsg = _productsLoaded && _purchaseService.products.isEmpty && _purchaseError == null && !_demoActive;
    return _SectionCard(
      title: 'Stone Packs',
      trailing: null,
      description: 'Purchase stones to spend on premium on‑demand features.',
      child: !_productsLoaded
          ? const Center(child: CircularProgressIndicator())
          : showEmptyMsg
              ? _EmptyMessage(
                  icon: Icons.store_mall_directory_outlined,
                  text: 'No products loaded. Publish items in the console to view them here.',
                )
              : ListView.separated(
                  itemCount: stoneIds.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: .15)),
                  itemBuilder: (context, index) {
                    final id = stoneIds[index];
                    final details = _purchaseService.products[id];
                    final amount = PurchaseService.stoneAmountFor(id) ?? 0;
                    final pending = _isPending(id);
                    final fallback = _demoStoneMeta[id];
                    final priceText = details?.price ?? fallback?['price'] ?? '—';
                    final descText = details?.description ?? fallback?['desc'] ?? 'Stone pack';
                    final disabled = !_demoActive && details == null;
                    return _ListRow(
                      leading: _iconCircle(Icons.diamond, gradient: true),
                      title: '$amount Stones',
                      subtitle: descText,
                      trailing: pending
                          ? const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2))
                          : _PrimaryButton(
                              label: priceText,
                              onTap: disabled ? null : () => _buyStonePack(id),
                            ),
                      faded: disabled,
                    );
                  },
                ),
      footer: Text(
        'Purchases are handled by the store provider. Preview mode if billing not available.',
        style: _smallMuted,
      ),
    );
  }

  Widget _iconCircle(IconData icon, {bool gradient = false, Color? color}) {
    final base = color ?? _primaryGradA;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient
            ? LinearGradient(colors: [_primaryGradA, _primaryGradB])
            : LinearGradient(colors: [base.withValues(alpha: .15), base.withValues(alpha: .05)]),
        border: Border.all(color: base.withValues(alpha: .40), width: 1),
      ),
      child: Icon(icon, color: gradient ? Colors.white : base, size: 22),
    );
  }

  Widget _buildFeatureUsage() {
    return _SectionCard(
      title: 'Premium Features',
      description: 'Use stones to instantly unlock focused premium actions.',
      child: ListView.separated(
        itemCount: _premiumFeatures.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: .15)),
        itemBuilder: (context, i) {
          final f = _premiumFeatures[i];
          final cost = f['cost'] as int;
          final affordable = _currentStones >= cost;
          return _ListRow(
            leading: _iconCircle(Icons.star, gradient: affordable, color: affordable ? _ok : Colors.grey),
            title: f['title'] as String,
            subtitle: f['desc'] as String,
            trailing: _PrimaryButton(
              label: affordable ? 'Use' : 'Need $cost',
              onTap: affordable ? () => _useFeature(f) : null,
              tone: affordable ? ButtonTone.primary : ButtonTone.disabled,
            ),
            extra: _CostChip(cost: cost, enough: affordable, color: affordable ? _ok : _warn),
            faded: !affordable,
          );
        },
      ),
      footer: Text('If a feature usage does not apply, please contact support.', style: _smallMuted),
    );
  }

  Widget _buildSubscriptionTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _SectionCard(
        title: 'Subscription',
        description: 'Sign in to view and manage subscription plans.',
        child: const Center(child: Text('Not signed in')),
      );
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final bool active = (data?['isPremium'] as bool?) ?? false;
        final String? untilRaw = data?['premiumUntil'] as String?;
        DateTime? until;
        if (untilRaw != null) {
          until = DateTime.tryParse(untilRaw);
        }
        return _SectionCard(
          title: 'Subscription Plans',
          description: active
              ? 'Your premium subscription is active.'
              : 'Unlock full premium access with a subscription.',
          trailing: active ? _badge('ACTIVE', _ok) : null,
          child: !_productsLoaded
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (active)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                        child: _activeSubscriptionInfo(until),
                      ),
                    _subscriptionPlanTile(
                      id: PurchaseService.monthlyProductId,
                      title: 'Monthly',
                      highlight: !active,
                      descriptor: 'Access all premium features for 1 month.',
                    ),
                    _subscriptionPlanTile(
                      id: PurchaseService.yearlyProductId,
                      title: 'Yearly',
                      highlight: true,
                      descriptor: 'Best value annual access (adds 12 months).',
                    ),
                    _subscriptionPlanTile(
                      id: PurchaseService.lifetimeProductId,
                      title: 'Lifetime',
                      highlight: false,
                      descriptor: 'One-time purchase. Lifetime premium access.',
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Subscriptions are handled by the store provider. Prices may vary by region.',
                              style: _smallMuted,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _purchaseService.restore(),
                            child: const Text('Restore'),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
        );
      },
    );
  }

  Widget _activeSubscriptionInfo(DateTime? until) {
    final s = until != null ? 'Renews / ends: ${until.toLocal().toString().split('.').first}' : 'Lifetime access';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _ok.withValues(alpha: .12),
        border: Border.all(color: _ok.withValues(alpha: .5)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: _ok.withValues(alpha: .9)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subscriptionPlanTile({
    required String id,
    required String title,
    required bool highlight,
    required String descriptor,
  }) {
    final details = _purchaseService.products[id];
    final price = details?.price ?? _fallbackSubPrices[id] ?? '—';
    final pending = _isPending(id);
    final badge = highlight ? _badge('POPULAR', _warn) : null;
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: highlight
              ? [_primaryGradA.withValues(alpha: .22), _primaryGradB.withValues(alpha: .18)]
              : [Theme.of(context).colorScheme.surface.withValues(alpha: .65), Theme.of(context).colorScheme.surface.withValues(alpha: .55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: highlight ? _primaryGradA.withValues(alpha: .55) : Theme.of(context).dividerColor.withValues(alpha: .35),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconCircle(
            id == PurchaseService.lifetimeProductId
                ? Icons.all_inclusive
                : id == PurchaseService.yearlyProductId
                    ? Icons.calendar_month
                    : Icons.calendar_view_month,
            gradient: highlight,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .3,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .87),
                        ),
                      ),
                    ),
                    if (badge != null) badge,
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  descriptor,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontSize: 12.2,
                        height: 1.3,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .62),
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: .08)
                            : Colors.black.withValues(alpha: .06),
                      ),
                      child: Text(
                        price,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: .4,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .85),
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 40,
                      child: pending
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                            )
                          : _PrimaryButton(
                              label: 'Buy',
                              onTap: details == null ? null : () => _buySubscription(id),
                            ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _buySubscription(String id) {
    setState(() {
      _pendingProductId = id;
    });
    _purchaseService.startPurchase(id);
  }

  // Badge widget for highlighting
  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(.12),
        border: Border.all(color: color.withOpacity(.6), width: 1.2),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ==== Helper Widgets (moved outside state class scope) ====

enum ButtonTone { primary, disabled }

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final ButtonTone tone;
  const _PrimaryButton({super.key, required this.label, this.onTap, this.tone = ButtonTone.primary});
  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null || tone == ButtonTone.disabled;
    final grad = const LinearGradient(colors: [Color(0xFF7B2FF7), Color(0xFF9F62FF)]);
    final bg = disabled ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .10) : null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: disabled ? null : grad,
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: disabled
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF7B2FF7).withValues(alpha: .35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                )
              ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 12.8,
          fontWeight: FontWeight.w700,
          letterSpacing: .4,
          color: disabled ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .45) : Colors.white,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
            onTap: disabled ? null : onTap,
          splashColor: Colors.white.withValues(alpha: .12),
          child: Center(child: Text(label)),
        ),
      ),
    );
  }
}

class _CostChip extends StatelessWidget {
  final int cost;
  final bool enough;
  final Color color;
  const _CostChip({super.key, required this.cost, required this.enough, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: .10),
        border: Border.all(color: color.withValues(alpha: .50), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.diamond, size: 14, color: color.withValues(alpha: .9)),
          const SizedBox(width: 4),
          Text('$cost', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color.withValues(alpha: .95))),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyMessage({super.key, required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [theme.colorScheme.primary.withValues(alpha: .15), theme.colorScheme.primary.withValues(alpha: .05)]),
          ),
          child: Icon(icon, size: 36, color: theme.colorScheme.primary.withValues(alpha: .85)),
        ),
        const SizedBox(height: 16),
        Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium!.copyWith(
            fontSize: 13,
            height: 1.35,
            color: theme.colorScheme.onSurface.withValues(alpha: .65),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? description;
  final Widget child;
  final Widget? trailing;
  final Widget? footer;
  const _SectionCard({super.key, required this.title, this.description, required this.child, this.trailing, this.footer});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.brightness == Brightness.dark
        ? [const Color(0x33FFFFFF), const Color(0x11FFFFFF)]
        : [const Color(0xAAFFFFFF), const Color(0x66FFFFFF)];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: glass,
          ),
          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: .10), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withValues(alpha: .08),
              blurRadius: 22,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800, letterSpacing: .5, fontSize: 18)),
                          if (description != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0, right: 4),
                              child: Text(
                                description!,
                                style: theme.textTheme.bodySmall!.copyWith(
                                      fontSize: 12.2,
                                      height: 1.35,
                                      color: theme.colorScheme.onSurface.withValues(alpha: .60),
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(child: child),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: footer!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  final Widget? extra;
  final bool faded;
  const _ListRow({super.key, required this.leading, required this.title, required this.subtitle, required this.trailing, this.extra, this.faded = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.onSurface.withValues(alpha: faded ? .45 : .85);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: .3, color: baseColor)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontSize: 12.2,
                    height: 1.25,
                    color: theme.colorScheme.onSurface.withValues(alpha: faded ? .45 : .60),
                  ),
                ),
              ],
            ),
          ),
          if (extra != null) ...[
            const SizedBox(width: 12),
            extra!,
          ],
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}
