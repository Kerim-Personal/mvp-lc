import 'package:flutter/material.dart';

class VocabularyTreasureScreen extends StatelessWidget {
  const VocabularyTreasureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelime Hazinesi'),
        backgroundColor: Colors.green.shade400,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_outlined, size: 80, color: Colors.green),
              SizedBox(height: 20),
              Text(
                "Günün Kelimesi: Serendipity",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Anlamı: Şans eseri, beklenmedik ve değerli bir şey bulma durumu.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black54),
              ),
              SizedBox(height: 20),
              Text(
                'Örnek: "Finding that old book in the library was a moment of pure serendipity."',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}