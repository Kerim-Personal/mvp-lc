// lib/navigation/lesson_router.dart

import 'package:flutter/material.dart';
import 'package:vocachat/lessons/grammar/a1/verb_to_be.dart';
import 'package:vocachat/lessons/grammar/a1/present_simple.dart';
import 'package:vocachat/lessons/grammar/a1/articles_lesson.dart';
import 'package:vocachat/lessons/grammar/a1/plural_nouns_lesson.dart';
import 'package:vocachat/lessons/grammar/a1/possessive_adjectives_lesson.dart';
import 'package:vocachat/lessons/grammar/a1/demonstratives_lesson.dart';
import 'package:vocachat/lessons/grammar/a1/prepositions_of_place_lesson.dart';
import 'package:vocachat/lessons/grammar/a1/prepositions_of_time_lesson.dart';
import 'package:vocachat/lessons/grammar/a1/can_for_ability_lesson.dart';
import 'package:vocachat/lessons/grammar/a1/past_simple_to_be_lesson.dart';
import 'package:vocachat/lessons/grammar/a1/past_simple_regular_verbs_lesson.dart';
import 'package:vocachat/lessons/grammar/a1/question_words_lesson.dart';
import 'package:vocachat/widgets/grammar/grammar_lesson_wrapper.dart';

// A2 ders importları
import 'package:vocachat/lessons/grammar/a2/present_continuous.dart';
import 'package:vocachat/lessons/grammar/a2/past_simple_irregular.dart';
import 'package:vocachat/lessons/grammar/a2/countable_uncountable.dart';
import 'package:vocachat/lessons/grammar/a2/quantifiers.dart';
import 'package:vocachat/lessons/grammar/a2/comparative_adjectives.dart';
import 'package:vocachat/lessons/grammar/a2/superlative_adjectives.dart';
import 'package:vocachat/lessons/grammar/a2/be_going_to.dart';
import 'package:vocachat/lessons/grammar/a2/adverbs_frequency.dart';
import 'package:vocachat/lessons/grammar/a2/object_pronouns.dart';
import 'package:vocachat/lessons/grammar/a2/verb_ing_infinitive.dart';
import 'package:vocachat/lessons/grammar/a2/present_perfect.dart';
import 'package:vocachat/lessons/grammar/a2/past_continuous.dart';

// B1 ders importları (sadece lesson_data anahtarlarına karşılık gelen ekranlar)
import 'package:vocachat/lessons/grammar/b1/past_perfect_lesson.dart';
import 'package:vocachat/lessons/grammar/b1/future_continuous_lesson.dart';
import 'package:vocachat/lessons/grammar/b1/reported_speech_lesson.dart';
import 'package:vocachat/lessons/grammar/b1/first_conditional_lesson.dart';
import 'package:vocachat/lessons/grammar/b1/second_conditional_lesson.dart';
import 'package:vocachat/lessons/grammar/b1/passive_voice_lesson.dart';
import 'package:vocachat/lessons/grammar/b1/relative_clauses_lesson.dart';
import 'package:vocachat/lessons/grammar/b1/gerunds_infinitives_lesson.dart';
import 'package:vocachat/lessons/grammar/b1/modals_lesson.dart';
import 'package:vocachat/lessons/grammar/b1/used_to_lesson.dart';
import 'package:vocachat/lessons/grammar/b1/present_perfect_continuous_lesson.dart';
import 'package:vocachat/lessons/grammar/b1/phrasal_verbs_intro_lesson.dart';

// B2 ders importları
import 'package:vocachat/lessons/grammar/b2/future_perfect_lesson.dart';
import 'package:vocachat/lessons/grammar/b2/third_conditional_lesson.dart';
import 'package:vocachat/lessons/grammar/b2/mixed_conditionals_lesson.dart';
import 'package:vocachat/lessons/grammar/b2/past_perfect_continuous_lesson.dart';
import 'package:vocachat/lessons/grammar/b2/passive_voice_all_lesson.dart';
import 'package:vocachat/lessons/grammar/b2/reported_speech_all_lesson.dart';
import 'package:vocachat/lessons/grammar/b2/modals_deduction_lesson.dart';
import 'package:vocachat/lessons/grammar/b2/relative_clauses_non_defining_lesson.dart';
import 'package:vocachat/lessons/grammar/b2/wishes_regrets_lesson.dart';
import 'package:vocachat/lessons/grammar/b2/advanced_phrasal_verbs_lesson.dart';
import 'package:vocachat/lessons/grammar/b2/causative_lesson.dart';
import 'package:vocachat/lessons/grammar/b2/participle_clauses_lesson.dart';

