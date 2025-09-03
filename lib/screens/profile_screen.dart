// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lingua_chat/services/auth_service.dart';
import 'dart:async';

// Gerekli tüm widget'ları içe aktarıyoruz
import 'package:lingua_chat/widgets/profile_screen/profile_sliver_app_bar.dart';
import 'package:lingua_chat/widgets/profile_screen/section_title.dart';
import 'package:lingua_chat/widgets/profile_screen/stats_grid.dart';
import 'package:lingua_chat/widgets/profile_screen/achievements_section.dart';
import 'package:lingua_chat/widgets/profile_screen/app_settings_card.dart';
import 'package:lingua_chat/widgets/profile_screen/support_card.dart';
import 'package:lingua_chat/widgets/profile_screen/account_management_card.dart';
import 'package:lingua_chat/widgets/profile_screen/admin_panel_card.dart';
import 'package:lingua_chat/widgets/profile_screen/admin_notification_card.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final int replayTrigger; // sekme tekrar açıldığında animasyonu yeniden oynatmak için
  const ProfileScreen({super.key, required this.userId, this.replayTrigger = 0});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  static Map<String, dynamic>? _cachedUserData; // Kalıcı cache (uygulama süresi boyunca)
  Map<String, dynamic>? _userData; // instance cache
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  bool _listening = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Önce varsa cache'i kullan: anında içerik -> flicker yok
    if (_cachedUserData != null) {
      _userData = _cachedUserData;
    }
    _attachListener();
  }

  void _attachListener() {
    if (_listening) return;
    _listening = true;
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;
      // Küçük değişimler için gereksiz rebuild engelle (referans ya da önemli alan farkı)
      if (_cachedUserData != null) {
        final old = _cachedUserData!;
        bool changed = false;
        for (final k in const [
          'displayName','email','avatarUrl','streak','totalPracticeTime','partnerCount','isPremium','role','highestStreak','level'
        ]) {
          if (old[k] != data[k]) { changed = true; break; }
        }
        if (!changed) return; // önemli fark yok
      }
      _cachedUserData = Map<String,dynamic>.from(data);
      if (mounted) setState(() => _userData = _cachedUserData);
      else _userData = _cachedUserData;
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  // Animasyonlu bölüm kaldırıldı; doğrudan child dönen helper
  Widget _section(Widget child) => child;

  @override
  Widget build(BuildContext context) {
    final data = _userData;
    if (data == null) {
      // Hiçbir şey çizme: önceki ekran altından direkt geçiş -> algılanan hız yüksek
      return const SizedBox.shrink();
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildContent(data),
    );
  }

  Widget _buildContent(Map<String, dynamic> userData) {
    final displayName = userData['displayName'] ?? 'Anonymous';
    final email = userData['email'] ?? 'No email';
    final level = userData['level'] ?? '-';
    final memberSince = (userData['createdAt'] as Timestamp?)?.toDate();
    final avatarUrl = userData['avatarUrl'] as String?;
    final streak = userData['streak'] ?? 0;
    final totalPracticeTime = userData['totalPracticeTime'] ?? 0;
    final partnerCount = userData['partnerCount'] ?? 0;
    final isPremium = userData['isPremium'] as bool? ?? false;
    final role = (userData['role'] as String?) ?? 'user';
    final highestStreak = userData['highestStreak'] ?? (streak ?? 0);

    final List<Widget> children = [];

    children.add(_section(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('My Stats'),
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
    )));
    children.add(const SizedBox(height: 16));

    children.add(_section(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionTitle('Earned Badges'),
        AchievementsSection(),
      ],
    )));
    children.add(const SizedBox(height: 16));

    children.add(_section(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionTitle('App Settings'),
        AppSettingsCard(),
      ],
    )));
    children.add(const SizedBox(height: 16));

    children.add(_section(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionTitle('Support'),
        SupportCard(),
      ],
    )));
    children.add(const SizedBox(height: 16));

    children.add(_section(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Account Management'),
        AccountManagementCard(
          memberSince: memberSince,
          userId: widget.userId,
          authService: _authService,
        ),
      ],
    )));

    if (role == 'admin' || role == 'moderator') {
      children.add(const SizedBox(height: 16));
      children.add(_section(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Administration'),
          const AdminPanelCard(),
          if (role == 'admin') const SizedBox(height: 12),
          if (role == 'admin') const AdminNotificationCard(),
        ],
      )));
    }

    return CustomScrollView(
      key: const ValueKey('profile_scroll_v2'),
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
            delegate: SliverChildListDelegate(
              children,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
            ),
          ),
        ),
      ],
    );
  }
}
