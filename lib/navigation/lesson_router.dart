// lib/navigation/lesson_router.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/lessons/grammar/a1/verb_to_be.dart';
import 'package:lingua_chat/lessons/grammar/a1/present_simple.dart';
import 'package:lingua_chat/lessons/grammar/a1/articles_lesson.dart';
import 'package:lingua_chat/lessons/grammar/a1/plural_nouns_lesson.dart';
import 'package:lingua_chat/lessons/grammar/a1/possessive_adjectives_lesson.dart'; // <-- YENİ: Bu satırı ekle

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

    // YENİ: Bu case bloğunu ekle
      case 'a1_possessive_adjectives':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PossessiveAdjectivesLessonScreen()),
        );
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$lessonTitle dersi yakında gelecek!')),
        );
    }
  }
}