// lib/screens/faq_category_screen.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/data/faq_data.dart';

class FaqCategoryScreen extends StatelessWidget {
  final String category;

  const FaqCategoryScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final List<FaqItem> faqs = faqData[category] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        foregroundColor: Colors.white,
        elevation: 2,
        // AppBar arka planını ana ekranla uyumlu hale getir
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade400, Colors.cyan.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Card(
            elevation: 4.0,
            shadowColor: Colors.black.withOpacity(0.2),
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              // Kart arka planına metalik gradient uygula
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFCFD8DC), // Açık gümüş
                    Color(0xFF90A4AE), // Koyu gümüş
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ExpansionTile(
                key: PageStorageKey(faq.question),
                title: Text(
                  faq.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    // Yazı rengini koyu yaparak okunabilirliği artır
                    color: Color(0xFF37474F),
                  ),
                ),
                // İkon renklerini de yazı rengiyle uyumlu yap
                iconColor: const Color(0xFF37474F),
                collapsedIconColor: const Color(0xFF37474F).withOpacity(0.8),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  Text(
                    faq.answer,
                    style: TextStyle(
                      // Cevap metninin okunabilirliğini artır
                      color: const Color(0xFF37474F).withOpacity(0.9),
                      height: 1.6,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}