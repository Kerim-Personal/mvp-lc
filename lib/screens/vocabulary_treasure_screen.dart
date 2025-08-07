// lib/screens/vocabulary_treasure_screen.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/models/vocabulary_model.dart';
import 'package:flutter_tts/flutter_tts.dart'; // YENİ: Seslendirme paketi import edildi

// GÜNCELLEME: Widget, ses motorunu yönetebilmek için StatefulWidget'a dönüştürüldü.
class VocabularyTreasureScreen extends StatefulWidget {
  final VocabularyWord word;

  const VocabularyTreasureScreen({super.key, required this.word});

  @override
  State<VocabularyTreasureScreen> createState() =>
      _VocabularyTreasureScreenState();
}

class _VocabularyTreasureScreenState extends State<VocabularyTreasureScreen> {
  // YENİ: FlutterTts nesnesi oluşturuldu.
  late FlutterTts flutterTts;
  bool isTtsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  // YENİ: Metin okuma motorunu başlatan fonksiyon.
  void _initializeTts() {
    flutterTts = FlutterTts();
    // Dil ve konuşma hızını ayarlıyoruz.
    flutterTts.setLanguage("en-US");
    flutterTts.setSpeechRate(0.5); // Daha anlaşılır olması için biraz yavaş.
    flutterTts.setPitch(1.0);
  }

  // YENİ: Kelimeyi seslendiren fonksiyon.
  Future<void> _speak() async {
    await flutterTts.speak(widget.word.word);
  }

  @override
  void dispose() {
    // Sayfa kapatıldığında motoru durduruyoruz.
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Günün Kelimesi'),
        backgroundColor: Colors.green.shade400,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withAlpha(26),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 60, color: Colors.green),
                    const SizedBox(height: 20),
                    // GÜNCELLEME: Kelime ve telaffuz butonu bir satıra alındı.
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            widget.word.word,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // YENİ: Telaffuz butonu eklendi.
                        IconButton(
                          icon: Icon(Icons.volume_up,
                              color: Colors.grey.shade600),
                          iconSize: 30,
                          tooltip: 'Telaffuz Et',
                          onPressed: _speak,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.word.phonetic,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildInfoCard(
                icon: Icons.translate_rounded,
                title: 'Anlamı',
                content: widget.word.meaning,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.format_quote_rounded,
                title: 'Örnek Cümle',
                content: widget.word.exampleSentence,
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      {required IconData icon,
        required String title,
        required String content,
        required Color color}) {
    return Card(
      elevation: 0,
      color: color.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withAlpha(51)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.lerp(color, Colors.black, 0.4)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withAlpha(179),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}