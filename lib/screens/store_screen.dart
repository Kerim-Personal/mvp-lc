// lib/screens/store_screen.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/widgets/shared/animated_background.dart';
import 'package:lingua_chat/widgets/store_screen/glassmorphism.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lingua_chat/widgets/store_screen/premium_animated_background.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with TickerProviderStateMixin {
  bool _isYearlySelected = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  // Konfeti, shimmer ve pulse animasyonları
  late final AnimationController _confettiController;
  late final AnimationController _premiumShimmerController;
  late final AnimationController _pulseController;
  bool _lastIsPremium = false;
  bool _confettiPlayedOnce = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _confettiController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _premiumShimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    _premiumShimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPushedAsSeparatePage = Navigator.of(context).canPop();

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
        body: _buildBodyWithBackground(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildBodyWithBackground(),
    );
  }

  // Premium durumunu dinler, uygun arka plan + içerik ile Stack döndürür.
  Widget _buildBodyWithBackground() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stack(children: [
        const AnimatedBackground(),
        _buildNonPremiumContent(),
      ]);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final bool isPremium = (data?['isPremium'] as bool?) ?? false;

        // Premiuma ilk geçişte konfeti oynat
        if (isPremium && !_lastIsPremium && !_confettiPlayedOnce) {
          _confettiPlayedOnce = true;
          _confettiController
            ..reset()
            ..forward();
        }
        _lastIsPremium = isPremium;

        return Stack(
          children: [
            // Arka plan seçimi
            if (isPremium) const PremiumAnimatedBackground() else const AnimatedBackground(),
            // İçerik
            isPremium ? _buildPremiumContent() : _buildNonPremiumContent(),
            // Konfeti overlay
            if (_confettiController.isAnimating || _confettiController.value > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _confettiController,
                    builder: (context, _) => CustomPaint(
                      painter: _ConfettiPainter(progress: _confettiController.value),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // DEĞİŞİKLİK: Premium durumunu dinleyip uygun içerik döndür.
  Widget _buildStoreContent() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Oturum yoksa, non-premium ekran göster.
      return _buildNonPremiumContent();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data?.data();
        final bool isPremium = (data?['isPremium'] as bool?) ?? false;
        return isPremium ? _buildPremiumContent() : _buildNonPremiumContent();
      },
    );
  }

  // Mevcut mağaza içeriği (satın alma ekranı) buraya taşındı.
  Widget _buildNonPremiumContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.purple.shade400, Colors.purple.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                    child: const Text(
                      'Lingua Pro',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black26,
                            offset: Offset(3.0, 3.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Tüm premium özelliklere erişerek\npotansiyelini açığa çıkar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.5,
                      color: Colors.black.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            Flexible(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildPlanCard(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PREMIUM: Abonelik aktif görünümü
  Widget _buildPremiumContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Başlık + rozet
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Shimmer'lı başlık
                  AnimatedBuilder(
                    animation: _premiumShimmerController,
                    builder: (context, _) {
                      final v = _premiumShimmerController.value; // 0..1
                      final stops = [
                        (v - 0.25).clamp(0.0, 1.0),
                        v,
                        (v + 0.25).clamp(0.0, 1.0),
                      ];
                      return ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => LinearGradient(
                          colors: const [Colors.amber, Colors.white, Colors.amber],
                          stops: stops,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                        child: const Text(
                          'Lingua Pro',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 10, color: Colors.black26, offset: Offset(2, 2))],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.amber.shade300, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text('Pro Aktif', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Teşekkür + avantajlar kartı
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: GlassmorphicContainer(
                  width: double.infinity,
                  borderRadius: 28,
                  blur: 18,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.4),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(170, 255, 255, 255),
                      Color.fromARGB(80, 255, 255, 255),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.amber.shade400, Colors.orange.shade600],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.shade200.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                              ),
                              child: const Icon(Icons.auto_awesome, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Teşekkürler! Pro ile tüm özelliklerin kilidi açık.',
                                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.black.withValues(alpha: 0.06), height: 1),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPremiumFeature('Sohbet içi anlık çeviri', Icons.translate),
                                _buildPremiumFeature('Seviyeye/cinsiyete göre partner arama', Icons.filter_alt_outlined),
                                _buildPremiumFeature('Reklamsız deneyim', Icons.ads_click),
                                _buildPremiumFeature("LinguaBot'a pro erişim", Icons.smart_toy_outlined),
                                _buildPremiumFeature('Öncelikli destek', Icons.support_agent),
                                _buildPremiumFeature('Gelişmiş gramer analizi', Icons.spellcheck),
                                _buildPremiumFeature('Kişiselleştirme temaları', Icons.palette_outlined),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _onManageSubscription,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  side: BorderSide(color: Colors.amber.shade400, width: 1.2),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.manage_accounts),
                                label: const Text('Aboneliği Yönet'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              // Pulse micro-interaction
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  final v = _pulseController.value; // 0..1
                                  final scale = 1.0 + 0.02 * math.sin(v * 2 * math.pi);
                                  return Transform.scale(scale: scale, child: child);
                                },
                                child: ElevatedButton.icon(
                                  onPressed: _goToSupport,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 10,
                                    shadowColor: Colors.amber.withValues(alpha: 0.4),
                                  ),
                                  icon: const Icon(Icons.headset_mic_outlined),
                                  label: const Text('Destek'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeature(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber.withValues(alpha: 0.2),
              border: Border.all(color: Colors.amber.shade400, width: 1),
            ),
            child: Icon(icon, size: 14, color: Colors.orange.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  // Aboneliği yönet: platformdan bağımsız güvenli açılış (önce Play, sonra Apple, sonra yardım makalesi)
  void _onManageSubscription() async {
    const packageName = 'com.codenzi.lingua_chat';
    final candidates = <Uri>[
      Uri.parse('https://play.google.com/store/account/subscriptions?package=$packageName'),
      Uri.parse('https://apps.apple.com/account/subscriptions'),
      Uri.parse('https://support.google.com/googleplay/answer/7018481?hl=tr'),
    ];

    for (final uri in candidates) {
      try {
        if (await canLaunchUrl(uri)) {
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (ok) return;
        }
      } catch (_) {
        // sıradaki adaya geç
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abonelik yönetimi açılamadı. Lütfen mağaza hesabı ayarlarınızı kontrol edin.')),
    );
  }

  void _goToSupport() {
    // Kullanıcıyı öncelikli destek formuna yönlendir.
    Navigator.of(context).pushNamed('/support');
  }

  Widget _buildPlanCard() {
    return GlassmorphicContainer(
      width: double.infinity,
      borderRadius: 30,
      blur: 15,
      border: Border.all(color: Colors.white, width: 1.5),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.fromARGB(138, 255, 255, 255),
          Color.fromARGB(61, 255, 255, 255),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSubscriptionToggle(),
            _buildFeatureList(),
            _buildActionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(13, 0, 0, 0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleChild('Aylık', !_isYearlySelected)),
          Expanded(child: _buildToggleChild('Yıllık', _isYearlySelected, isDiscounted: true)),
        ],
      ),
    );
  }

  Widget _buildToggleChild(String text, bool isSelected, {bool isDiscounted = false}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isYearlySelected = text == 'Yıllık';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? const Color.fromARGB(230, 156, 39, 176) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSelected ? Colors.white : Colors.black54,
                ),
              ),
              if (isDiscounted)
                Text(
                  '2 Ay Ücretsiz',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.amber.shade200 : Colors.green,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      {'icon': Icons.translate, 'text': 'Çeviri Desteği'},
      {'icon': Icons.hourglass_bottom_outlined, 'text': 'Sohbet Uzatma Jetonu'},
      {'icon': Icons.wc, 'text': 'Cinsiyete Göre Partner Arama'},
      {'icon': Icons.bar_chart_rounded, 'text': 'Seviyeye Göre Partner Arama'},
      {'icon': Icons.support_agent, 'text': 'Öncelikli Destek'},
      {'icon': Icons.ads_click, 'text': 'Reklamsız Deneyim'},
      {'icon': Icons.smart_toy_outlined, 'text': "LinguaBot'a Pro Erişim"},
      {'icon': Icons.spellcheck, 'text': "Gelişmiş Gramer Analizi"},
      {'icon': Icons.palette_outlined, 'text': "Premium'a Özel Kişiselleştirmeler"},
    ];

    return Flexible(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: features.map((feature) => _buildFeatureRow(feature['text'] as String, feature['icon'] as IconData)).toList(),
      ),
    );
  }

  Widget _buildFeatureRow(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14.5, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: Text(
            _isYearlySelected ? '899.99 TL/yıl' : '89.99 TL/ay',
            key: ValueKey<bool>(_isYearlySelected),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 10,
            shadowColor: const Color.fromARGB(128, 156, 39, 176),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Hemen Başla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// Basit konfeti ressamı: üst merkezden farklı açılarla parçacıklar saçar.
class _ConfettiPainter extends CustomPainter {
  final double progress; // 0..1
  _ConfettiPainter({required this.progress});

  final List<Color> _palette = const [
    Color(0xFFFFC107), // amber
    Color(0xFFFF5722), // deep orange
    Color(0xFF9C27B0), // purple
    Color(0xFF03A9F4), // light blue
    Color(0xFF4CAF50), // green
    Color(0xFFFFEB3B), // yellow
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.15);
    final rnd = math.Random(7);
    final count = 120;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + (progress * 1.2);
      final spread = 40 + 260 * progress; // yarıçap artışı
      final gravity = 0.6 * progress * progress * size.height * 0.25;
      final radius = spread + rnd.nextDouble() * 30;
      final x = center.dx + math.cos(angle) * radius + rnd.nextDouble() * 6 * (1 - progress);
      final y = center.dy + math.sin(angle) * radius + gravity;

      final color = _palette[i % _palette.length];
      final paint = Paint()..color = color.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0));

      // Konfeti parçacığı: küçük dönen dikdörtgenler
      final sizeFactor = 2.0 + (i % 3) * 0.8 + rnd.nextDouble();
      final rectSize = Size(sizeFactor + 2, sizeFactor + 5);
      final rect = Rect.fromCenter(center: Offset(x, y), width: rectSize.width, height: rectSize.height);

      final rotation = angle * 3 + progress * 8 + (i % 5) * 0.2;
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(rotation);
      canvas.translate(-rect.center.dx, -rect.center.dy);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}
