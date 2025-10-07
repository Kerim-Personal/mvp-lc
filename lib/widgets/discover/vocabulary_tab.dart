// lib/widgets/discover/vocabulary_tab.dart

import 'package:flutter/material.dart';
import '../../repositories/vocabulary_progress_repository.dart';
import '../../screens/vocabulary_pack_screen.dart';
import '../../services/grammar_progress_service.dart';
import '../../data/vocabulary_level_map.dart';
import '../../data/vocabulary_data_clean.dart';
import '../../data/lesson_data.dart';

class VocabularyPack {
  final String title;
  final IconData icon;
  final Color color1;
  final Color color2;
  final int wordCount;
  final double progress;
  final bool isLocked;
  const VocabularyPack({required this.title, required this.icon, required this.color1, required this.color2, required this.wordCount, required this.progress, required this.isLocked});
}

class VocabularyTab extends StatefulWidget {
  const VocabularyTab({super.key});
  @override
  State<VocabularyTab> createState() => _VocabularyTabState();
}

class _VocabularyTabState extends State<VocabularyTab> {
  // Dinamik kelime sayısı helper
  int wc(String key) => vocabularyDataClean[key]?.length ?? 0;

  // Seviye bazlı ilerlemeler
  Map<String, double> _grammarLevelProgress = {};
  bool _grammarLoading = true;
  Map<String, double> _vocabLevelProgress = {};
  bool _vocabLoading = true;

  @override
  void initState() {
    super.initState();
    // Yerel progress verilerini yükle (lazy init tetiklemek için)
    VocabularyProgressRepository.instance.fetchAllProgress();
    _computeGrammarProgress();
    _computeVocabLevelProgress();
    // Vocab progress değişince seviye özetini güncelle
    VocabularyProgressRepository.instance.progressNotifier.addListener(_computeVocabLevelProgress);
  }

  @override
  void dispose() {
    VocabularyProgressRepository.instance.progressNotifier.removeListener(_computeVocabLevelProgress);
    super.dispose();
  }

  Future<void> _computeGrammarProgress() async {
    final completed = await GrammarProgressService.instance.getCompleted();
    final byLevel = <String, List<String>>{};
    for (final l in grammarLessons) {
      byLevel.putIfAbsent(l.level, () => <String>[]).add(l.contentPath);
    }
    final result = <String, double>{};
    for (final level in cefrLevels) {
      final ids = byLevel[level] ?? const <String>[];
      if (ids.isEmpty) { result[level] = 0.0; continue; }
      final done = ids.where(completed.contains).length;
      result[level] = done / ids.length;
    }
    if (mounted) setState(() { _grammarLevelProgress = result; _grammarLoading = false; });
  }

  Future<void> _computeVocabLevelProgress() async {
    final progressMap = await VocabularyProgressRepository.instance.fetchAllProgress();
    final totals = <String, int>{ for (final l in cefrLevels) l: 0 };
    final learned = <String, int>{ for (final l in cefrLevels) l: 0 };

    vocabularyDataClean.forEach((category, words) {
      final lvl = vocabularyPackLevel[category];
      if (lvl == null) return;
      totals[lvl] = (totals[lvl] ?? 0) + words.length;
      final learnedSet = progressMap[category] ?? const <String>{};
      learned[lvl] = (learned[lvl] ?? 0) + learnedSet.length;
    });

    final result = <String, double>{};
    for (final l in cefrLevels) {
      final t = totals[l] ?? 0;
      final d = learned[l] ?? 0;
      result[l] = t == 0 ? 0.0 : (d / t).clamp(0.0, 1.0);
    }
    if (mounted) setState(() { _vocabLevelProgress = result; _vocabLoading = false; });
  }

