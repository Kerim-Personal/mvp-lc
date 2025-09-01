// lib/screens/root_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:lingua_chat/screens/home_screen.dart';
import 'package:lingua_chat/screens/profile_screen.dart';
import 'package:lingua_chat/screens/store_screen.dart';
import 'package:lingua_chat/screens/discover_screen.dart';
import 'package:lingua_chat/screens/community_screen.dart';
import 'package:lingua_chat/widgets/shared/animated_background.dart';

// Bu fonksiyon veritabanı kurulumu için, dokunulmasına gerek yok.
Future<void> _createDefaultChatRooms() async {
  final chatRoomsCollection = FirebaseFirestore.instance.collection('group_chats');
  final snapshot = await chatRoomsCollection.limit(1).get();
  if (snapshot.docs.isEmpty) {
    final batch = FirebaseFirestore.instance.batch();
    final defaultRooms = [
      {
        "name": "Müzik Kutusu",
        "description": "Farklı türlerden müzikler keşfedin ve favori sanatçılarınızı paylaşın.",
        "iconName": "music_note_outlined",
        "color1": "0xFFF06292",
        "color2": "0xFFE57373",
        "isFeatured": true
      },
    ];
    for (var roomData in defaultRooms) {
      final docRef = chatRoomsCollection.doc();
      batch.set(docRef, roomData);
    }
    await batch.commit();
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  RootScreenState createState() => RootScreenState();
}

class RootScreenState extends State<RootScreen> with TickerProviderStateMixin {
  int _selectedIndex = 2;
  bool _isSearching = false; // partner arama tam ekran durumu
  late AnimationController _navIconAnimationController;
  late Animation<double> _scaleAnimation;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);

    _navIconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _navIconAnimationController,
        curve: Curves.easeOut,
      ),
    );
    _createDefaultChatRooms();
  }

  @override
  void dispose() {
    _navIconAnimationController.dispose();
    _pageController.dispose(); // Controller'ı dispose etmeyi unutma
    super.dispose();
  }

  void changeTab(int index) {
    if (index >= 0 && index < 5) {
      _onItemTapped(index);
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    // Sayfayı animasyonlu olarak değiştir
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 10),
      curve: Curves.easeInOut,
    );
    _navIconAnimationController.forward().then((_) => _navIconAnimationController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    final List<Widget> pages = [
      const StoreScreen(),
      const DiscoverScreen(),
      HomeScreen( // const kaldırıldı callback için
        onSearchingChanged: (val) {
          if (mounted) setState(() => _isSearching = val);
        },
      ),
      const CommunityScreen(),
      if (currentUser != null) ProfileScreen(userId: currentUser.uid),
    ];

    final List<GButton> tabs = [
      const GButton(icon: Icons.store_mall_directory_outlined, text: 'Mağaza'),
      const GButton(icon: Icons.explore_outlined, text: 'Keşfet'),
      const GButton(icon: Icons.home_rounded, text: 'Ana Sayfa'),
      const GButton(icon: Icons.groups_outlined, text: 'Topluluk'),
      if (currentUser != null)
        const GButton(icon: Icons.person_rounded, text: 'Profil'),
    ];

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: pages,
          ),
        ],
      ),
      bottomNavigationBar: _isSearching ? null : _buildBottomNav(tabs),
    );
  }

  Widget _buildBottomNav(List<GButton> tabs) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Arka plan ile daha uyumlu, hafif saydam yüzey rengi
    final Color backgroundColor = (isDark ? cs.surface : Colors.white).withValues(alpha: isDark ? 0.92 : 0.96);
    final Color shadowColor = isDark ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.05);
    final Color inactiveColor = isDark ? cs.onSurface.withValues(alpha: 0.65) : Colors.black54;
    final Color activeTabColor = cs.primary; // sekme arka planı
    final Color activeIconColor = cs.onPrimary; // aktif ikon + yazı

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
            width: 0.6,
          ),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, -2),
            color: shadowColor,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
          child: GNav(
            rippleColor: activeTabColor.withValues(alpha: 0.18),
            hoverColor: activeTabColor.withValues(alpha: 0.10),
            gap: 8,
            activeColor: activeIconColor,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            duration: const Duration(milliseconds: 140),
            tabBackgroundColor: activeTabColor,
            color: inactiveColor,
            tabs: tabs.asMap().entries.map((entry) {
              int idx = entry.key;
              GButton tab = entry.value;
              final bool selected = _selectedIndex == idx;
              return GButton(
                icon: tab.icon,
                text: tab.text,
                leading: selected
                    ? ScaleTransition(
                        scale: _scaleAnimation,
                        child: Icon(
                          tab.icon,
                          color: activeIconColor,
                        ),
                      )
                    : Icon(
                        tab.icon,
                        color: inactiveColor,
                      ),
              );
            }).toList(),
            selectedIndex: _selectedIndex,
            onTabChange: _onItemTapped,
          ),
        ),
      ),
    );
  }
}