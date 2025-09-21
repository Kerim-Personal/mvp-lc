// lib/screens/faq_category_screen.dart

import 'package:flutter/material.dart';
import 'package:vocachat/data/faq_data.dart';

class FaqCategoryScreen extends StatelessWidget {
  final String category;

  const FaqCategoryScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final List<FaqItem> faqs = faqData[category] ?? [];
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Help and support screen ile tutarlı renk paleti
    final appBarGradientStart = isDark ? cs.primary.withValues(alpha: 0.8) : cs.primary;
    final appBarGradientEnd = isDark ? cs.primary.withValues(alpha: 0.6) : cs.primary.withValues(alpha: 0.8);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          category,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: cs.onPrimary,
            fontSize: 18
          )
        ),
        centerTitle: true,
        elevation: isDark ? 2 : 4,
        iconTheme: IconThemeData(color: cs.onPrimary),
        backgroundColor: cs.primary,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [appBarGradientStart, appBarGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: faqs.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: faqs.length,
              itemBuilder: (context, index) {
                final faq = faqs[index];
                final questionColor = isDark ? cs.onSurface : const Color(0xFF37474F);
                final answerColor = isDark ? cs.onSurface.withValues(alpha: 0.85) : const Color(0xFF37474F).withValues(alpha: 0.9);
                final iconColor = questionColor;
                final gradientColors = isDark
                    ? [
                        cs.surface.withValues(alpha: 0.95),
                        cs.surface.withValues(alpha: 0.80),
                      ]
                    : const [
                        Color(0xFFCFD8DC),
                        Color(0xFF90A4AE),
                      ];
                return Card(
                  elevation: isDark ? 1.5 : 4.0,
                  shadowColor: isDark ? Colors.black.withValues(alpha: 0.45) : Colors.black.withValues(alpha: 0.2),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Theme(
                      // ExpansionTile renklerinin koyu temada surface etkisini bozmasını engelle
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        key: PageStorageKey(faq.question),
                        title: Text(
                          faq.question,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: questionColor,
                          ),
                        ),
                        iconColor: iconColor,
                        collapsedIconColor: iconColor.withValues(alpha: 0.8),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        children: [
                          Text(
                            faq.answer,
                            style: TextStyle(
                              color: answerColor,
                              height: 1.55,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help_outline, size: 72, color: cs.onSurface.withValues(alpha: 0.35)),
          const SizedBox(height: 16),
          Text('Bu kategoride içerik bulunamadı.', style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.8))),
          const SizedBox(height: 8),
          Text('Yakında yeni içerikler eklenecek.', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}