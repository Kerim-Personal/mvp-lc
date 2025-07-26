import 'package:flutter/material.dart';
import 'package:lingua_chat/screens/vocabulary_treasure_screen.dart';

class VocabularyTreasureCard extends StatelessWidget {
  const VocabularyTreasureCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const VocabularyTreasureScreen()));
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
        child: const Row(
          children: [
            Icon(Icons.menu_book_outlined, color: Colors.white, size: 32),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Kelime Hazinesi",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  SizedBox(height: 4),
                  Text("Günün yeni kelimesini öğren.",
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16)
          ],
        ),
      ),
    );
  }
}