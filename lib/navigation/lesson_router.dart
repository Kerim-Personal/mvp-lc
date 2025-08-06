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

class LessonRouter {
  static void navigateToLesson(BuildContext context, String contentPath, String lessonTitle) {
    switch (contentPath) {
      case 'a1_verb_to_be':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VerbToBeLessonScreen()),
        );
        break;

      case 'a1_present_simple':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PresentSimpleLessonScreen()),
        );
        break;

      case 'a1_articles':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ArticlesLessonScreen()),
        );
        break;

      case 'a1_plural_nouns':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PluralNounsLessonScreen()),
        );
        break;

      case 'a1_possessive_adjectives':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PossessiveAdjectivesLessonScreen()),
        );
        break;

      case 'a1_demonstratives':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DemonstrativesLessonScreen()),
        );
        break;

      case 'a1_prepositions_place':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PrepositionsOfPlaceLessonScreen()),
        );
        break;

      case 'a1_prepositions_time':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PrepositionsOfTimeLessonScreen()),
        );
        break;

      case 'a1_can_for_ability':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CanForAbilityLessonScreen()),
        );
        break;

      case 'a1_past_simple_to_be':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PastSimpleToBeLessonScreen()),
        );
        break;

      case 'a1_past_simple_regular':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PastSimpleRegularVerbsLessonScreen()),
        );
        break;

    // YENİ: Bu case bloğunu ekle
      case 'a1_question_words':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QuestionWordsLessonScreen()),
        );
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$lessonTitle dersi yakında gelecek!')),
        );
    }
  }
}