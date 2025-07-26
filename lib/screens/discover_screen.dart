// lib/screens/discover_screen.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/widgets/discover/grammar_tab.dart';
import 'package:lingua_chat/widgets/discover/vocabulary_tab.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keşfet'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.teal,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Gramer', icon: Icon(Icons.spellcheck)),
            Tab(text: 'Kelime', icon: Icon(Icons.style_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          GrammarTab(),
          VocabularyTab(),
        ],
      ),
    );
  }
}