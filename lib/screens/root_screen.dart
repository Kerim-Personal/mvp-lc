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

  // DEĞİŞİKLİK: State sınıfının adını dışarıya açtık (public yaptık).
  @override
  RootScreenState createState() => RootScreenState();
}

// DEĞİŞİKLİK: State sınıfının adı '_' olmadan (public) olarak değiştirildi.
class RootScreenState extends State<RootScreen> with TickerProviderStateMixin {
  int _selectedIndex = 2;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _createDefaultChatRooms();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // YENİ: Dışarıdan sekme değiştirmeyi sağlayacak metot.
  void changeTab(int index) {
    if (index >= 0 && index < 5) { // Olası hataları önlemek için kontrol
      _onItemTapped(index);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _animationController.forward().then((value) => _animationController.reverse());
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

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
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
              color: Colors.black.withAlpha(26),
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
              duration: const Duration(milliseconds: 100),
              tabBackgroundColor: Colors.teal.shade400,
              color: Colors.black54,
              tabs: tabs.asMap().entries.map((entry) {
                int idx = entry.key;
                GButton tab = entry.value;
                return GButton(
                  icon: tab.icon,
                  text: tab.text!,
                  leading: _selectedIndex == idx
                      ? ScaleTransition(
                    scale: _scaleAnimation,
                    child: Icon(
                      tab.icon,
                      color: Colors.white,
                    ),
                  )
                      : Icon(
                    tab.icon,
                    color: Colors.black54,
                  ),
                );
              }).toList(),
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}