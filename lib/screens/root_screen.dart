// lib/screens/root_screen.dart

import 'dart:ui'; // YENİ: BackdropFilter için import edildi
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
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

  // YENİ: StoreScreen'den taşınan Glassmorphism arka plan metodu
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

  @override
  Widget build(BuildContext context) {
    if (_selectedIndex >= _pages.length) {
      _selectedIndex = 1;
    }

    // DEĞİŞTİ: Yapı, Stack içine alınarak arka planın her zaman
    // en altta olması sağlandı.
    return Scaffold(
      body: Stack(
        children: [
          // En alttaki katman: Hareketli ve bulanık arka plan
          _buildAnimatedBackground(),
          // Üstteki katman: Görüntülenecek olan asıl sayfa içeriği
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: Colors.white,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Colors.teal.shade400,
              color: Colors.black54,
              tabs: const [
                GButton(
                  icon: Icons.store_mall_directory_outlined,
                  text: 'Mağaza',
                ),
                GButton(
                  icon: Icons.home_rounded,
                  text: 'Ana Sayfa',
                ),
                GButton(
                  icon: Icons.person_rounded,
                  text: 'Profil',
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}