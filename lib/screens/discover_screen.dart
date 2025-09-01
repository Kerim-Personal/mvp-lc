// lib/screens/discover_screen.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/widgets/discover/grammar_tab.dart';
import 'package:lingua_chat/widgets/discover/vocabulary_tab.dart';
import '../widgets/discover/practice_tab.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int _selectedIndex = 0; // 0: Gramer, 1: Kelime, 2: Pratik

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Özel Sekme Seçici
            _buildTabSelector(),
            const SizedBox(height: 16),

            // Sekme İçeriği (Gramer, Kelime, Pratik)
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                          parent: animation, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                  );
                },
                child: _selectedIndex == 0
                    ? GrammarTab(key: const ValueKey('grammar'))
                    : _selectedIndex == 1
                        ? VocabularyTab(key: const ValueKey('vocabulary'))
                        : PracticeTab(key: const ValueKey('practice')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          // ÇÖZÜLDÜ: withOpacity uyarısını gidermek için withAlpha kullanıldı. (0.05 * 255 ~= 13)
          color: Colors.black.withAlpha(13),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _buildTabItem(title: 'Gramer', icon: Icons.spellcheck, index: 0),
            _buildTabItem(
                title: 'Kelime', icon: Icons.style_outlined, index: 1),
            _buildTabItem(title: 'Pratik', icon: Icons.quiz_outlined, index: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(
      {required String title, required IconData icon, required int index}) {
    final bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      // ÇÖZÜLDÜ: withOpacity uyarısını gidermek için withAlpha kullanıldı. (0.1 * 255 ~= 26)
                      color: Colors.black.withAlpha(26),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.teal : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.teal : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}