// C1 ders importları
import 'package:vocachat/lessons/grammar/c1/inversion_lesson.dart';
import 'package:vocachat/lessons/grammar/c1/cleft_sentences_lesson.dart';
import 'package:vocachat/lessons/grammar/c1/ellipsis_lesson.dart';
import 'package:vocachat/lessons/grammar/c1/advanced_conditionals_lesson.dart';
import 'package:vocachat/lessons/grammar/c1/subjunctive_lesson.dart';
import 'package:vocachat/lessons/grammar/c1/future_in_past_lesson.dart';
import 'package:vocachat/lessons/grammar/c1/discourse_markers_lesson.dart';
import 'package:vocachat/lessons/grammar/c1/advanced_modals_lesson.dart';
import 'package:vocachat/lessons/grammar/c1/collocations_lesson.dart';
import 'package:vocachat/lessons/grammar/c1/idioms_lesson.dart';
import 'package:vocachat/lessons/grammar/c1/hedging_lesson.dart';
import 'package:vocachat/lessons/grammar/c1/nominalization_lesson.dart';

// C2 ders importları
import 'package:vocachat/lessons/grammar/c2/complex_passives_lesson.dart';
import 'package:vocachat/lessons/grammar/c2/emphasis_lesson.dart';
import 'package:vocachat/lessons/grammar/c2/reference_lesson.dart';
import 'package:vocachat/lessons/grammar/c2/cohesion_lesson.dart';
import 'package:vocachat/lessons/grammar/c2/fronting_lesson.dart';
import 'package:vocachat/lessons/grammar/c2/register_tone_lesson.dart';
import 'package:vocachat/lessons/grammar/c2/ambiguity_lesson.dart';
import 'package:vocachat/lessons/grammar/c2/historic_present_lesson.dart';
import 'package:vocachat/lessons/grammar/c2/anticipatory_it_lesson.dart';
import 'package:vocachat/lessons/grammar/c2/pro_forms_lesson.dart';
import 'package:vocachat/lessons/grammar/c2/rhetorical_devices_lesson.dart';
import 'package:vocachat/lessons/grammar/c2/lexical_density_lesson.dart';

// Ders AppBar renk eşlemesi (isteğe bağlı; bulunamazsa tema rengi kullanılır)
const Map<String, Color> _lessonAppBarColors = {
  'a1_verb_to_be': Color(0xFF00695C),
  'a1_present_simple': Color(0xFF303F9F),
  'a1_articles': Color(0xFF7B1FA2),
  'a1_plural_nouns': Color(0xFFF57C00),
  'a1_possessive_adjectives': Color(0xFF455A64),
  'a1_demonstratives': Color(0xFFAFB42B),
  'a1_prepositions_place': Color(0xFF5D4037),
  'a1_prepositions_time': Color(0xFF303F9F),
  'a1_can_for_ability': Color(0xFF00695C),
  'a1_past_simple_to_be': Color(0xFF1976D2),
  'a1_past_simple_regular': Color(0xFF7B1FA2),
  'a1_question_words': Color(0xFF558B2F),
  // A2 ders renkleri
  'a2_present_continuous': Color(0xFF0097A7),
  'a2_past_simple_irregular': Color(0xFF7B1FA2),
  'a2_countable_uncountable': Color(0xFFF57C00),
  'a2_quantifiers': Color(0xFF388E3C),
  'a2_comparative_adjectives': Color(0xFF1976D2),
  'a2_superlative_adjectives': Color(0xFFFF8F00),
  'a2_be_going_to': Color(0xFFC2185B),
  'a2_adverbs_frequency': Color(0xFF00695C),
  'a2_object_pronouns': Color(0xFF303F9F),
  'a2_verb_ing_infinitive': Color(0xFF673AB7),
  'a2_present_perfect': Color(0xFF689F38),
  'a2_past_continuous': Color(0xFF5D4037),
  // B1 (yalnızca lesson_data anahtarları)
  'b1_future_continuous': Color(0xFF0097A7),
  'b1_first_conditional': Color(0xFFAFB42B),
  'b1_second_conditional': Color(0xFF303F9F),
  'b1_present_perfect_continuous': Color(0xFF689F38),
  'b1_past_perfect': Color(0xFF1976D2),
  'b1_passive_voice_simple': Color(0xFF558B2F),
  'b1_reported_speech_statements': Color(0xFF455A64),
  'b1_modals_obligation': Color(0xFFFF8F00),
  'b1_relative_clauses_defining': Color(0xFF673AB7),
  'b1_used_to': Color(0xFF1976D2),
  'b1_phrasal_verbs_intro': Color(0xFF0097A7),
  'b1_gerunds_infinitives': Color(0xFF689F38),
  // C2 ders renkleri (eklendi)
  'c2_pro_forms': Color(0xFF006064),
  'c2_rhetorical_devices': Color(0xFF4E342E),
  'c2_lexical_density': Color(0xFF1B5E20),
};

