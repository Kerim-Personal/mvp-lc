// lib/widgets/discover/vocabulary_tab.dart

import 'package:flutter/material.dart';

// Veri Modeli
class VocabularyPack {
  final String title;
  final IconData icon;
  final Color color1;
  final Color color2;
  final int wordCount;
  final double progress;
  const VocabularyPack({required this.title, required this.icon, required this.color1, required this.color2, required this.wordCount, required this.progress});
}

// Kelime Sekmesi Ana Widget'ı
class VocabularyTab extends StatelessWidget {
  VocabularyTab({super.key});

  final List<VocabularyPack> vocabularyPacks = [
    // --- TEMEL VE GÜNLÜK KONULAR ---
    VocabularyPack(title: 'Günlük Hayat', icon: Icons.wb_sunny_outlined, color1: Colors.blue, color2: Colors.lightBlueAccent, wordCount: 100, progress: 0.6),
    VocabularyPack(title: 'Yemek & Mutfak', icon: Icons.restaurant_menu, color1: Colors.red, color2: Colors.redAccent, wordCount: 80, progress: 0.9),
    VocabularyPack(title: 'Seyahat & Turizm', icon: Icons.flight_takeoff, color1: Colors.orange, color2: Colors.deepOrangeAccent, wordCount: 120, progress: 0.3),
    VocabularyPack(title: 'Aile & İlişkiler', icon: Icons.family_restroom, color1: Colors.pink, color2: Colors.pinkAccent, wordCount: 70, progress: 0.0),
    VocabularyPack(title: 'Sağlık & Fitness', icon: Icons.fitness_center, color1: Colors.green, color2: Colors.lightGreen, wordCount: 90, progress: 0.1),
    VocabularyPack(title: 'Ev & Mobilya', icon: Icons.weekend_outlined, color1: Colors.brown, color2: Colors.brown.shade300, wordCount: 60, progress: 0.0),

    // --- İŞ VE KARİYER ---
    VocabularyPack(title: 'İş İngilizcesi', icon: Icons.business_center, color1: Colors.indigo, color2: Colors.indigoAccent, wordCount: 150, progress: 0.75),
    VocabularyPack(title: 'Finans & Ekonomi', icon: Icons.monetization_on_outlined, color1: Colors.teal, color2: Colors.tealAccent, wordCount: 100, progress: 0.0),
    VocabularyPack(title: 'Pazarlama & Reklam', icon: Icons.campaign_outlined, color1: Colors.deepPurple, color2: Colors.deepPurpleAccent, wordCount: 80, progress: 0.0),
    VocabularyPack(title: 'Teknoloji & Yazılım', icon: Icons.computer, color1: Colors.grey.shade600, color2: Colors.blueGrey, wordCount: 130, progress: 0.0),

    // --- EĞİTİM VE AKADEMİK ---
    VocabularyPack(title: 'Eğitim & Okul', icon: Icons.school_outlined, color1: Colors.blue.shade700, color2: Colors.blue.shade900, wordCount: 90, progress: 0.0),
    VocabularyPack(title: 'Bilim & Araştırma', icon: Icons.science_outlined, color1: Colors.cyan, color2: Colors.cyanAccent, wordCount: 110, progress: 0.0),
    VocabularyPack(title: 'Hukuk & Adalet', icon: Icons.gavel_outlined, color1: Colors.amber.shade800, color2: Colors.amber.shade900, wordCount: 70, progress: 0.0),
    VocabularyPack(title: 'IELTS/TOEFL Hazırlık', icon: Icons.assignment_turned_in_outlined, color1: Colors.red.shade800, color2: Colors.red.shade900, wordCount: 200, progress: 0.0),

    // --- HOBİLER VE İLGİ ALANLARI ---
    VocabularyPack(title: 'Sanat & Kültür', icon: Icons.palette_outlined, color1: Colors.purple, color2: Colors.purpleAccent, wordCount: 80, progress: 0.0),
    VocabularyPack(title: 'Müzik & Enstrümanlar', icon: Icons.music_note_outlined, color1: Colors.deepOrange, color2: Colors.deepOrangeAccent, wordCount: 70, progress: 0.0),
    VocabularyPack(title: 'Spor & Aktiviteler', icon: Icons.sports_soccer_outlined, color1: Colors.lightGreen, color2: Colors.greenAccent, wordCount: 100, progress: 0.0),
    VocabularyPack(title: 'Doğa & Çevre', icon: Icons.eco_outlined, color1: Colors.green.shade700, color2: Colors.green.shade900, wordCount: 90, progress: 0.0),
    VocabularyPack(title: 'Tarih & Mitoloji', icon: Icons.museum_outlined, color1: Colors.orange.shade800, color2: Colors.orange.shade900, wordCount: 120, progress: 0.0),

    // --- SOYUT KAVRAMLAR VE DİL BİLGİSİ ---
    VocabularyPack(title: 'Duygular & Hisler', icon: Icons.sentiment_satisfied_alt_outlined, color1: Colors.yellow.shade700, color2: Colors.yellow.shade900, wordCount: 60, progress: 0.0),
    VocabularyPack(title: 'Karakter & Kişilik', icon: Icons.psychology_outlined, color1: Colors.blueGrey.shade700, color2: Colors.blueGrey.shade900, wordCount: 80, progress: 0.0),
    VocabularyPack(title: 'Deyimler (Idioms)', icon: Icons.format_quote_outlined, color1: Colors.indigo.shade300, color2: Colors.indigo.shade500, wordCount: 150, progress: 0.0),
    VocabularyPack(title: 'Phrasal Verbs', icon: Icons.dynamic_feed_outlined, color1: Colors.cyan.shade300, color2: Colors.cyan.shade500, wordCount: 180, progress: 0.0),
    VocabularyPack(title: 'Argo & Günlük Konuşma', icon: Icons.sms_outlined, color1: Colors.pink.shade300, color2: Colors.pink.shade500, wordCount: 100, progress: 0.0),
  ];


  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const SectionTitle(title: 'Tematik Kelime Paketleri'),
        const SizedBox(height: 16),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.9,
          ),
          itemCount: vocabularyPacks.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) => VocabularyPackCard(pack: vocabularyPacks[index]),
        ),
      ],
    );
  }
}

// Bölüm Başlığı
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }
}

// Kelime Paketi Kartı
class VocabularyPackCard extends StatelessWidget {
  final VocabularyPack pack;
  const VocabularyPackCard({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pack.title} kelime paketi yakında sizlerle!')),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [pack.color1, pack.color2], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          // OPTİMİZASYON: `withAlpha` yerine daha performanslı olan `withOpacity` kullanıldı.
          boxShadow: [BoxShadow(color: pack.color2.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(pack.icon, color: Colors.white, size: 36),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    pack.title,
                    softWrap: true,
                    overflow: TextOverflow.fade,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  // OPTİMİZASYON: `withAlpha` yerine daha performanslı olan `withOpacity` kullanıldı.
                  Text('${pack.wordCount} kelime', style: TextStyle(color: Colors.white.withOpacity(0.9))),
                  const SizedBox(height: 8),
                  if (pack.progress > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: pack.progress,
                        // OPTİMİZASYON: `withAlpha` yerine daha performanslı olan `withOpacity` kullanıldı.
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}