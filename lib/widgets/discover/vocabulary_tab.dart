// lib/widgets/discover/vocabulary_tab.dart

import 'package:flutter/material.dart';

// Veri Modeli
class VocabularyPack {
  final String title;
  final IconData icon;
  final Color color1;
  final Color color2;
  final int wordCount;
  final double progress;
  const VocabularyPack({required this.title, required this.icon, required this.color1, required this.color2, required this.wordCount, required this.progress});
}

// Kelime Sekmesi Ana Widget'ı
class VocabularyTab extends StatelessWidget {
  const VocabularyTab({super.key});

  final List<VocabularyPack> vocabularyPacks = const [
    VocabularyPack(title: 'İş İngilizcesi', icon: Icons.business_center, color1: Colors.blue, color2: Color(0xFF536DFE), wordCount: 50, progress: 0.75),
    VocabularyPack(title: 'Seyahat', icon: Icons.flight_takeoff, color1: Colors.orange, color2: Color(0xFFFFAB40), wordCount: 75, progress: 0.3),
    VocabularyPack(title: 'Teknoloji', icon: Icons.computer, color1: Color(0xFF616161), color2: Color(0xFF9E9E9E), wordCount: 60, progress: 0.0),
    VocabularyPack(title: 'Yemek & Mutfak', icon: Icons.restaurant_menu, color1: Colors.red, color2: Color(0xFFEF5350), wordCount: 40, progress: 0.9),
    VocabularyPack(title: 'Sağlık & Fitness', icon: Icons.fitness_center, color1: Colors.green, color2: Color(0xFF66BB6A), wordCount: 65, progress: 0.1),
    VocabularyPack(title: 'Sanat & Kültür', icon: Icons.palette, color1: Colors.purple, color2: Color(0xFFAB47BC), wordCount: 55, progress: 0.0),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const SectionTitle(title: 'Tematik Kelime Paketleri'),
        const SizedBox(height: 16),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.9,
          ),
          itemCount: vocabularyPacks.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) => VocabularyPackCard(pack: vocabularyPacks[index]),
        ),
      ],
    );
  }
}

// Bölüm Başlığı
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }
}

// Kelime Paketi Kartı
class VocabularyPackCard extends StatelessWidget {
  final VocabularyPack pack;
  const VocabularyPackCard({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [pack.color1, pack.color2], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: pack.color2.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(pack.icon, color: Colors.white, size: 36),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pack.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('${pack.wordCount} kelime', style: TextStyle(color: Colors.white.withOpacity(0.9))),
                const SizedBox(height: 8),
                if (pack.progress > 0)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: pack.progress,
                      backgroundColor: Colors.white.withAlpha(77),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}