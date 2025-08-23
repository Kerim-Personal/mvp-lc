// lib/widgets/discover/vocabulary_tab.dart

import 'package:flutter/material.dart';
import '../../screens/vocabulary_pack_screen.dart';

class VocabularyPack {
  final String title;
  final IconData icon;
  final Color color1;
  final Color color2;
  final int wordCount;
  final double progress;
  const VocabularyPack({required this.title, required this.icon, required this.color1, required this.color2, required this.wordCount, required this.progress});
}

class VocabularyTab extends StatelessWidget {
  VocabularyTab({super.key});

  // Paket listesi, vocabulary_data.dart ile uyumlu olacak şekilde tamamen güncellendi.
  final List<VocabularyPack> vocabularyPacks = [
    // --- TEMEL VE GÜNLÜK KONULAR ---
    VocabularyPack(title: 'Daily Life', icon: Icons.wb_sunny_outlined, color1: Colors.blue, color2: Colors.lightBlueAccent, wordCount: 10, progress: 1.0),
    VocabularyPack(title: 'Food & Kitchen', icon: Icons.restaurant_menu, color1: Colors.red, color2: Colors.redAccent, wordCount: 10, progress: 0.65),
    VocabularyPack(title: 'Travel & Tourism', icon: Icons.flight_takeoff, color1: Colors.orange, color2: Colors.deepOrangeAccent, wordCount: 10, progress: 0.30),
    VocabularyPack(title: 'Family & Relationships', icon: Icons.family_restroom, color1: Colors.pink, color2: Colors.pinkAccent, wordCount: 10, progress: 1.0),
    VocabularyPack(title: 'Health & Fitness', icon: Icons.fitness_center, color1: Colors.green, color2: Colors.lightGreen, wordCount: 10, progress: 0.80),
    VocabularyPack(title: 'Home & Furniture', icon: Icons.weekend_outlined, color1: Colors.brown, color2: Colors.brown.shade300, wordCount: 10, progress: 1.0),

    // --- İŞ VE KARİYER ---
    VocabularyPack(title: 'Business English', icon: Icons.business_center, color1: Colors.indigo, color2: Colors.indigoAccent, wordCount: 10, progress: 0.50),
    VocabularyPack(title: 'Finance & Economy', icon: Icons.monetization_on_outlined, color1: Colors.teal, color2: Colors.tealAccent, wordCount: 10, progress: 1.0),
    VocabularyPack(title: 'Marketing & Advertising', icon: Icons.campaign_outlined, color1: Colors.deepPurple, color2: Colors.deepPurpleAccent, wordCount: 10, progress: 0.25),
    VocabularyPack(title: 'Technology & Software', icon: Icons.computer, color1: Colors.grey.shade600, color2: Colors.blueGrey, wordCount: 10, progress: 1.0),

    // --- EĞİTİM VE AKADEMİK ---
    VocabularyPack(title: 'Education & School', icon: Icons.school_outlined, color1: Colors.blue.shade700, color2: Colors.blue.shade900, wordCount: 10, progress: 1.0),
    VocabularyPack(title: 'Science & Research', icon: Icons.science_outlined, color1: Colors.cyan, color2: Colors.cyanAccent, wordCount: 10, progress: 0.0),
    VocabularyPack(title: 'Law & Justice', icon: Icons.gavel_outlined, color1: Colors.amber.shade800, color2: Colors.amber.shade900, wordCount: 10, progress: 1.0),
    VocabularyPack(title: 'IELTS/TOEFL Prep', icon: Icons.assignment_turned_in_outlined, color1: Colors.red.shade800, color2: Colors.red.shade900, wordCount: 10, progress: 0.15),

    // --- HOBİLER VE İLGİ ALANLARI ---
    VocabularyPack(title: 'Art & Culture', icon: Icons.palette_outlined, color1: Colors.purple, color2: Colors.purpleAccent, wordCount: 10, progress: 1.0),
    VocabularyPack(title: 'Music & Instruments', icon: Icons.music_note_outlined, color1: Colors.deepOrange, color2: Colors.deepOrangeAccent, wordCount: 10, progress: 1.0),
    VocabularyPack(title: 'Sports & Activities', icon: Icons.sports_soccer_outlined, color1: Colors.lightGreen, color2: Colors.greenAccent, wordCount: 10, progress: 0.90),
    VocabularyPack(title: 'Nature & Environment', icon: Icons.eco_outlined, color1: Colors.green.shade700, color2: Colors.green.shade900, wordCount: 10, progress: 1.0),
    VocabularyPack(title: 'History & Mythology', icon: Icons.museum_outlined, color1: Colors.orange.shade800, color2: Colors.orange.shade900, wordCount: 10, progress: 0.0),

    // --- SOYUT KAVRAMLAR VE DİL BİLGİSİ ---
    VocabularyPack(title: 'Emotions & Feelings', icon: Icons.sentiment_satisfied_alt_outlined, color1: Colors.yellow.shade700, color2: Colors.yellow.shade900, wordCount: 10, progress: 1.0),
    VocabularyPack(title: 'Character & Personality', icon: Icons.psychology_outlined, color1: Colors.blueGrey.shade700, color2: Colors.blueGrey.shade900, wordCount: 10, progress: 0.40),
    VocabularyPack(title: 'Idioms', icon: Icons.format_quote_outlined, color1: Colors.indigo.shade300, color2: Colors.indigo.shade500, wordCount: 10, progress: 0.0),
    VocabularyPack(title: 'Phrasal Verbs', icon: Icons.dynamic_feed_outlined, color1: Colors.cyan.shade300, color2: Colors.cyan.shade500, wordCount: 10, progress: 0.0),
    VocabularyPack(title: 'Slang & Colloquialisms', icon: Icons.sms_outlined, color1: Colors.pink.shade300, color2: Colors.pink.shade500, wordCount: 10, progress: 1.0),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 16.0),
          child: SectionTitle(title: 'Thematic Vocabulary Packs'),
        ),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
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

class VocabularyPackCard extends StatelessWidget {
  final VocabularyPack pack;
  const VocabularyPackCard({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    bool isCompleted = pack.progress >= 1.0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VocabularyPackScreen(pack: pack),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [pack.color1, pack.color2], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: pack.color2.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(pack.icon, color: Colors.white.withOpacity(0.9), size: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GÜNCELLEME: Başlığın tek satıra sığması için FittedBox eklendi.
                    SizedBox(
                      height: 40, // Tüm başlıkların aynı yüksekliği kaplaması için
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          pack.title,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${pack.wordCount} words',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                        ),
                        if (!isCompleted && pack.progress > 0)
                          Text(
                            '${(pack.progress * 100).toInt()}%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: pack.progress,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isCompleted)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.white, size: 24),
              ),
            ),
        ],
      ),
    );
  }
}
