// lib/screens/store_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lingua_chat/widgets/store_screen/glassmorphism.dart'; // Glassmorphism widget'ını import ediyoruz

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with TickerProviderStateMixin {
  bool _isYearlySelected = true; // Yıllık seçeneği varsayılan yapalım
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
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          _buildStoreContent(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -150,
          child: CircleAvatar(radius: 220, backgroundColor: const Color.fromARGB(77, 156, 39, 176)),
        ),
        Positioned(
          bottom: -180,
          left: -150,
          child: CircleAvatar(radius: 250, backgroundColor: const Color.fromARGB(77, 0, 188, 212)),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }

  Widget _buildStoreContent() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView( // İçeriğin küçük ekranlarda taşmasını engeller
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Lingua Pro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Tüm premium özelliklere erişerek potansiyelini açığa çıkar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(height: 30),
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildPlanCard(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard() {
    // Kartın yüksekliğini içeriğe göre dinamik hale getirdik
    return GlassmorphicContainer(
      width: double.infinity,
      height: 540, // Yüksekliği yeni özellik için biraz daha artırdık
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
          // 'Yıllık' butonuna mı tıklandı, ona göre durumu ayarla
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
    // GÜNCELLEME: "Cinsiyete Göre Arama" özelliği eklendi
    final features = [
      'Sınırsız Çeviri Desteği',
      'Sınırsız Sohbet Uzatma Jetonu',
      'Cinsiyete Göre Partner Arama',
      'İleri Seviye Partnerlerle Eşleşme (C1-C2)',
      'İleri Seviye İstatistikler',
      'Öncelikli Destek',
      'Özel Tema Seçenekleri',
      'Reklamsız Deneyim',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.purple, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(feature, style: const TextStyle(fontSize: 15, color: Colors.black87))),
          ],
        ),
      )).toList(),
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