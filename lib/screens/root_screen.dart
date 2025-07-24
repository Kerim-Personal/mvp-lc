// lib/screens/root_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/screens/home_screen.dart';
import 'package:lingua_chat/screens/profile_screen.dart';
import 'package:lingua_chat/screens/store_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  // Uygulamanın Ana Sayfa (ortadaki sekme) ile başlaması için başlangıç indeksi 1 yapıldı.
  int _selectedIndex = 1;
  late final List<Widget> _pages;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Sayfa listesi yeni düzene göre güncellendi: Mağaza, Ana Sayfa, Profil
    _pages = [
      const StoreScreen(),
      const HomeScreen(),
      if (currentUser != null) ProfileScreen(userId: currentUser!.uid),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedIndex >= _pages.length) {
      _selectedIndex = 1; // Hata durumunda ana sayfaya yönlendir.
    }

    return Scaffold(
      // bottomNavigationBar'ı kaldırıp Stack yapısı kullanıyoruz
      // böylece özel navigasyon barımızı sayfa içeriğinin üzerine koyabiliriz.
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          // Özel ve animasyonlu navigasyon barımız
          _buildCustomBottomNavBar(),
        ],
      ),
    );
  }

  // YENİ: Mükemmel görünümlü navigasyon barını oluşturan metot
  Widget _buildCustomBottomNavBar() {
    return Positioned(
      bottom: 25, // Ekranın altından boşluk
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50.0),
              border: Border.all(width: 1.5, color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.store_mall_directory_outlined, 'Mağaza', 0),
                _buildNavItem(Icons.home_rounded, 'Ana Sayfa', 1),
                _buildNavItem(Icons.person_rounded, 'Profil', 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // YENİ: Navigasyon barındaki her bir butonu oluşturan metot
  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withOpacity(0.9) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade800,
              size: 26,
            ),
            // Sadece seçili olduğunda metni göstererek daha temiz bir görünüm elde ediyoruz
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}