// lib/navigation/lesson_router.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/lessons/grammar/a1/verb_to_be.dart';

class LessonRouter {
  static void navigateToLesson(BuildContext context, String contentPath, String lessonTitle) {
    // contentPath'e göre ilgili ders sayfasını bul ve aç
    switch (contentPath) {
      case 'a1_verb_to_be':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VerbToBeLessonScreen()),
        );
        break;

    // YENİ DERSLERİ BURAYA EKLEYEBİLİRSİNİZ
    // case 'a1_present_simple':
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(builder: (context) => const PresentSimpleLessonScreen()),
    //   );
    //   break;

      default:
      // Eğer eşleşen bir ders yoksa "yakında gelecek" mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$lessonTitle dersi yakında gelecek!')),
        );
    }
  }
}