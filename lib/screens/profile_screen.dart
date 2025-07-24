// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/screens/edit_profile_screen.dart';
import 'package:lingua_chat/screens/login_screen.dart';
import 'package:lingua_chat/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;
  final AuthService _authService = AuthService(); // AuthService eklendi

  @override
  void initState() {
    super.initState();
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: 'Profili Düzenle',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditProfileScreen(userId: widget.userId),
                ),
              );
            },
          ),
          IconButton( // <-- YENİ EKLENDİ
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _authService.signOut();
              navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false);
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('Veriler yüklenirken bir hata oluştu.'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Kullanıcı bulunamadı.'));
          }

          final userData = snapshot.data!.data();
          final displayName = userData?['displayName'] ?? 'İsimsiz';
          final email = userData?['email'] ?? 'E-posta yok';
          final level = userData?['level'] ?? 'Belirlenmemiş';
          final memberSince = (userData?['createdAt'] as Timestamp?)?.toDate();
          final formattedDate = memberSince != null
              ? DateFormat('dd MMMM yyyy', 'tr_TR').format(memberSince)
              : 'Bilinmiyor';

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _userStream = FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .snapshots();
              });
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.teal.shade100,
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 40,
                              color: Colors.teal,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        email,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                _buildProfileInfoTile(
                  icon: Icons.bar_chart_rounded,
                  title: 'Dil Seviyesi',
                  subtitle: level,
                  color: Colors.deepPurple,
                ),
                _buildProfileInfoTile(
                  icon: Icons.cake_rounded,
                  title: 'Üyelik Tarihi',
                  subtitle: formattedDate,
                  color: Colors.orange,
                ),
                const Divider(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16)),
    );
  }
}