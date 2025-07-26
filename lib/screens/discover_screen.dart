// lib/screens/discover_screen.dart

import 'package:flutter/material.dart';

// --- Veri Modelleri ---
class Lesson {
  final String title;
  final String level;
  final IconData icon;
  final MaterialColor color;

  const Lesson({required this.title, required this.level, required this.icon, required this.color});
}

// --- Ana Ekran Widget'ı ---

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  // --- Gramer Dersleri Veri Listesi ---
  final List<Lesson> grammarLessons = const [
    // Beginner (A1/A2)
    Lesson(title: 'Present Simple', level: 'A1', icon: Icons.watch_later_outlined, color: Colors.green),
    Lesson(title: 'Past Simple', level: 'A1', icon: Icons.history_edu_outlined, color: Colors.green),
    Lesson(title: 'Articles: a/an/the', level: 'A2', icon: Icons.text_fields_outlined, color: Colors.green),
    Lesson(title: 'Prepositions of Place', level: 'A2', icon: Icons.place_outlined, color: Colors.green),
    // Intermediate (B1/B2)
    Lesson(title: 'Present Perfect', level: 'B1', icon: Icons.check_circle_outline, color: Colors.orange),
    Lesson(title: 'Conditionals (1st & 2nd)', level: 'B1', icon: Icons.help_outline, color: Colors.orange),
    Lesson(title: 'Passive Voice', level: 'B2', icon: Icons.sync_alt_outlined, color: Colors.orange),
    Lesson(title: 'Reported Speech', level: 'B2', icon: Icons.record_voice_over_outlined, color: Colors.orange),
    // Advanced (C1)
    Lesson(title: 'Advanced Conditionals', level: 'C1', icon: Icons.functions_outlined, color: Colors.red),
    Lesson(title: 'Inversion', level: 'C1', icon: Icons.swap_horiz_outlined, color: Colors.red),
    Lesson(title: 'Subjunctive', level: 'C1', icon: Icons.lightbulb_outline, color: Colors.red),
    Lesson(title: 'Cleft Sentences', level: 'C1', icon: Icons.splitscreen_outlined, color: Colors.red),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keşfet'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const TopicOfTheWeekCard(),
          const SizedBox(height: 24),
          const SectionTitle(title: 'Gramer Merkezi'),
          const SizedBox(height: 12),
          GrammarLessonsGrid(lessons: grammarLessons),
          const SizedBox(height: 24),
          const SectionTitle(title: 'Kelime Pratiği'),
          const SizedBox(height: 12),
          const VocabularyPracticeGrid(),
        ],
      ),
    );
  }
}


// --- Özel Widget'lar ---

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

class TopicOfTheWeekCard extends StatelessWidget {
  const TopicOfTheWeekCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.cyan.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withAlpha(77),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Haftanın Konusu', style: TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 4),
          const Text('Teknoloji ve Gelecek', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          const Text(
            'Bu hafta yapay zeka ve geleceğin teknolojileri hakkında sohbet etmeye ne dersin?',
            style: TextStyle(fontSize: 15, color: Colors.white, height: 1.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Kelime Listesine Göz At'),
          )
        ],
      ),
    );
  }
}

class GrammarLessonsGrid extends StatelessWidget {
  final List<Lesson> lessons;
  const GrammarLessonsGrid({super.key, required this.lessons});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: lessons.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: lesson.color.withAlpha(25),
          elevation: 0,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(lesson.icon, color: lesson.color, size: 28),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: lesson.color.withAlpha(50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lesson.level,
                          style: TextStyle(color: lesson.color.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      lesson.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: lesson.color.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        _buildPracticeCard(title: 'Dinleme Testi', icon: Icons.headset_mic_outlined, color: Colors.blue),
        _buildPracticeCard(title: 'Telaffuz', icon: Icons.mic_none_outlined, color: Colors.orange),
      ],
    );
  }

  Widget _buildPracticeCard({required String title, required IconData icon, required Color color}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: color.withAlpha(26),
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
                  style: TextStyle(fontWeight: FontWeight.w600, color: color),
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