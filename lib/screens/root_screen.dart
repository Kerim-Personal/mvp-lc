// lib/screens/root_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/screens/goals_screen.dart';
import 'package:lingua_chat/screens/home_screen.dart';
import 'package:lingua_chat/screens/profile_screen.dart'; // <-- HATA BURADAYDI, DÜZELTİLDİ

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(),
      const GoalsScreen(),
      // Mevcut kullanıcı ID'si ile ProfileScreen'i başlatıyoruz.
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
    // Profil sayfası null olabileceğinden (kullanıcı yoksa) kontrol ekliyoruz.
    if (_pages.length < 3 && _selectedIndex > 1) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_rounded),
            label: 'Hedefler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey.shade600,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }
}