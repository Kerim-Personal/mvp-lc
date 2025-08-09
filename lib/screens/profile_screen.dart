// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lingua_chat/services/auth_service.dart';

// Gerekli tüm widget'ları içe aktarıyoruz
import 'package:lingua_chat/widgets/profile_screen/profile_sliver_app_bar.dart';
import 'package:lingua_chat/widgets/profile_screen/section_title.dart';
import 'package:lingua_chat/widgets/profile_screen/stats_grid.dart';
import 'package:lingua_chat/widgets/profile_screen/achievements_section.dart';
import 'package:lingua_chat/widgets/profile_screen/app_settings_card.dart';
import 'package:lingua_chat/widgets/profile_screen/support_card.dart';
import 'package:lingua_chat/widgets/profile_screen/account_management_card.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;
  final AuthService _authService = AuthService();

  late AnimationController _staggeredAnimationController;

  @override
  void initState() {
    super.initState();
    _userStream = FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots();

    _staggeredAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _staggeredAnimationController.forward();
  }

  @override
  void dispose() {
    _staggeredAnimationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedSection({required Widget child, required int index}) {
    final interval = Interval(
      0.1 * index,
      0.6 + 0.1 * index,
      curve: Curves.easeOutCubic,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _staggeredAnimationController, curve: interval)),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _staggeredAnimationController, curve: interval),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Kullanıcı bilgileri yüklenemedi.', style: TextStyle(color: Colors.white)));
          }

          final userData = snapshot.data!.data()!;
          final displayName = userData['displayName'] ?? 'İsimsiz';
          final email = userData['email'] ?? 'E-posta yok';
          final level = userData['level'] ?? '-';
          final memberSince = (userData['createdAt'] as Timestamp?)?.toDate();
          final avatarUrl = userData['avatarUrl'] as String?;
          final streak = userData['streak'] ?? 0;
          final totalPracticeTime = userData['totalPracticeTime'] ?? 0;
          final partnerCount = userData['partnerCount'] ?? 0;
          final isPremium = userData['isPremium'] as bool? ?? false; // YENİ: Premium verisi çekiliyor.

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              ProfileSliverAppBar(
                displayName: displayName,
                email: email,
                avatarUrl: avatarUrl,
                isPremium: isPremium, // YENİ: Premium verisi AppBar'a aktarılıyor.
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _buildAnimatedSection(
                        index: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle('İstatistiklerim'),
                            Transform.translate(
                              offset: const Offset(0, -4.0),
                              child: StatsGrid(
                                level: level,
                                streak: streak,
                                totalPracticeTime: totalPracticeTime,
                                partnerCount: partnerCount,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedSection(
                        index: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle('Kazanılan Rozetler'),
                            const AchievementsSection(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedSection(
                        index: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle('Uygulama Ayarları'),
                            const AppSettingsCard(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedSection(
                        index: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle('Destek'),
                            const SupportCard(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedSection(
                        index: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle('Hesap Yönetimi'),
                            AccountManagementCard(
                              memberSince: memberSince,
                              userId: widget.userId,
                              authService: _authService,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}