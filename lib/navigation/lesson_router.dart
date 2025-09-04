// lib/navigation/lesson_router.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/lessons/grammar/a1/verb_to_be.dart';
import 'package:lingua_chat/lessons/grammar/a1/present_simple.dart';
import 'package:lingua_chat/lessons/grammar/a1/articles_lesson.dart';
import 'package:lingua_chat/lessons/grammar/a1/plural_nouns_lesson.dart';
import 'package:lingua_chat/lessons/grammar/a1/possessive_adjectives_lesson.dart';
import 'package:lingua_chat/lessons/grammar/a1/demonstratives_lesson.dart';
import 'package:lingua_chat/lessons/grammar/a1/prepositions_of_place_lesson.dart';
import 'package:lingua_chat/lessons/grammar/a1/prepositions_of_time_lesson.dart';
import 'package:lingua_chat/lessons/grammar/a1/can_for_ability_lesson.dart';
import 'package:lingua_chat/lessons/grammar/a1/past_simple_to_be_lesson.dart';
import 'package:lingua_chat/lessons/grammar/a1/past_simple_regular_verbs_lesson.dart';
import 'package:lingua_chat/lessons/grammar/a1/question_words_lesson.dart'; // <-- YENİ: Bu satırı ekle
import 'package:lingua_chat/widgets/grammar/grammar_lesson_wrapper.dart';

// Ders AppBar renk eşlemesi
const Map<String, Color> _lessonAppBarColors = {
  'a1_verb_to_be': Color(0xFF00695C), // Colors.teal.shade700
  'a1_present_simple': Color(0xFF303F9F), // indigo 700
  'a1_articles': Color(0xFF7B1FA2), // purple 700
  'a1_plural_nouns': Color(0xFFF57C00), // orange 700
  'a1_possessive_adjectives': Color(0xFF455A64), // blueGrey 700
  'a1_demonstratives': Color(0xFFAFB42B), // lime 700
  'a1_prepositions_place': Color(0xFF5D4037), // brown 700
  'a1_prepositions_time': Color(0xFF303F9F), // indigo 700
  'a1_can_for_ability': Color(0xFF00695C), // teal 700
  'a1_past_simple_to_be': Color(0xFF1976D2), // blue 700
  'a1_past_simple_regular': Color(0xFF7B1FA2), // purple 700
  'a1_question_words': Color(0xFF558B2F), // lightGreen 700
};

class LessonRouter {
  static Future<void> navigateToLesson(BuildContext context, String contentPath, String lessonTitle) async {
    Widget? screen;
    switch (contentPath) {
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
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$lessonTitle dersi yakında gelecek!')),
        );
    }
    if (screen != null) {
      final color = _lessonAppBarColors[contentPath];
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GrammarLessonWrapper(
            contentPath: contentPath,
            child: screen!,
            appBarColor: color,
          ),
        ),
      );
    }
  }
}