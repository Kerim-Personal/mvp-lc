// lib/screens/store_screen.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/widgets/shared/animated_background.dart'; // <-- YENİ İMPORT
import 'package:lingua_chat/widgets/store_screen/glassmorphism.dart';

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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // DEĞİŞİKLİK: Sayfanın direkt mi yoksa RootScreen içinden mi açıldığını kontrol et
    final bool isPushedAsSeparatePage = Navigator.of(context).canPop();

    // Eğer sayfa direkt açıldıysa, kendi arkaplanını ve AppBar'ını oluştur.
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
        body: Stack(
          children: [
            const AnimatedBackground(),
            _buildStoreContent(),
          ],
        ),
      );
    }

    // Eğer RootScreen içindeyse, şeffaf kalmaya devam et.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildStoreContent(),
    );
  }

  Widget _buildStoreContent() {
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
                      color: Colors.black.withOpacity(0.7),
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