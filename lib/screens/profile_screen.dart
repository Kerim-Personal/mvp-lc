// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lingua_chat/services/auth_service.dart';

// Yeni widget'larımızı import ediyoruz
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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _userStream = FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Kullanıcı bilgileri yüklenemedi.'));
          }

          final userData = snapshot.data!.data()!;
          final displayName = userData['displayName'] ?? 'İsimsiz';
          final email = userData['email'] ?? 'E-posta yok';
          final level = userData['level'] ?? 'Belirlenmemiş';
          final memberSince = (userData['createdAt'] as Timestamp?)?.toDate();
          final avatarUrl = userData['avatarUrl'] as String?;

          return CustomScrollView(
            slivers: [
              ProfileSliverAppBar(
                displayName: displayName,
                email: email,
                avatarUrl: avatarUrl,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle('İstatistiklerim'),
                          StatsGrid(level: level),
                          const SectionTitle('Rozetler'),
                          const AchievementsSection(),
                          const SectionTitle('Uygulama Ayarları'),
                          const AppSettingsCard(),
                          const SectionTitle('Destek'),
                          const SupportCard(),
                          const SectionTitle('Hesap Yönetimi'),
                          AccountManagementCard(
                            memberSince: memberSince,
                            userId: widget.userId,
                            authService: _authService,
                          ),
                        ],
                      ),
                    ),
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