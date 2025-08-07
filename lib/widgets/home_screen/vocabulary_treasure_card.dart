// lib/widgets/home_screen/vocabulary_treasure_card.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/models/vocabulary_model.dart'; // Kelime modelini import ediyoruz
import 'package:lingua_chat/screens/vocabulary_treasure_screen.dart';

class VocabularyTreasureCard extends StatelessWidget {
  const VocabularyTreasureCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Her gün için benzersiz kelimeyi seçen algoritma
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final dailyWord = vocabularyList[dayOfYear % vocabularyList.length];

    return InkWell(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => VocabularyTreasureScreen(word: dailyWord)));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade300, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.teal.withAlpha(50),
                  blurRadius: 10,
                  offset: const Offset(0, 5))
            ]),
        child: Row(
          children: [
            const Icon(Icons.menu_book_outlined, color: Colors.white, size: 32),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Kelime Hazinesi",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  const SizedBox(height: 4),
                  // GÜNCELLEME: Artık o günün kelimesini gösteriyor
                  Text("Günün kelimesi: ${dailyWord.word}",
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16)
          ],
        ),
      ),
    );
  }
}