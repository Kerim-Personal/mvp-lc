// lib/screens/challenge_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Panoya kopyalama işlevi için eklendi
import 'package:lingua_chat/models/challenge_model.dart';

class ChallengeScreen extends StatelessWidget {
  final Challenge challenge;

  const ChallengeScreen({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(challenge.title),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.flag_circle_outlined,
                size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            Text(
              challenge.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bu görevi partnerinle sohbet ederken tamamlamaya çalış. Başarılar!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const Divider(height: 48, thickness: 1),
            const Text(
              'Hangi Cümleleri Kullanabilirsin?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal),
            ),
            const SizedBox(height: 16),
            ...challenge.exampleSentences.map((sentence) {
              return Card(
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.1),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  // GÜNCELLEME: Padding ayarlandı.
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16, right: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Icon(Icons.chat_bubble_outline,
                            color: Colors.amber.shade800, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          sentence,
                          style: const TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // YENİ: Kopyala butonu eklendi.
                      IconButton(
                        icon: const Icon(Icons.copy_outlined, size: 22, color: Colors.grey),
                        tooltip: 'Kopyala',
                        onPressed: () {
                          // Metni panoya kopyala
                          Clipboard.setData(ClipboardData(text: sentence));
                          // Kullanıcıya geri bildirim göster
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cümle panoya kopyalandı!'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}