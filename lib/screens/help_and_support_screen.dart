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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildFinalSliverAppBar(),
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

  // Sade ve şık SliverAppBar (Değişiklik yok)
  SliverAppBar _buildFinalSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 150.0,
      pinned: true,
      backgroundColor: Colors.teal.shade400,
      elevation: 2,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'Yardım Merkezi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade400, Colors.cyan.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  // Bölüm başlığı (Değişiklik yok)
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  // GÜNCELLENMİŞ KATEGORİ KARTLARI (Metalik Gümüş Gri)
  Widget _buildCategoryCard(BuildContext context, String category, int index) {
    const categoryIcons = {
      'Uygulamayı Keşfet': Icons.explore_outlined,
      'Hesap ve Profil': Icons.account_circle_outlined,
      'Güvenlik ve Gizlilik': Icons.shield_outlined,
      'Premium Üyelik ve Ödemeler': Icons.star_border_purple500_sharp,
    };

    final icon = categoryIcons[category] ?? Icons.help_outline;

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
        elevation: 4.0,
        shadowColor: Colors.black.withOpacity(0.2),
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
              // Metalik Gümüş Gri Gradient
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFCFD8DC), // Açık gümüş
                  Color(0xFF90A4AE), // Koyu gümüş
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  // Kontrast için koyu renk ikon
                  color: const Color(0xFF37474F),
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      // Kontrast için koyu renk yazı
                      color: Color(0xFF37474F),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  // Kontrast için koyu renk ok
                  color: const Color(0xFF37474F).withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Destek Bölümü (Değişiklik yok)
  Widget _buildContactSupportSection(BuildContext context) {
    return Card(
      elevation: 2.0, shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.support_agent, color: Colors.teal, size: 40),
            const SizedBox(height: 12),
            const Text('Aradığınızı bulamadınız mı?', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Destek ekibimiz size yardımcı olmaktan mutluluk duyar.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Premium kontrolü: Premium ise uygulama içi destek formu, değilse e-posta
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        bool isPremium = false;
                        if (user != null) {
                          final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                          isPremium = (snap.data()?['isPremium'] as bool?) == true;
                        }
                        if (isPremium) {
                          // Uygulama içi destek ekranına git
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
                      backgroundColor: Colors.teal, foregroundColor: Colors.white,
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