  // Sadece görsel/meta bilgileri tutan yapı
  late final List<_PackMeta> _metas = [
    // A1
    _PackMeta('Daily Life', Icons.wb_sunny_outlined, Colors.blue, Colors.lightBlueAccent),
    _PackMeta('Food & Kitchen', Icons.restaurant_menu, Colors.red, Colors.redAccent),
    _PackMeta('Home & Furniture', Icons.weekend_outlined, Colors.brown, Colors.brown.shade300),
    _PackMeta('Family & Relationships', Icons.family_restroom, Colors.pink, Colors.pinkAccent),
    _PackMeta('Sports & Activities', Icons.sports_soccer_outlined, Colors.lightGreen, Colors.greenAccent),
    _PackMeta('Weather & Seasons', Icons.cloud_outlined, Colors.lightBlue, Colors.blueAccent),
    // A2
    _PackMeta('Travel & Tourism', Icons.flight_takeoff, Colors.orange, Colors.deepOrangeAccent),
    _PackMeta('Education & School', Icons.school_outlined, Colors.blue.shade700, Colors.blue.shade900),
    _PackMeta('Emotions & Feelings', Icons.sentiment_satisfied_alt_outlined, Colors.yellow.shade700, Colors.yellow.shade900),
    _PackMeta('Music & Instruments', Icons.music_note_outlined, Colors.deepOrange, Colors.deepOrangeAccent),
    _PackMeta('Health & Fitness', Icons.fitness_center, Colors.green, Colors.lightGreen),
    _PackMeta('Work & Office', Icons.work_outline, Colors.indigo.shade400, Colors.indigo),
    // B1
    _PackMeta('Technology & Software', Icons.computer, Colors.grey.shade600, Colors.blueGrey),
    _PackMeta('Art & Culture', Icons.palette_outlined, Colors.purple, Colors.purpleAccent),
    _PackMeta('Character & Personality', Icons.psychology_outlined, Colors.blueGrey.shade700, Colors.blueGrey.shade900),
    _PackMeta('Nature & Environment', Icons.eco_outlined, Colors.green.shade700, Colors.green.shade900),
    _PackMeta('Phrasal Verbs', Icons.dynamic_feed_outlined, Colors.cyan.shade300, Colors.cyan.shade500),
    _PackMeta('Hobbies & Leisure', Icons.sports_esports_outlined, Colors.teal, Colors.tealAccent),
    // B2
    _PackMeta('Business English', Icons.business_center, Colors.indigo, Colors.indigoAccent),
    _PackMeta('Finance & Economy', Icons.monetization_on_outlined, Colors.teal, Colors.tealAccent),
    _PackMeta('Science & Research', Icons.science_outlined, Colors.cyan, Colors.cyanAccent),
    _PackMeta('History & Mythology', Icons.museum_outlined, Colors.orange.shade800, Colors.orange.shade900),
    _PackMeta('Transportation & Directions', Icons.directions_bus_outlined, Colors.deepPurple, Colors.deepPurpleAccent),
    _PackMeta('Media & Entertainment', Icons.movie_outlined, Colors.redAccent, Colors.deepOrange),
    // C1
    _PackMeta('Marketing & Advertising', Icons.campaign_outlined, Colors.deepPurple, Colors.deepPurpleAccent),
    _PackMeta('Law & Justice', Icons.gavel_outlined, Colors.amber.shade800, Colors.amber.shade900),
    _PackMeta('Idioms', Icons.format_quote_outlined, Colors.indigo.shade300, Colors.indigo.shade500),
    _PackMeta('Slang & Colloquialisms', Icons.sms_outlined, Colors.pink.shade300, Colors.pink.shade500),
    _PackMeta('Academic Skills', Icons.menu_book_outlined, Colors.brown.shade600, Colors.brown.shade400),
    _PackMeta('Debate & Rhetoric', Icons.record_voice_over_outlined, Colors.blueGrey, Colors.blueGrey.shade400),
    // C2
    _PackMeta('IELTS/TOEFL Prep', Icons.assignment_turned_in_outlined, Colors.red.shade800, Colors.red.shade900),
    _PackMeta('Research Methods', Icons.biotech_outlined, Colors.green.shade800, Colors.green.shade400),
    _PackMeta('Philosophy & Ethics', Icons.lightbulb_outline, Colors.blueGrey.shade800, Colors.blueGrey.shade600),
    _PackMeta('Literary Devices', Icons.menu_book_outlined, Colors.deepOrange.shade700, Colors.orange.shade400),
    _PackMeta('Policy & Governance', Icons.account_balance_outlined, Colors.blue.shade800, Colors.blue.shade400),
    _PackMeta('Advanced Science', Icons.science, Colors.purple.shade700, Colors.purple.shade300),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, Set<String>>>(
      valueListenable: VocabularyProgressRepository.instance.progressNotifier,
      builder: (context, progressMap, _) {
        // Önce tüm paket ViewModel'lerini hazırla
        final allPacks = _metas.map((m) {
          final total = wc(m.title);
          final learnedCount = progressMap[m.title]?.length ?? 0;
          final prog = total == 0 ? 0.0 : (learnedCount / total).clamp(0.0, 1.0);
          final level = vocabularyPackLevel[m.title];
          bool locked = false;
          if (level != null && level != 'A1') {
            final prev = previousLevelOf(level);
            final grammarOk = !_grammarLoading && ((_grammarLevelProgress[prev] ?? 0.0) >= 1.0);
            final vocabOk = !_vocabLoading && ((_vocabLevelProgress[prev] ?? 0.0) >= 1.0);
            locked = !(grammarOk && vocabOk);
          }
          return VocabularyPack(
            title: m.title,
            icon: m.icon,
            color1: m.color1,
            color2: m.color2,
            wordCount: total,
            progress: prog,
            isLocked: locked,
          );
        }).toList();

        // CEFR seviyelerine göre grupla ve alfabetik sırala
        final Map<String, List<VocabularyPack>> grouped = {
          for (final l in cefrLevels) l: <VocabularyPack>[]
        };
        for (final p in allPacks) {
          final lvl = vocabularyPackLevel[p.title] ?? 'A1';
          grouped.putIfAbsent(lvl, () => <VocabularyPack>[]).add(p);
        }
        for (final l in grouped.keys) {
          grouped[l]?.sort((a, b) => a.title.compareTo(b.title));
        }

        // Bölüm widget'ları: boş seviyeleri atla, her seviyede en fazla 6 kart göster
        final List<Widget> sections = [];
        for (final level in cefrLevels) {
          final original = grouped[level] ?? const <VocabularyPack>[];
          if (original.isEmpty) continue;
          List<VocabularyPack> displayList = List.of(original);
          if (displayList.length > 6) {
            displayList = displayList.take(6).toList();
          }
          sections.add(
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 12.0, top: 8.0),
              child: SectionTitle(title: '$level Vocabulary'),
            ),
          );
          sections.add(
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: displayList.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => VocabularyPackCard(pack: displayList[index]),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: sections,
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
        if (pack.isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This pack is locked. Complete previous level Grammar and Vocabulary 100% to unlock.')),
          );
          return;
        }
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
            child: Opacity(
              opacity: pack.isLocked ? 0.6 : 1.0,
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
          if (pack.isLocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(Icons.lock, color: Colors.white, size: 40),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
