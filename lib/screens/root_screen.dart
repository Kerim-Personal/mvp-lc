// lib/screens/root_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/screens/home_screen.dart';
import 'package:lingua_chat/screens/profile_screen.dart';
import 'package:lingua_chat/screens/store_screen.dart';
import 'package:lingua_chat/screens/discover_screen.dart';
import 'package:lingua_chat/screens/community_screen.dart';
import 'package:lingua_chat/widgets/shared/animated_background.dart';
import 'dart:ui' show lerpDouble;

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
  late PageController _pageController;
  late AnimationController _navIconAnimationController; // geri eklendi
  late Animation<double> _scaleAnimation; // geri eklendi

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _navIconAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _scaleAnimation = CurvedAnimation(parent: _navIconAnimationController, curve: Curves.easeOutCubic);
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
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
    );
    _navIconAnimationController.forward(from: 0); // animasyon tetikleme
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
      bottomNavigationBar: _isSearching ? null : _buildBottomNav(currentUser),
    );
  }

  Widget _buildBottomNav(User? currentUser) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color backgroundColor = (isDark ? cs.surface : Colors.white).withValues(alpha: isDark ? 0.94 : 0.97);
    final Color shadowColor = isDark ? Colors.black.withValues(alpha: 0.45) : Colors.black.withValues(alpha: 0.06);
    final Color inactiveColor = isDark ? cs.onSurface.withValues(alpha: 0.65) : Colors.black87;
    final Color activeColor = cs.primary;
    final Color activeIconColor = cs.onPrimary;

    final items = <_NavItemData>[
      _NavItemData(icon: Icons.store_mall_directory_outlined, label: 'Store'),
      _NavItemData(icon: Icons.explore_outlined, label: 'Discover'),
      _NavItemData(icon: Icons.home_rounded, label: 'Home'),
      _NavItemData(icon: Icons.groups_outlined, label: 'Community'),
      if (currentUser != null) _NavItemData(icon: Icons.person_rounded, label: 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
            width: 0.6,
          ),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, -4),
            color: shadowColor,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72, // kompaktlaştırıldı (önce: 86)
          child: Row(
            children: List.generate(items.length, (index) {
              final data = items[index];
              final selected = _selectedIndex == index;
              return Expanded(
                child: _NavBarItem(
                  data: data,
                  selected: selected,
                  activeColor: activeColor,
                  activeIconColor: activeIconColor,
                  inactiveColor: inactiveColor,
                  animation: _scaleAnimation,
                  onTap: () => _onItemTapped(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  const _NavItemData({required this.icon, required this.label});
}

class _NavBarItem extends StatelessWidget {
  final _NavItemData data;
  final bool selected;
  final Color activeColor;
  final Color activeIconColor;
  final Color inactiveColor;
  final Animation<double> animation;
  final VoidCallback onTap;
  const _NavBarItem({
    required this.data,
    required this.selected,
    required this.activeColor,
    required this.activeIconColor,
    required this.inactiveColor,
    required this.animation,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final highlightColor = activeColor;
    return Semantics(
      selected: selected,
      button: true,
      label: data.label,
      child: InkWell(
        onTap: onTap,
        splashColor: highlightColor.withValues(alpha: 0.15),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: selected ? highlightColor : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AnimatedNavIcon(
                  icon: data.icon,
                  selected: selected,
                  activeColor: activeIconColor,
                  inactiveColor: inactiveColor,
                  animation: animation,
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                    color: selected ? activeIconColor : inactiveColor.withValues(alpha: 0.85),
                  ),
                  child: Text(
                    data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final Animation<double> animation;
  const _AnimatedNavIcon({
    required this.icon,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.animation,
  });
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        double scale;
        if (selected) {
          if (animation.value < 0.55) { // büyüme fazı
            final t = animation.value / 0.55;
            scale = lerpDouble(1.0, 1.25, t)!;
          } else { // geri dönme fazı
            final t = (animation.value - 0.55) / 0.45;
            scale = lerpDouble(1.25, 1.0, t)!;
          }
        } else {
          scale = 1.0;
        }
        return SizedBox(
          width: 30,
          height: 30,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: selected ? activeColor : inactiveColor,
              size: 24,
            ),
          ),
        );
      },
    );
  }
}