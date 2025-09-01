// lib/screens/help_and_support_screen.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/screens/faq_category_screen.dart';
import 'package:lingua_chat/screens/support_request_screen.dart';
import 'package:lingua_chat/data/faq_data.dart';
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
                  if (index == 0) {
                    return _buildSectionHeader(context, 'Yardım Konuları');
                  }
                  if (index <= categories.length) {
                    final category = categories[index - 1];
                    return _buildCategoryCard(context, category, index - 1);
                  }
                  return _buildContactSupportSection(context);
                },
                childCount: categories.length + 2,
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
    final start = isDark ? cs.primary.withValues(alpha: 0.35) : Colors.teal.shade400;
    final end = isDark ? cs.secondary.withValues(alpha: 0.35) : Colors.cyan.shade600;
    final titleColor = isDark ? cs.onSurface : Colors.white;
    return SliverAppBar(
      expandedHeight: 150.0,
      pinned: true,
      backgroundColor: isDark ? cs.surface : Colors.teal.shade400,
      elevation: isDark ? 0 : 2,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Yardım Merkezi',
          style: TextStyle(fontWeight: FontWeight.bold, color: titleColor, fontSize: 18),
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

  // Bölüm başlığı tema uyumlu
  Widget _buildSectionHeader(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
      ),
    );
  }

  // Tema duyarlı kategori kartları
  Widget _buildCategoryCard(BuildContext context, String category, int index) {
    const categoryIcons = {
      'Uygulamayı Keşfet': Icons.explore_outlined,
      'Hesap ve Profil': Icons.account_circle_outlined,
      'Güvenlik ve Gizlilik': Icons.shield_outlined,
      'Premium Üyelik ve Ödemeler': Icons.star_border_purple500_sharp,
    };
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final icon = categoryIcons[category] ?? Icons.help_outline;
    final textColor = isDark ? cs.onSurface : const Color(0xFF37474F);
    final arrowColor = textColor.withValues(alpha: 0.7);
    final gradientColors = isDark
        ? [
            cs.surface.withValues(alpha: 0.80),
            cs.surface.withValues(alpha: 0.55),
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
        elevation: isDark ? 1.5 : 4.0,
        shadowColor: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.2),
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => FaqCategoryScreen(category: category)));
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: textColor, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    category,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: textColor,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 18, color: arrowColor),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.support_agent, color: cs.primary, size: 40),
            const SizedBox(height: 12),
            Text('Aradığınızı bulamadınız mı?', textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Destek ekibimiz size yardımcı olmaktan mutluluk duyar.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: subtle)),
            const SizedBox(height: 20),
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
                            query: Uri.encodeFull('subject=Destek Talebi&body=Merhaba destek ekibi, sorunumu burada açıklıyorum...'),
                          );
                          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-posta uygulaması açılamadı.')));
                          }
                        }
                      } catch (e) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('İşlem başarısız: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 4,
                    ),
                    child: const Text('Bize Ulaşın', style: TextStyle(fontWeight: FontWeight.bold)),
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
