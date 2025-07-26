// lib/widgets/discover/grammar_tab.dart

import 'package:flutter/material.dart';

// --- Veri Modeli ---
class Lesson {
  final String title;
  final String level;
  final IconData icon;
  final MaterialColor color;
  const Lesson(
      {required this.title,
        required this.level,
        required this.icon,
        required this.color});
}

// --- Gramer Sekmesi Ana Widget'ı ---
class GrammarTab extends StatelessWidget {
  GrammarTab({super.key});

  // --- EKSİKSİZ VE TAM GRAMER KONULARI LİSTESİ ---
  final List<Lesson> grammarLessons = const [
    // A1 Level
    Lesson(title: 'Verb "to be" (am/is/are)', level: 'A1', icon: Icons.person_outline, color: Colors.green),
    Lesson(title: 'Present Simple', level: 'A1', icon: Icons.watch_later_outlined, color: Colors.green),
    Lesson(title: 'Articles (a/an/the)', level: 'A1', icon: Icons.text_fields_outlined, color: Colors.green),
    Lesson(title: 'Plural Nouns', level: 'A1', icon: Icons.group_add_outlined, color: Colors.green),
    Lesson(title: 'Possessive Adjectives', level: 'A1', icon: Icons.key_outlined, color: Colors.green),
    Lesson(title: 'Demonstratives', level: 'A1', icon: Icons.arrow_forward_outlined, color: Colors.green),
    Lesson(title: 'Prepositions of Place', level: 'A1', icon: Icons.place_outlined, color: Colors.green),
    Lesson(title: 'Prepositions of Time', level: 'A1', icon: Icons.access_time_outlined, color: Colors.green),
    Lesson(title: '"Can" for Ability', level: 'A1', icon: Icons.sports_kabaddi, color: Colors.green),
    Lesson(title: 'Past Simple ("to be")', level: 'A1', icon: Icons.history_edu_outlined, color: Colors.green),
    Lesson(title: 'Past Simple (Regular Verbs)', level: 'A1', icon: Icons.replay_outlined, color: Colors.green),
    Lesson(title: 'Question Words', level: 'A1', icon: Icons.quiz_outlined, color: Colors.green),

    // A2 Level
    Lesson(title: 'Present Continuous', level: 'A2', icon: Icons.directions_run_outlined, color: Colors.lightBlue),
    Lesson(title: 'Past Simple (Irregular Verbs)', level: 'A2', icon: Icons.cached_outlined, color: Colors.lightBlue),
    Lesson(title: 'Countable/Uncountable Nouns', level: 'A2', icon: Icons.format_list_numbered_outlined, color: Colors.lightBlue),
    Lesson(title: 'Quantifiers (some/any/much/many)', level: 'A2', icon: Icons.unfold_more_outlined, color: Colors.lightBlue),
    Lesson(title: 'Comparative Adjectives', level: 'A2', icon: Icons.compare_arrows_outlined, color: Colors.lightBlue),
    Lesson(title: 'Superlative Adjectives', level: 'A2', icon: Icons.military_tech_outlined, color: Colors.lightBlue),
    Lesson(title: '"Be Going To" for Future', level: 'A2', icon: Icons.event_outlined, color: Colors.lightBlue),
    Lesson(title: 'Adverbs of Frequency', level: 'A2', icon: Icons.repeat_outlined, color: Colors.lightBlue),
    Lesson(title: 'Object Pronouns', level: 'A2', icon: Icons.group_outlined, color: Colors.lightBlue),
    Lesson(title: 'Verb + -ing/infinitive', level: 'A2', icon: Icons.settings_ethernet_outlined, color: Colors.lightBlue),
    Lesson(title: 'Present Perfect', level: 'A2', icon: Icons.check_circle_outline, color: Colors.lightBlue),
    Lesson(title: 'Past Continuous', level: 'A2', icon: Icons.history_toggle_off_outlined, color: Colors.lightBlue),

    // B1 Level
    Lesson(title: 'Future Continuous', level: 'B1', icon: Icons.hourglass_bottom_outlined, color: Colors.orange),
    Lesson(title: 'First Conditional', level: 'B1', icon: Icons.filter_1_outlined, color: Colors.orange),
    Lesson(title: 'Second Conditional', level: 'B1', icon: Icons.filter_2_outlined, color: Colors.orange),
    Lesson(title: 'Present Perfect Continuous', level: 'B1', icon: Icons.all_inclusive_outlined, color: Colors.orange),
    Lesson(title: 'Past Perfect', level: 'B1', icon: Icons.double_arrow_outlined, color: Colors.orange),
    Lesson(title: 'Passive Voice (Simple Tenses)', level: 'B1', icon: Icons.sync_alt_outlined, color: Colors.orange),
    Lesson(title: 'Reported Speech (Statements)', level: 'B1', icon: Icons.record_voice_over_outlined, color: Colors.orange),
    Lesson(title: 'Modals of Obligation/Permission', level: 'B1', icon: Icons.gavel_outlined, color: Colors.orange),
    Lesson(title: 'Relative Clauses (Defining)', level: 'B1', icon: Icons.link_outlined, color: Colors.orange),
    Lesson(title: 'Used To', level: 'B1', icon: Icons.history, color: Colors.orange),
    Lesson(title: 'Phrasal Verbs (Introduction)', level: 'B1', icon: Icons.extension_outlined, color: Colors.orange),
    Lesson(title: 'Gerunds and Infinitives', level: 'B1', icon: Icons.looks_one_outlined, color: Colors.orange),

    // B2 Level
    Lesson(title: 'Future Perfect', level: 'B2', icon: Icons.event_available_outlined, color: Colors.deepOrange),
    Lesson(title: 'Third Conditional', level: 'B2', icon: Icons.filter_3_outlined, color: Colors.deepOrange),
    Lesson(title: 'Mixed Conditionals', level: 'B2', icon: Icons.shuffle_outlined, color: Colors.deepOrange),
    Lesson(title: 'Past Perfect Continuous', level: 'B2', icon: Icons.timelapse_outlined, color: Colors.deepOrange),
    Lesson(title: 'Passive Voice (All Tenses)', level: 'B2', icon: Icons.sync_problem_outlined, color: Colors.deepOrange),
    Lesson(title: 'Reported Speech (All forms)', level: 'B2', icon: Icons.voice_over_off_outlined, color: Colors.deepOrange),
    Lesson(title: 'Modals of Deduction', level: 'B2', icon: Icons.lightbulb_outline, color: Colors.deepOrange),
    Lesson(title: 'Relative Clauses (Non-Defining)', level: 'B2', icon: Icons.link_off_outlined, color: Colors.deepOrange),
    Lesson(title: 'Wishes and Regrets', level: 'B2', icon: Icons.sentiment_dissatisfied_outlined, color: Colors.deepOrange),
    Lesson(title: 'Advanced Phrasal Verbs', level: 'B2', icon: Icons.widgets_outlined, color: Colors.deepOrange),
    Lesson(title: 'Causative (have/get something done)', level: 'B2', icon: Icons.build_circle_outlined, color: Colors.deepOrange),
    Lesson(title: 'Participle Clauses', level: 'B2', icon: Icons.format_quote_outlined, color: Colors.deepOrange),

    // C1 Level
    Lesson(title: 'Inversion', level: 'C1', icon: Icons.swap_horiz_outlined, color: Colors.red),
    Lesson(title: 'Cleft Sentences', level: 'C1', icon: Icons.splitscreen_outlined, color: Colors.red),
    Lesson(title: 'Ellipsis', level: 'C1', icon: Icons.more_horiz_outlined, color: Colors.red),
    Lesson(title: 'Advanced Conditionals', level: 'C1', icon: Icons.functions_outlined, color: Colors.red),
    Lesson(title: 'Subjunctive', level: 'C1', icon: Icons.recommend_outlined, color: Colors.red),
    Lesson(title: 'Future in the Past', level: 'C1', icon: Icons.update_outlined, color: Colors.red),
    Lesson(title: 'Discourse Markers', level: 'C1', icon: Icons.low_priority_outlined, color: Colors.red),
    Lesson(title: 'Advanced Modal Verbs', level: 'C1', icon: Icons.policy_outlined, color: Colors.red),
    Lesson(title: 'Collocations', level: 'C1', icon: Icons.grain_outlined, color: Colors.red),
    Lesson(title: 'Idiomatic Expressions', level: 'C1', icon: Icons.emoji_emotions_outlined, color: Colors.red),
    Lesson(title: 'Hedging and Vague Language', level: 'C1', icon: Icons.blur_on_outlined, color: Colors.red),
    Lesson(title: 'Nominalization', level: 'C1', icon: Icons.font_download_outlined, color: Colors.red),

    // C2 Level
    Lesson(title: 'Complex Passives', level: 'C2', icon: Icons.transform_outlined, color: Colors.purple),
    Lesson(title: 'Emphasis Structures', level: 'C2', icon: Icons.priority_high_outlined, color: Colors.purple),
    Lesson(title: 'Anaphoric/Cataphoric Reference', level: 'C2', icon: Icons.mediation_outlined, color: Colors.purple),
    Lesson(title: 'Cohesion and Coherence', level: 'C2', icon: Icons.linear_scale_outlined, color: Colors.purple),
    Lesson(title: 'Fronting and End-weight', level: 'C2', icon: Icons.format_align_justify_outlined, color: Colors.purple),
    Lesson(title: 'Register and Tone', level: 'C2', icon: Icons.campaign_outlined, color: Colors.purple),
    Lesson(title: 'Syntactic Ambiguity', level: 'C2', icon: Icons.help_center_outlined, color: Colors.purple),
    Lesson(title: 'Historic Present', level: 'C2', icon: Icons.auto_stories_outlined, color: Colors.purple),
    Lesson(title: 'Anticipatory "it"', level: 'C2', icon: Icons.lightbulb_circle_outlined, color: Colors.purple),
    Lesson(title: 'Pro-forms and Substitution', level: 'C2', icon: Icons.find_replace_outlined, color: Colors.purple),
    Lesson(title: 'Rhetorical Devices', level: 'C2', icon: Icons.theater_comedy_outlined, color: Colors.purple),
    Lesson(title: 'Lexical Density', level: 'C2', icon: Icons.data_usage_outlined, color: Colors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    // Dersleri seviyelerine göre grupla
    final Map<String, List<Lesson>> lessonsByLevel = {};
    for (var lesson in grammarLessons) {
      lessonsByLevel.putIfAbsent(lesson.level, () => []).add(lesson);
    }
    final levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final levelColors = [ Colors.green, Colors.lightBlue, Colors.orange, Colors.deepOrange, Colors.red, Colors.purple ];

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.9,
      ),
      itemCount: levels.length,
      itemBuilder: (context, index) {
        final level = levels[index];
        final lessonsInLevel = lessonsByLevel[level] ?? [];
        return LevelCard(
          level: level,
          lessonCount: lessonsInLevel.length,
          color: levelColors[index],
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => GrammarLevelScreen(
                      level: level,
                      lessons: lessonsInLevel,
                      color: levelColors[index]))),
        );
      },
    );
  }
}

// Seviye Kartı Widget'ı
class LevelCard extends StatelessWidget {
  final String level;
  final int lessonCount;
  final MaterialColor color;
  final VoidCallback onTap;

  const LevelCard(
      {super.key,
        required this.level,
        required this.lessonCount,
        required this.color,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color.shade300, color.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(level,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(blurRadius: 10, color: Colors.black26)])),
            const SizedBox(height: 8),
            Text('$lessonCount Konu',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// Gramer Detay Sayfası
class GrammarLevelScreen extends StatelessWidget {
  final String level;
  final List<Lesson> lessons;
  final MaterialColor color;

  const GrammarLevelScreen(
      {super.key,
        required this.level,
        required this.lessons,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$level Gramer Konuları'),
        backgroundColor: color.shade400,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: lessons.length,
        itemBuilder: (context, index) {
          final lesson = lessons[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(lesson.icon, color: lesson.color),
              title: Text(lesson.title),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}