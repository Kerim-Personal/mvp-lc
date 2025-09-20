// lib/data/lesson_data.dart

import 'package:flutter/material.dart';
import 'package:vocachat/models/lesson_model.dart';

const List<Lesson> grammarLessons = [
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