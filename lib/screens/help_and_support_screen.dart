// lib/screens/help_and_support_screen.dart

import 'package:flutter/material.dart';
import 'package:vocachat/screens/faq_category_screen.dart';
import 'package:vocachat/screens/support_request_screen.dart';
import 'package:vocachat/data/faq_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpAndSupportScreen extends StatelessWidget {
  const HelpAndSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = faqData.keys.toList();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildFinalSliverAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < categories.length) {
                    final category = categories[index];
                    return _buildCategoryCard(context, category, index);
                  }
                  return _buildContactSupportSection(context);
                },
                childCount: categories.length + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sade ve tema duyarlı SliverAppBar
  SliverAppBar _buildFinalSliverAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    // Tutarlı renk paleti
    final start = isDark ? cs.primary.withValues(alpha: 0.8) : cs.primary;
    final end = isDark ? cs.primary.withValues(alpha: 0.6) : cs.primary.withValues(alpha: 0.8);
    final titleColor = isDark ? cs.onPrimary : cs.onPrimary;

    return SliverAppBar(
      expandedHeight: 150.0,
      pinned: true,
      backgroundColor: cs.primary,
      elevation: isDark ? 2 : 4,
      iconTheme: IconThemeData(color: cs.onPrimary),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Help Center',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: titleColor,
            fontSize: 18
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [start, end],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  // Tema duyarlı kategori kartları
  Widget _buildCategoryCard(BuildContext context, String category, int index) {
    const categoryIcons = {
      'Uygulamayı Keşfet': Icons.explore_outlined,
      'Hesap ve Profil': Icons.account_circle_outlined,
      'Premium ve Faturalandırma': Icons.star_border_purple500_sharp,
      'Özellikler ve Kullanım': Icons.settings_outlined,
      'Destek ve Yardım': Icons.help_outline,
    };
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final icon = categoryIcons[category] ?? Icons.help_outline;
    final textColor = isDark ? cs.onSurface : const Color(0xFF37474F);
    final arrowColor = textColor.withValues(alpha: 0.7);
    final gradientColors = isDark
        ? [
            cs.surface.withValues(alpha: 0.95),
            cs.surface.withValues(alpha: 0.75),
          ]
        : const [
            Color(0xFFCFD8DC),
            Color(0xFF90A4AE),
          ];

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
        elevation: isDark ? 1.5 : 3.0,
        shadowColor: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.2),
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => FaqCategoryScreen(category: category)));
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: textColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: arrowColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Destek Bölümü tema uyumlu
  Widget _buildContactSupportSection(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final subtle = cs.onSurface.withValues(alpha: 0.65);
    return Card(
      elevation: theme.brightness == Brightness.dark ? 1.5 : 2.0,
      shadowColor: theme.brightness == Brightness.dark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.support_agent, color: cs.primary, size: 32),
            const SizedBox(height: 8),
            Text("Can't find what you need?", textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text('Our support team is happy to help you.', textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: subtle)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        bool isPremium = false;
                        if (user != null) {
                          final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                          isPremium = (snap.data()?['isPremium'] as bool?) == true;
                        }
                        if (isPremium) {
                          // ignore: use_build_context_synchronously
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SupportRequestScreen()));
                        } else {
                          final uri = Uri(
                            scheme: 'mailto',
                            path: 'info@codenzi.com',
                            query: Uri.encodeFull('subject=Support Request&body=Hello support team, here is my issue...'),
                          );
                          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open email app.')));
                          }
                        }
                      } catch (e) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 3,
                    ),
                    child: const Text('Contact Us', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
