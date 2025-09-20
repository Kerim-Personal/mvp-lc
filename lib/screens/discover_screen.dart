// lib/screens/discover_screen.dart

import 'package:flutter/material.dart';
import 'package:vocachat/widgets/discover/grammar_tab.dart';
import 'package:vocachat/widgets/discover/vocabulary_tab.dart';
import '../widgets/discover/practice_tab.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, this.activationTrigger = 0});
  final int activationTrigger; // RootScreen sekmeye her dönüşte artırır

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int _selectedIndex = 0; // 0: Grammar, 1: Vocabulary, 2: Practice
  int _grammarReplay = 0;

  @override
  void didUpdateWidget(covariant DiscoverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activationTrigger != widget.activationTrigger) {
      if (_selectedIndex == 0) {
        setState(() => _grammarReplay++);
      }
    }
  }

  void _selectTab(int idx) {
    if (_selectedIndex == idx) {
      if (idx == 0) setState(() => _grammarReplay++); // aynı sekmeye tekrar basınca replay
      return;
    }
    setState(() {
      _selectedIndex = idx;
      if (idx == 0) _grammarReplay++; // Grammar'a geçerken tetikle
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabSelector(),
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
                    ? GrammarTab(key: ValueKey('grammar_$_grammarReplay'), replayTrigger: _grammarReplay)
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20), // Community ile hizalı
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(13),
          borderRadius: BorderRadius.circular(20), // Community: 20
        ),
        child: Row(
          children: [
            _buildTabItem(title: 'Grammar', icon: Icons.spellcheck, index: 0),
            _buildTabItem(title: 'Vocabulary', icon: Icons.style_outlined, index: 1),
            _buildTabItem(title: 'Practice', icon: Icons.quiz_outlined, index: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({required String title, required IconData icon, required int index}) {
    final bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12), // Community ile uyumlu
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16), // Community: 16
            boxShadow: isSelected
                ? [
                    BoxShadow(
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