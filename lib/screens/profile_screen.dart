// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/screens/edit_profile_screen.dart';
// DEĞİŞİKLİK: LoginScreen import'u artık gerekli değil.
// import 'package:lingua_chat/screens/login_screen.dart';
import 'package:lingua_chat/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;
  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true;

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

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(displayName, email),
              _buildAnimatedProfileContent(level, memberSince),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(String displayName, String email) {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.teal,
      elevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          var top = constraints.biggest.height;
          return FlexibleSpaceBar(
            centerTitle: true,
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: top <= kToolbarHeight + 40 ? 1.0 : 0.0,
              child: Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade400, Colors.cyan.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color.fromARGB(230, 255, 255, 255),
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 48,
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      color: Color.fromARGB(204, 255, 255, 255),
                      fontSize: 14,
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

  Widget _buildAnimatedProfileContent(String level, DateTime? memberSince) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('İstatistiklerim'),
                _buildStatsGrid(level),
                const SizedBox(height: 24),
                _buildSectionTitle('Rozetler'),
                _buildAchievementsSection(),
                const SizedBox(height: 24),
                _buildSectionTitle('Uygulama Ayarları'),
                _buildAppSettingsCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('Destek'),
                _buildSupportCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('Hesap Yönetimi'),
                _buildAccountManagementCard(memberSince),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Padding _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildStatsGrid(String level) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1,
      children: [
        _buildStatCard(Icons.local_fire_department, "3 Gün", "Seri", Colors.orange),
        _buildStatCard(Icons.timer, "45 dk", "Pratik Süresi", Colors.blue),
        _buildStatCard(Icons.people, "7", "Partner", Colors.green),
        _buildStatCard(Icons.bar_chart_rounded, level, "Seviye", Colors.purple),
        _buildStatCard(Icons.translate, "24", "Yeni Kelime", Colors.redAccent),
        _buildStatCard(Icons.military_tech, "12 Gün", "En Yüksek Seri", Colors.amber.shade700),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildAchievementBadge('İlk Adım', Icons.flag, Colors.green, true),
          _buildAchievementBadge('Konuşkan', Icons.chat_bubble, Colors.blue, true),
          _buildAchievementBadge('Gezgin', Icons.language, Colors.orange, true),
          _buildAchievementBadge('Usta', Icons.star, Colors.amber, false),
          _buildAchievementBadge('Fenomen', Icons.whatshot, Colors.red, false),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(String name, IconData icon, Color color, bool earned) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: earned ? color : Colors.grey.shade300,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              color: earned ? Colors.black87 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
    );
  }

  Widget _buildAppSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Bildirimler'),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            secondary: const Icon(Icons.notifications_none_rounded, color: Colors.blue),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.palette_outlined, color: Colors.purple),
            title: const Text('Görünüm'),
            subtitle: const Text('Sistem Varsayılanı'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.help_outline_rounded, color: Colors.green),
            title: const Text('Yardım & Destek'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.description_outlined, color: Colors.blueGrey),
            title: const Text('Kullanıcı Sözleşmesi'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.grey),
            title: const Text('Gizlilik Politikası'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAccountManagementCard(DateTime? memberSince) {
    final formattedDate = memberSince != null ? DateFormat('dd MMMM yyyy', 'tr_TR').format(memberSince) : 'Bilinmiyor';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cake_rounded, color: Colors.pink),
            title: const Text('Üyelik Tarihi'),
            subtitle: Text(formattedDate),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.edit_note_rounded, color: Colors.blue),
            title: const Text('Profili Düzenle'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen(userId: widget.userId)),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.email_outlined, color: Colors.orange),
            title: const Text('E-postayı Değiştir'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.password_rounded, color: Colors.grey),
            title: const Text('Şifreyi Değiştir'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.teal),
            title: const Text('Çıkış Yap'),
            onTap: () async {
              // KALICI DÜZELTME: Manuel yönlendirme kaldırıldı.
              // Sadece oturumu kapatıyoruz, gerisini AuthWrapper halledecek.
              await _authService.signOut();
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            title: const Text('Hesabı Sil', style: TextStyle(color: Colors.redAccent)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}