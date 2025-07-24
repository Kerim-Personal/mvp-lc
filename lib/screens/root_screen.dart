// lib/screens/root_screen.dart

// DEĞİŞTİ: 'dart:ui' import'u artık gerekli olmadığı için kaldırıldı.
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
  int _selectedIndex = 1;
  late final List<Widget> _pages;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
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
      // DEĞİŞTİ: extendBody parametresi kaldırıldı, böylece body
      // navigasyon çubuğunun arkasına taşmaz.
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      // DEĞİŞTİ: Özel navigasyon çubuğu, standart BottomNavigationBar ile değiştirildi.
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.store_mall_directory_outlined),
            label: 'Mağaza',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // Ana temayla uyumlu olması için seçili ikon rengi ayarlandı.
        selectedItemColor: Theme.of(context).primaryColor,
        // Tüm etiketlerin görünmesi için tip ayarlandı.
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

// DEĞİŞTİ: _buildCustomBottomNavBar ve _buildNavItem metotları
// artık kullanılmadığı için kaldırıldı.
}