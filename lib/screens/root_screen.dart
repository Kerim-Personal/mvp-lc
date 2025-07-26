// lib/screens/root_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:lingua_chat/screens/home_screen.dart';
import 'package:lingua_chat/screens/profile_screen.dart';
import 'package:lingua_chat/screens/store_screen.dart';
import 'package:lingua_chat/screens/discover_screen.dart';
import 'package:lingua_chat/screens/community_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    final List<Widget> pages = [
      const StoreScreen(),
      const DiscoverScreen(),
      const HomeScreen(),
      const CommunityScreen(),
    ];

    final List<GButton> tabs = [
      const GButton(icon: Icons.store_mall_directory_outlined, text: 'Mağaza'),
      const GButton(icon: Icons.explore_outlined, text: 'Keşfet'),
      const GButton(icon: Icons.home_rounded, text: 'Ana Sayfa'),
      const GButton(icon: Icons.groups_outlined, text: 'Topluluk'),
    ];

    if (currentUser != null) {
      pages.add(ProfileScreen(userId: currentUser.uid));
      tabs.add(
        const GButton(icon: Icons.person_rounded, text: 'Profil'),
      );
    }

    if (_selectedIndex >= pages.length) {
      _selectedIndex = 2;
    }

    // DÜZELTME: Scaffold'u basitleştirip gereksiz AppBar'ı ve özelliği kaldırıyoruz.
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(0.1),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Colors.teal.shade400,
              color: Colors.black54,
              tabs: tabs,
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}