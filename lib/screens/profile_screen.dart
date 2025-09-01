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
import 'package:lingua_chat/widgets/profile_screen/admin_panel_card.dart';

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

  Widget _buildAnimatedSection({required Widget child, required int index, Key? key}) {
    // Dinamik ve güvenli aralık hesaplama: end 1.0'ı geçmesin, start < end olsun
    double start = 0.1 * index; // artışlı başlangıç
    double end = 0.6 + 0.1 * index; // önceki mantık
    if (end > 1.0) end = 1.0; // clamp
    if (start >= end) {
      // Çok son öğelerde çakışmayı engellemek için küçük bir fark bırak
      start = (end - 0.05).clamp(0.0, 0.95);
    }
    final interval = Interval(start, end, curve: Curves.easeOutCubic);

    return SlideTransition(
      key: key,
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
          final role = (userData['role'] as String?) ?? 'user';
          final highestStreak = userData['highestStreak'] ?? (streak ?? 0);

          // --- Yeni: Dinamik listeyi önce oluştur ---
          int animIndex = 0;
          final List<Widget> children = [];

          children.add(_buildAnimatedSection(
            key: const ValueKey('section_stats'),
            index: animIndex++,
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
                    highestStreak: highestStreak is int ? highestStreak : 0,
                  ),
                ),
              ],
            ),
          ));
          children.add(const SizedBox(key: ValueKey('gap_1'), height: 16));

          children.add(_buildAnimatedSection(
            key: const ValueKey('section_achievements'),
            index: animIndex++,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Kazanılan Rozetler'),
                const AchievementsSection(),
              ],
            ),
          ));
          children.add(const SizedBox(key: ValueKey('gap_2'), height: 16));

          children.add(_buildAnimatedSection(
            key: const ValueKey('section_settings'),
            index: animIndex++,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Uygulama Ayarları'),
                const AppSettingsCard(),
              ],
            ),
          ));
          children.add(const SizedBox(key: ValueKey('gap_3'), height: 16));

          children.add(_buildAnimatedSection(
            key: const ValueKey('section_support'),
            index: animIndex++,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Destek'),
                const SupportCard(),
              ],
            ),
          ));
          children.add(const SizedBox(key: ValueKey('gap_4'), height: 16));

          children.add(_buildAnimatedSection(
            key: const ValueKey('section_account'),
            index: animIndex++,
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
          ));

          if (role == 'admin' || role == 'moderator') {
            children.add(const SizedBox(key: ValueKey('gap_admin'), height: 16));
            children.add(_buildAnimatedSection(
              key: const ValueKey('section_admin'),
              index: animIndex++,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SectionTitle('Yönetim'),
                  AdminPanelCard(),
                ],
              ),
            ));
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              ProfileSliverAppBar(
                displayName: displayName,
                email: email,
                avatarUrl: avatarUrl,
                isPremium: isPremium,
                role: role,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(children, addAutomaticKeepAlives: false, addRepaintBoundaries: true),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}