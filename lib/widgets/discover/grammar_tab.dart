// lib/widgets/discover/grammar_tab.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/lessons/grammar/a1/verb_to_be.dart';
import 'package:lingua_chat/navigation/lesson_router.dart';

// --- VERİ MODELLERİ ---

class Lesson {
  final String title;
  final String level;
  final IconData icon;
  final MaterialColor color;
  final String contentPath; // Her dersin kendi dosyasına yönlendirme yapmak için eklendi.

  const Lesson({
    required this.title,
    required this.level,
    required this.icon,
    required this.color,
    required this.contentPath,
  });
}

// --- GRAMER SEKMESİ ANA WIDGET'I (YENİDEN TASARLANDI) ---
class GrammarTab extends StatelessWidget {
  GrammarTab({super.key});

  // Not: Bu ders listesini ve kullanıcı ilerlemesini normalde bir veritabanından (örn. Firestore) çekmeniz gerekir.
  // Bu örnekte veriler statik olarak tanımlanmıştır.
  // Her bir derse, ilgili ders dosyasını temsil eden benzersiz bir 'contentPath' eklendi.
  final List<Lesson> grammarLessons = const [
    // A1 Level
    Lesson(title: 'Verb "to be" (am/is/are)', level: 'A1', icon: Icons.person_outline, color: Colors.green, contentPath: 'a1_verb_to_be'),
    Lesson(title: 'Present Simple', level: 'A1', icon: Icons.watch_later_outlined, color: Colors.green, contentPath: 'a1_present_simple'),
    Lesson(title: 'Articles (a/an/the)', level: 'A1', icon: Icons.text_fields_outlined, color: Colors.green, contentPath: 'a1_articles'),
    Lesson(title: 'Plural Nouns', level: 'A1', icon: Icons.group_add_outlined, color: Colors.green, contentPath: 'a1_plural_nouns'),
    Lesson(title: 'Possessive Adjectives', level: 'A1', icon: Icons.key_outlined, color: Colors.green, contentPath: 'a1_possessive_adjectives'),
    Lesson(title: 'Demonstratives', level: 'A1', icon: Icons.arrow_forward_outlined, color: Colors.green, contentPath: 'a1_demonstratives'),
    Lesson(title: 'Prepositions of Place', level: 'A1', icon: Icons.place_outlined, color: Colors.green, contentPath: 'a1_prepositions_place'),
    Lesson(title: 'Prepositions of Time', level: 'A1', icon: Icons.access_time_outlined, color: Colors.green, contentPath: 'a1_prepositions_time'),
    Lesson(title: '"Can" for Ability', level: 'A1', icon: Icons.sports_kabaddi, color: Colors.green, contentPath: 'a1_can_for_ability'),
    Lesson(title: 'Past Simple ("to be")', level: 'A1', icon: Icons.history_edu_outlined, color: Colors.green, contentPath: 'a1_past_simple_to_be'),
    Lesson(title: 'Past Simple (Regular Verbs)', level: 'A1', icon: Icons.replay_outlined, color: Colors.green, contentPath: 'a1_past_simple_regular'),
    Lesson(title: 'Question Words', level: 'A1', icon: Icons.quiz_outlined, color: Colors.green, contentPath: 'a1_question_words'),

    // A2 Level
    Lesson(title: 'Present Continuous', level: 'A2', icon: Icons.directions_run_outlined, color: Colors.lightBlue, contentPath: 'a2_present_continuous'),
    Lesson(title: 'Past Simple (Irregular Verbs)', level: 'A2', icon: Icons.cached_outlined, color: Colors.lightBlue, contentPath: 'a2_past_simple_irregular'),
    Lesson(title: 'Countable/Uncountable Nouns', level: 'A2', icon: Icons.format_list_numbered_outlined, color: Colors.lightBlue, contentPath: 'a2_countable_uncountable'),
    Lesson(title: 'Quantifiers (some/any/much/many)', level: 'A2', icon: Icons.unfold_more_outlined, color: Colors.lightBlue, contentPath: 'a2_quantifiers'),
    Lesson(title: 'Comparative Adjectives', level: 'A2', icon: Icons.compare_arrows_outlined, color: Colors.lightBlue, contentPath: 'a2_comparative_adjectives'),
    Lesson(title: 'Superlative Adjectives', level: 'A2', icon: Icons.military_tech_outlined, color: Colors.lightBlue, contentPath: 'a2_superlative_adjectives'),
    Lesson(title: '"Be Going To" for Future', level: 'A2', icon: Icons.event_outlined, color: Colors.lightBlue, contentPath: 'a2_be_going_to'),
    Lesson(title: 'Adverbs of Frequency', level: 'A2', icon: Icons.repeat_outlined, color: Colors.lightBlue, contentPath: 'a2_adverbs_frequency'),
    Lesson(title: 'Object Pronouns', level: 'A2', icon: Icons.group_outlined, color: Colors.lightBlue, contentPath: 'a2_object_pronouns'),
    Lesson(title: 'Verb + -ing/infinitive', level: 'A2', icon: Icons.settings_ethernet_outlined, color: Colors.lightBlue, contentPath: 'a2_verb_ing_infinitive'),
    Lesson(title: 'Present Perfect', level: 'A2', icon: Icons.check_circle_outline, color: Colors.lightBlue, contentPath: 'a2_present_perfect'),
    Lesson(title: 'Past Continuous', level: 'A2', icon: Icons.history_toggle_off_outlined, color: Colors.lightBlue, contentPath: 'a2_past_continuous'),

    // B1 Level
    Lesson(title: 'Future Continuous', level: 'B1', icon: Icons.hourglass_bottom_outlined, color: Colors.orange, contentPath: 'b1_future_continuous'),
    Lesson(title: 'First Conditional', level: 'B1', icon: Icons.filter_1_outlined, color: Colors.orange, contentPath: 'b1_first_conditional'),
    Lesson(title: 'Second Conditional', level: 'B1', icon: Icons.filter_2_outlined, color: Colors.orange, contentPath: 'b1_second_conditional'),
    Lesson(title: 'Present Perfect Continuous', level: 'B1', icon: Icons.all_inclusive_outlined, color: Colors.orange, contentPath: 'b1_present_perfect_continuous'),
    Lesson(title: 'Past Perfect', level: 'B1', icon: Icons.double_arrow_outlined, color: Colors.orange, contentPath: 'b1_past_perfect'),
    Lesson(title: 'Passive Voice (Simple Tenses)', level: 'B1', icon: Icons.sync_alt_outlined, color: Colors.orange, contentPath: 'b1_passive_voice_simple'),
    Lesson(title: 'Reported Speech (Statements)', level: 'B1', icon: Icons.record_voice_over_outlined, color: Colors.orange, contentPath: 'b1_reported_speech_statements'),
    Lesson(title: 'Modals of Obligation/Permission', level: 'B1', icon: Icons.gavel_outlined, color: Colors.orange, contentPath: 'b1_modals_obligation'),
    Lesson(title: 'Relative Clauses (Defining)', level: 'B1', icon: Icons.link_outlined, color: Colors.orange, contentPath: 'b1_relative_clauses_defining'),
    Lesson(title: 'Used To', level: 'B1', icon: Icons.history, color: Colors.orange, contentPath: 'b1_used_to'),
    Lesson(title: 'Phrasal Verbs (Introduction)', level: 'B1', icon: Icons.extension_outlined, color: Colors.orange, contentPath: 'b1_phrasal_verbs_intro'),
    Lesson(title: 'Gerunds and Infinitives', level: 'B1', icon: Icons.looks_one_outlined, color: Colors.orange, contentPath: 'b1_gerunds_infinitives'),

    // B2 Level
    Lesson(title: 'Future Perfect', level: 'B2', icon: Icons.event_available_outlined, color: Colors.deepOrange, contentPath: 'b2_future_perfect'),
    Lesson(title: 'Third Conditional', level: 'B2', icon: Icons.filter_3_outlined, color: Colors.deepOrange, contentPath: 'b2_third_conditional'),
    Lesson(title: 'Mixed Conditionals', level: 'B2', icon: Icons.shuffle_outlined, color: Colors.deepOrange, contentPath: 'b2_mixed_conditionals'),
    Lesson(title: 'Past Perfect Continuous', level: 'B2', icon: Icons.timelapse_outlined, color: Colors.deepOrange, contentPath: 'b2_past_perfect_continuous'),
    Lesson(title: 'Passive Voice (All Tenses)', level: 'B2', icon: Icons.sync_problem_outlined, color: Colors.deepOrange, contentPath: 'b2_passive_voice_all'),
    Lesson(title: 'Reported Speech (All forms)', level: 'B2', icon: Icons.voice_over_off_outlined, color: Colors.deepOrange, contentPath: 'b2_reported_speech_all'),
    Lesson(title: 'Modals of Deduction', level: 'B2', icon: Icons.lightbulb_outline, color: Colors.deepOrange, contentPath: 'b2_modals_deduction'),
    Lesson(title: 'Relative Clauses (Non-Defining)', level: 'B2', icon: Icons.link_off_outlined, color: Colors.deepOrange, contentPath: 'b2_relative_clauses_non_defining'),
    Lesson(title: 'Wishes and Regrets', level: 'B2', icon: Icons.sentiment_dissatisfied_outlined, color: Colors.deepOrange, contentPath: 'b2_wishes_regrets'),
    Lesson(title: 'Advanced Phrasal Verbs', level: 'B2', icon: Icons.widgets_outlined, color: Colors.deepOrange, contentPath: 'b2_advanced_phrasal_verbs'),
    Lesson(title: 'Causative (have/get something done)', level: 'B2', icon: Icons.build_circle_outlined, color: Colors.deepOrange, contentPath: 'b2_causative'),
    Lesson(title: 'Participle Clauses', level: 'B2', icon: Icons.format_quote_outlined, color: Colors.deepOrange, contentPath: 'b2_participle_clauses'),

    // C1 Level
    Lesson(title: 'Inversion', level: 'C1', icon: Icons.swap_horiz_outlined, color: Colors.red, contentPath: 'c1_inversion'),
    Lesson(title: 'Cleft Sentences', level: 'C1', icon: Icons.splitscreen_outlined, color: Colors.red, contentPath: 'c1_cleft_sentences'),
    Lesson(title: 'Ellipsis', level: 'C1', icon: Icons.more_horiz_outlined, color: Colors.red, contentPath: 'c1_ellipsis'),
    Lesson(title: 'Advanced Conditionals', level: 'C1', icon: Icons.functions_outlined, color: Colors.red, contentPath: 'c1_advanced_conditionals'),
    Lesson(title: 'Subjunctive', level: 'C1', icon: Icons.recommend_outlined, color: Colors.red, contentPath: 'c1_subjunctive'),
    Lesson(title: 'Future in the Past', level: 'C1', icon: Icons.update_outlined, color: Colors.red, contentPath: 'c1_future_in_past'),
    Lesson(title: 'Discourse Markers', level: 'C1', icon: Icons.low_priority_outlined, color: Colors.red, contentPath: 'c1_discourse_markers'),
    Lesson(title: 'Advanced Modal Verbs', level: 'C1', icon: Icons.policy_outlined, color: Colors.red, contentPath: 'c1_advanced_modals'),
    Lesson(title: 'Collocations', level: 'C1', icon: Icons.grain_outlined, color: Colors.red, contentPath: 'c1_collocations'),
    Lesson(title: 'Idiomatic Expressions', level: 'C1', icon: Icons.emoji_emotions_outlined, color: Colors.red, contentPath: 'c1_idioms'),
    Lesson(title: 'Hedging and Vague Language', level: 'C1', icon: Icons.blur_on_outlined, color: Colors.red, contentPath: 'c1_hedging'),
    Lesson(title: 'Nominalization', level: 'C1', icon: Icons.font_download_outlined, color: Colors.red, contentPath: 'c1_nominalization'),

    // C2 Level
    Lesson(title: 'Complex Passives', level: 'C2', icon: Icons.transform_outlined, color: Colors.purple, contentPath: 'c2_complex_passives'),
    Lesson(title: 'Emphasis Structures', level: 'C2', icon: Icons.priority_high_outlined, color: Colors.purple, contentPath: 'c2_emphasis'),
    Lesson(title: 'Anaphoric/Cataphoric Reference', level: 'C2', icon: Icons.mediation_outlined, color: Colors.purple, contentPath: 'c2_reference'),
    Lesson(title: 'Cohesion and Coherence', level: 'C2', icon: Icons.linear_scale_outlined, color: Colors.purple, contentPath: 'c2_cohesion'),
    Lesson(title: 'Fronting and End-weight', level: 'C2', icon: Icons.format_align_justify_outlined, color: Colors.purple, contentPath: 'c2_fronting'),
    Lesson(title: 'Register and Tone', level: 'C2', icon: Icons.campaign_outlined, color: Colors.purple, contentPath: 'c2_register_tone'),
    Lesson(title: 'Syntactic Ambiguity', level: 'C2', icon: Icons.help_center_outlined, color: Colors.purple, contentPath: 'c2_ambiguity'),
    Lesson(title: 'Historic Present', level: 'C2', icon: Icons.auto_stories_outlined, color: Colors.purple, contentPath: 'c2_historic_present'),
    Lesson(title: 'Anticipatory "it"', level: 'C2', icon: Icons.lightbulb_circle_outlined, color: Colors.purple, contentPath: 'c2_anticipatory_it'),
    Lesson(title: 'Pro-forms and Substitution', level: 'C2', icon: Icons.find_replace_outlined, color: Colors.purple, contentPath: 'c2_pro_forms'),
    Lesson(title: 'Rhetorical Devices', level: 'C2', icon: Icons.theater_comedy_outlined, color: Colors.purple, contentPath: 'c2_rhetorical_devices'),
    Lesson(title: 'Lexical Density', level: 'C2', icon: Icons.data_usage_outlined, color: Colors.purple, contentPath: 'c2_lexical_density'),
  ];

