// lib/widgets/discover/vocabulary_tab.dart

import 'package:flutter/material.dart';
import '../../data/vocabulary_data.dart';
import '../../data/vocabulary_data_clean.dart';
import '../../repositories/vocabulary_progress_repository.dart';
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

class VocabularyTab extends StatefulWidget {
  const VocabularyTab({super.key});
  @override
  State<VocabularyTab> createState() => _VocabularyTabState();
}

class _VocabularyTabState extends State<VocabularyTab> {
  // Dinamik kelime sayısı helper
  int wc(String key) => vocabularyDataClean[key]?.length ?? 0;

  @override
  void initState() {
    super.initState();
    // Yerel progress verilerini yükle (lazy init tetiklemek için)
    VocabularyProgressRepository.instance.fetchAllProgress();
  }

  // Sadece görsel/meta bilgileri tutan yapı
  late final List<_PackMeta> _metas = [
    _PackMeta('Daily Life', Icons.wb_sunny_outlined, Colors.blue, Colors.lightBlueAccent),
    _PackMeta('Food & Kitchen', Icons.restaurant_menu, Colors.red, Colors.redAccent),
    _PackMeta('Travel & Tourism', Icons.flight_takeoff, Colors.orange, Colors.deepOrangeAccent),
    _PackMeta('Family & Relationships', Icons.family_restroom, Colors.pink, Colors.pinkAccent),
    _PackMeta('Health & Fitness', Icons.fitness_center, Colors.green, Colors.lightGreen),
    _PackMeta('Home & Furniture', Icons.weekend_outlined, Colors.brown, Colors.brown.shade300),
    _PackMeta('Business English', Icons.business_center, Colors.indigo, Colors.indigoAccent),
    _PackMeta('Finance & Economy', Icons.monetization_on_outlined, Colors.teal, Colors.tealAccent),
    _PackMeta('Marketing & Advertising', Icons.campaign_outlined, Colors.deepPurple, Colors.deepPurpleAccent),
    _PackMeta('Technology & Software', Icons.computer, Colors.grey.shade600, Colors.blueGrey),
    _PackMeta('Education & School', Icons.school_outlined, Colors.blue.shade700, Colors.blue.shade900),
    _PackMeta('Science & Research', Icons.science_outlined, Colors.cyan, Colors.cyanAccent),
    _PackMeta('Law & Justice', Icons.gavel_outlined, Colors.amber.shade800, Colors.amber.shade900),
    _PackMeta('IELTS/TOEFL Prep', Icons.assignment_turned_in_outlined, Colors.red.shade800, Colors.red.shade900),
    _PackMeta('Art & Culture', Icons.palette_outlined, Colors.purple, Colors.purpleAccent),
    _PackMeta('Music & Instruments', Icons.music_note_outlined, Colors.deepOrange, Colors.deepOrangeAccent),
    _PackMeta('Sports & Activities', Icons.sports_soccer_outlined, Colors.lightGreen, Colors.greenAccent),
    _PackMeta('Nature & Environment', Icons.eco_outlined, Colors.green.shade700, Colors.green.shade900),
    _PackMeta('History & Mythology', Icons.museum_outlined, Colors.orange.shade800, Colors.orange.shade900),
    _PackMeta('Emotions & Feelings', Icons.sentiment_satisfied_alt_outlined, Colors.yellow.shade700, Colors.yellow.shade900),
    _PackMeta('Character & Personality', Icons.psychology_outlined, Colors.blueGrey.shade700, Colors.blueGrey.shade900),
    _PackMeta('Idioms', Icons.format_quote_outlined, Colors.indigo.shade300, Colors.indigo.shade500),
    _PackMeta('Phrasal Verbs', Icons.dynamic_feed_outlined, Colors.cyan.shade300, Colors.cyan.shade500),
    _PackMeta('Slang & Colloquialisms', Icons.sms_outlined, Colors.pink.shade300, Colors.pink.shade500),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, Set<String>>>(
      valueListenable: VocabularyProgressRepository.instance.progressNotifier,
      builder: (context, progressMap, _) {
        final packs = _metas.map((m) {
          final total = wc(m.title);
          final learnedCount = progressMap[m.title]?.length ?? 0;
          final prog = total == 0 ? 0.0 : (learnedCount / total).clamp(0.0, 1.0);
          return VocabularyPack(
            title: m.title,
            icon: m.icon,
            color1: m.color1,
            color2: m.color2,
            wordCount: total,
            progress: prog,
          );
        }).toList();

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
              itemCount: packs.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => VocabularyPackCard(pack: packs[index]),
            ),
          ],
        );
      },
    );
  }
}

class _PackMeta {
  final String title; final IconData icon; final Color color1; final Color color2;
  _PackMeta(this.title, this.icon, this.color1, this.color2);
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Text(
      title,
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface.withValues(alpha: 0.9)),
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
              boxShadow: [BoxShadow(color: pack.color2.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(pack.icon, color: Colors.white.withValues(alpha: 0.9), size: 32),
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
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
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
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.8)),
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
                  color: Colors.white.withValues(alpha: 0.25),
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
