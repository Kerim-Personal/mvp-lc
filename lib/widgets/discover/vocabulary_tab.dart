// lib/widgets/discover/vocabulary_tab.dart

import 'package:flutter/material.dart';

// --- Veri Modeli ---
class VocabularyPack {
  final String title;
  final IconData icon;
  final Color color1;
  final Color color2;
  final int wordCount;
  final double progress;

  const VocabularyPack({
    required this.title,
    required this.icon,
    required this.color1,
    required this.color2,
    required this.wordCount,
    required this.progress,
  });
}

// --- Ana Widget ---
class VocabularyTab extends StatelessWidget {
  const VocabularyTab({super.key});

  final List<VocabularyPack> vocabularyPacks = const [
    VocabularyPack(title: 'İş İngilizcesi', icon: Icons.business_center, color1: Colors.blue, color2: Color(0xFF536DFE), wordCount: 50, progress: 0.75),
    VocabularyPack(title: 'Seyahat', icon: Icons.flight_takeoff, color1: Colors.orange, color2: Color(0xFFFFAB40), wordCount: 75, progress: 0.3),
    VocabularyPack(title: 'Teknoloji', icon: Icons.computer, color1: Color(0xFF616161), color2: Color(0xFF9E9E9E), wordCount: 60, progress: 0.0),
    VocabularyPack(title: 'Yemek & Mutfak', icon: Icons.restaurant_menu, color1: Colors.red, color2: Color(0xFFEF5350), wordCount: 40, progress: 0.9),
    VocabularyPack(title: 'Sağlık & Fitness', icon: Icons.fitness_center, color1: Colors.green, color2: Color(0xFF66BB6A), wordCount: 65, progress: 0.1),
    VocabularyPack(title: 'Sanat & Kültür', icon: Icons.palette, color1: Colors.purple, color2: Color(0xFFAB47BC), wordCount: 55, progress: 0.0),
    VocabularyPack(title: 'Finans & Ekonomi', icon: Icons.account_balance, color1: Colors.teal, color2: Color(0xFF26A69A), wordCount: 80, progress: 0.5),
    VocabularyPack(title: 'Doğa & Çevre', icon: Icons.eco, color1: Colors.brown, color2: Color(0xFF8D6E63), wordCount: 45, progress: 1.0),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const SectionTitle(title: 'Tematik Kelime Paketleri'),
        const SizedBox(height: 12),
        VocabularyPacksGrid(packs: vocabularyPacks),
        const SizedBox(height: 24),
        const SectionTitle(title: 'Alıştırmalar'),
        const SizedBox(height: 12),
        const VocabularyPracticeGrid(),
      ],
    );
  }
}


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

class VocabularyPacksGrid extends StatelessWidget {
  final List<VocabularyPack> packs;
  const VocabularyPacksGrid({super.key, required this.packs});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: packs.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final pack = packs[index];
        return VocabularyPackCard(pack: pack);
      },
    );
  }
}

class VocabularyPackCard extends StatelessWidget {
  final VocabularyPack pack;
  const VocabularyPackCard({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [pack.color1, pack.color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: pack.color2.withAlpha(128), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(pack.icon, color: Colors.white, size: 32),
              const Spacer(),
              Text(
                pack.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                '${pack.wordCount} kelime',
                style: TextStyle(color: Colors.white.withAlpha(204)),
              ),
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
        ),
      ),
    );
  }
}

class VocabularyPracticeGrid extends StatelessWidget {
  const VocabularyPracticeGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.8,
      children: [
        _buildPracticeCard(title: 'Kelime Kartları', icon: Icons.style_outlined, color: Colors.purple),
        _buildPracticeCard(title: 'Boşluk Doldurma', icon: Icons.edit_note, color: Colors.red),
        _buildPracticeCard(title: 'Dinleme Testi', icon: Icons.video_library_outlined, color: Colors.blue),
        _buildPracticeCard(title: 'Telaffuz', icon: Icons.mic_none_outlined, color: Colors.orange),
      ],
    );
  }

  Widget _buildPracticeCard({required String title, required IconData icon, required MaterialColor color}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: color.withAlpha(77),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color.shade800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}