  // Örnek kullanıcı ilerlemesi. Bu veriyi Firestore'dan veya başka bir state management çözümüyle yönetmelisiniz.
  final Map<String, double> userProgress = const {
    'A1': 1.0,   // %100 tamamlandı
    'A2': 0.75,  // %75 tamamlandı
    'B1': 0.33,  // %33 tamamlandı
    'B2': 0.0,
    'C1': 0.0,
    'C2': 0.0,
  };

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Lesson>> lessonsByLevel = {};
    for (var lesson in grammarLessons) {
      lessonsByLevel.putIfAbsent(lesson.level, () => []).add(lesson);
    }
    final levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final levelColors = [
      Colors.green, Colors.lightBlue, Colors.orange,
      Colors.deepOrange, Colors.red, Colors.purple
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      itemCount: levels.length,
      itemBuilder: (context, index) {
        final level = levels[index];
        final lessonsInLevel = lessonsByLevel[level] ?? [];
        final progress = userProgress[level] ?? 0.0;
        final isLocked = (index > 0) && ((userProgress[levels[index - 1]] ?? 0.0) < 1.0);

        return LevelPathNode(
          level: level,
          lessonCount: lessonsInLevel.length,
          color: levelColors[index],
          progress: progress,
          isLocked: isLocked,
          isLeftAligned: index.isEven,
          onTap: isLocked ? null : () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GrammarLevelScreen(
                  level: level,
                  lessons: lessonsInLevel,
                  color: levelColors[index]
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- PATİKA DÜĞÜMÜ (HER SEVİYE İÇİN) ---
class LevelPathNode extends StatelessWidget {
  final String level;
  final int lessonCount;
  final Color color;
  final double progress;
  final bool isLocked;
  final bool isLeftAligned;
  final VoidCallback? onTap;

  const LevelPathNode({
    super.key,
    required this.level,
    required this.lessonCount,
    required this.color,
    required this.progress,
    required this.isLocked,
    required this.isLeftAligned,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Row(
        mainAxisAlignment: isLeftAligned ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isLeftAligned) const Spacer(),
          Column(
            crossAxisAlignment: isLeftAligned ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLocked
                          ? [Colors.grey.shade500, Colors.grey.shade600]
                          : [(color as MaterialColor).shade300, (color as MaterialColor).shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      if (!isLocked)
                        BoxShadow(
                          color: color.withAlpha((0.4 * 255).round()), // withOpacity(0.4)
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                    ],
                  ),
                  child: Column(
                    children: [
                      if (isLocked)
                        Icon(Icons.lock_outline, color: Colors.white.withAlpha((0.8 * 255).round()), size: 48)
                      else
                        Text(
                          level,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              shadows: [Shadow(blurRadius: 10, color: Colors.black26)]
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '$lessonCount Konu',
                        style: TextStyle(
                          color: Colors.white.withAlpha((0.9 * 255).round()),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (!isLocked)
                Container(
                  width: 180,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        progress == 1.0 ? Icons.check_circle : Icons.hourglass_empty,
                        color: progress == 1.0 ? Colors.green.shade700 : Colors.grey.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      )
                    ],
                  ),
                ),
            ],
          ),
          if (isLeftAligned) const Spacer(),
        ],
      ),
    );
  }
}


// --- GRAMER SEVİYE DETAY SAYFASI ---
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
    // Örnek tamamlanmış dersler (Bunu da Firestore'dan almalısınız)
    final Set<String> completedLessons = {'Verb "to be" (am/is/are)', 'Present Simple', 'Present Continuous'};

    return Scaffold(
      appBar: AppBar(
        title: Text('$level Gramer Konuları'),
        backgroundColor: color.shade400,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: lessons.length,
        itemBuilder: (context, index) {
          final lesson = lessons[index];
          final isCompleted = completedLessons.contains(lesson.title);
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            elevation: 2,
            shadowColor: Colors.black.withAlpha((0.1 * 255).round()),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isCompleted ? color.withAlpha((0.9 * 255).round()) : Colors.grey.shade200,
                child: Icon(
                  isCompleted ? Icons.check : lesson.icon,
                  color: isCompleted ? Colors.white : lesson.color,
                ),
                foregroundColor: Colors.white,
              ),
              title: Text(
                lesson.title,
                style: TextStyle(
                    decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                    color: isCompleted ? Colors.grey.shade600 : Colors.black87,
                    fontWeight: isCompleted ? FontWeight.normal : FontWeight.w600
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey),
              onTap: () {
                // Yönlendirme için merkezi LessonRouter'ı kullan
                LessonRouter.navigateToLesson(context, lesson.contentPath, lesson.title);
              },
            ),
          );
        },
      ),
    );
  }
}