// Eksik dersler için basit yer tutucu ekran
class _PlaceholderLessonScreen extends StatelessWidget {
  final String title;
  final String contentPath;
  const _PlaceholderLessonScreen({required this.title, required this.contentPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(title, style: const TextStyle(color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.menu_book_outlined),
                            SizedBox(width: 8),
                            Text('Lesson Coming Soon', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Bu ders içeriği yakında eklenecek. (key: '" + contentPath + "')',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8)),
                        ),
                        const SizedBox(height: 12),
                        const Text('Yine de ilerleme için sayfa sonuna kaydırıp Completed olarak işaretleyebilirsin.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 600),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class LessonRouter {
  static Future<void> navigateToLesson(BuildContext context, String contentPath, String lessonTitle) async {
    late Widget screen;
    switch (contentPath) {
      // A1
      case 'a1_verb_to_be':
        screen = const VerbToBeLessonScreen();
        break;
      case 'a1_present_simple':
        screen = const PresentSimpleLessonScreen();
        break;
      case 'a1_articles':
        screen = const ArticlesLessonScreen();
        break;
      case 'a1_plural_nouns':
        screen = const PluralNounsLessonScreen();
        break;
      case 'a1_possessive_adjectives':
        screen = const PossessiveAdjectivesLessonScreen();
        break;
      case 'a1_demonstratives':
        screen = const DemonstrativesLessonScreen();
        break;
      case 'a1_prepositions_place':
        screen = const PrepositionsOfPlaceLessonScreen();
        break;
      case 'a1_prepositions_time':
        screen = const PrepositionsOfTimeLessonScreen();
        break;
      case 'a1_can_for_ability':
        screen = const CanForAbilityLessonScreen();
        break;
      case 'a1_past_simple_to_be':
        screen = const PastSimpleToBeLessonScreen();
        break;
      case 'a1_past_simple_regular':
        screen = const PastSimpleRegularVerbsLessonScreen();
        break;
      case 'a1_question_words':
        screen = const QuestionWordsLessonScreen();
        break;

      // A2
      case 'a2_present_continuous':
        screen = const PresentContinuousLessonScreen();
        break;
      case 'a2_past_simple_irregular':
        screen = const PastSimpleIrregularLessonScreen();
        break;
      case 'a2_countable_uncountable':
        screen = const CountableUncountableLessonScreen();
        break;
      case 'a2_quantifiers':
        screen = const QuantifiersLessonScreen();
        break;
      case 'a2_comparative_adjectives':
        screen = const ComparativeAdjectivesLessonScreen();
        break;
      case 'a2_superlative_adjectives':
        screen = const SuperlativeAdjectivesLessonScreen();
        break;
      case 'a2_be_going_to':
        screen = const BeGoingToLessonScreen();
        break;
      case 'a2_adverbs_frequency':
        screen = const AdverbsFrequencyLessonScreen();
        break;
      case 'a2_object_pronouns':
        screen = const ObjectPronounsLessonScreen();
        break;
      case 'a2_verb_ing_infinitive':
        screen = const VerbIngInfinitiveLessonScreen();
        break;
      case 'a2_present_perfect':
        screen = const PresentPerfectLessonScreen();
        break;
      case 'a2_past_continuous':
        screen = const PastContinuousLessonScreen();
        break;

      // B1 (lesson_data ile birebir 12 ders)
      case 'b1_future_continuous':
        screen = const FutureContinuousLessonScreen();
        break;
      case 'b1_first_conditional':
        screen = const FirstConditionalLessonScreen();
        break;
      case 'b1_second_conditional':
        screen = const SecondConditionalLessonScreen();
        break;
      case 'b1_present_perfect_continuous':
        screen = const PresentPerfectContinuousLessonScreen();
        break;
      case 'b1_past_perfect':
        screen = const PastPerfectLessonScreen();
        break;
      case 'b1_passive_voice_simple':
        screen = const PassiveVoiceLessonScreen();
        break;
      case 'b1_reported_speech_statements':
        screen = const ReportedSpeechLessonScreen();
        break;
      case 'b1_modals_obligation':
        screen = const ModalsLessonScreen();
        break;
      case 'b1_relative_clauses_defining':
        screen = const RelativeClausesLessonScreen();
        break;
      case 'b1_used_to':
        screen = const UsedToLessonScreen();
        break;
      case 'b1_phrasal_verbs_intro':
        screen = const PhrasalVerbsIntroLessonScreen();
        break;
      case 'b1_gerunds_infinitives':
        screen = const GerundsInfinitivesLessonScreen();
        break;

      // B2 (12 ders)
      case 'b2_future_perfect':
        screen = const FuturePerfectLessonScreen();
        break;
      case 'b2_third_conditional':
        screen = const ThirdConditionalLessonScreen();
        break;
      case 'b2_mixed_conditionals':
        screen = const MixedConditionalsLessonScreen();
        break;
      case 'b2_past_perfect_continuous':
        screen = const PastPerfectContinuousLessonScreen();
        break;
      case 'b2_passive_voice_all':
        screen = const PassiveVoiceAllLessonScreen();
        break;
      case 'b2_reported_speech_all':
        screen = const ReportedSpeechAllLessonScreen();
        break;
      case 'b2_modals_deduction':
        screen = const ModalsDeductionLessonScreen();
        break;
      case 'b2_relative_clauses_non_defining':
        screen = const RelativeClausesNonDefiningLessonScreen();
        break;
      case 'b2_wishes_regrets':
        screen = const WishesRegretsLessonScreen();
        break;
      case 'b2_advanced_phrasal_verbs':
        screen = const AdvancedPhrasalVerbsLessonScreen();
        break;
      case 'b2_causative':
        screen = const CausativeLessonScreen();
        break;
      case 'b2_participle_clauses':
        screen = const ParticipleClausesLessonScreen();
        break;

      // C1 (12 ders)
      case 'c1_inversion':
        screen = const InversionLessonScreen();
        break;
      case 'c1_cleft_sentences':
        screen = const CleftSentencesLessonScreen();
        break;
      case 'c1_ellipsis':
        screen = const EllipsisLessonScreen();
        break;
      case 'c1_advanced_conditionals':
        screen = const AdvancedConditionalsLessonScreen();
        break;
      case 'c1_subjunctive':
        screen = const SubjunctiveLessonScreen();
        break;
      case 'c1_future_in_past':
        screen = const FutureInPastLessonScreen();
        break;
      case 'c1_discourse_markers':
        screen = const DiscourseMarkersLessonScreen();
        break;
      case 'c1_advanced_modals':
        screen = const AdvancedModalsLessonScreen();
        break;
      case 'c1_collocations':
        screen = const CollocationsLessonScreen();
        break;
      case 'c1_idioms':
        screen = const IdiomsLessonScreen();
        break;
      case 'c1_hedging':
        screen = const HedgingLessonScreen();
        break;
      case 'c1_nominalization':
        screen = const NominalizationLessonScreen();
        break;

      // C2 (12 ders)
      case 'c2_complex_passives':
        screen = const ComplexPassivesLessonScreen();
        break;
      case 'c2_emphasis':
        screen = const EmphasisLessonScreen();
        break;
      case 'c2_reference':
        screen = const ReferenceLessonScreen();
        break;
      case 'c2_cohesion':
        screen = const CohesionLessonScreen();
        break;
      case 'c2_fronting':
        screen = const FrontingLessonScreen();
        break;
      case 'c2_register_tone':
        screen = const RegisterToneLessonScreen();
        break;
      case 'c2_ambiguity':
        screen = const AmbiguityLessonScreen();
        break;
      case 'c2_historic_present':
        screen = const HistoricPresentLessonScreen();
        break;
      case 'c2_anticipatory_it':
        screen = const AnticipatoryItLessonScreen();
        break;
      case 'c2_pro_forms':
        screen = const ProFormsLessonScreen();
        break;
      case 'c2_rhetorical_devices':
        screen = const RhetoricalDevicesLessonScreen();
        break;
      case 'c2_lexical_density':
        screen = const LexicalDensityLessonScreen();
        break;

      // Bilinmeyen anahtarlar da Placeholder
      default:
        screen = _PlaceholderLessonScreen(title: lessonTitle, contentPath: contentPath);
        break;
    }

    final color = _lessonAppBarColors[contentPath];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GrammarLessonWrapper(
          contentPath: contentPath,
          child: screen,
          appBarColor: color,
        ),
      ),
    );
  }
}