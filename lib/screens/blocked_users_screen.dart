// lib/screens/blocked_users_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingua_chat/services/block_service.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Kullanıcı giriş yapmamışsa erken çıkış yap
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Engellenenler')),
        body: const Center(child: Text('Devam etmek için giriş yapın.')),
      );
    }

    // Kullanıcının 'blockedUsers' alanını dinlemek için stream
    final userDocStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Ekrana hafif bir arka plan rengi verelim
      appBar: AppBar(
        title: const Text('Engellenenler'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userDocStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildEmptyState('Kullanıcı verisi bulunamadı.');
          }

          final data = snapshot.data!.data()!;
          final List<dynamic> blockedIds = (data['blockedUsers'] as List<dynamic>?) ?? const [];

          if (blockedIds.isEmpty) {
            return _buildEmptyState(
              'Henüz kimseyi engellemediniz.',
              icon: Icons.shield_outlined,
            );
          }

          // Engellenen kullanıcıların detaylarını çekmek için FutureBuilder
          return FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
            future: _fetchBlockedUsers(blockedIds.cast<String>()),
            builder: (context, usersSnap) {
              if (usersSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!usersSnap.hasData || usersSnap.data!.isEmpty) {
                return _buildEmptyState('Engellenen kullanıcı bulunamadı.');
              }

              final docs = usersSnap.data!;

              // Engellenen kullanıcıları liste olarak göster
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final userData = doc.data();
                  return _buildBlockedUserCard(context, currentUser.uid, doc.id, userData);
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Engellenen kullanıcıların listesini Firestore'dan çeker.
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> _fetchBlockedUsers(List<String> userIds) {
    if (userIds.isEmpty) {
      return Future.value([]);
    }
    // Her bir UID için get() isteğini paralel olarak çalıştırır.
    return Future.wait(
      userIds.map((uid) => FirebaseFirestore.instance.collection('users').doc(uid).get()),
    );
  }

  /// Engellenen bir kullanıcıyı gösteren kart widget'ı.
  Widget _buildBlockedUserCard(BuildContext context, String currentUserId, String targetUserId, Map<String, dynamic>? userData) {
    final displayName = userData?['displayName'] ?? 'Bilinmeyen Kullanıcı';
    final avatarUrl = userData?['avatarUrl'] as String?;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.teal.shade50,
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? ClipOval(
                child: SvgPicture.network(
                  avatarUrl,
                  width: 48,
                  height: 48,
                  placeholderBuilder: (_) => const Icon(Icons.person, color: Colors.teal, size: 28),
                ),
              )
                  : const Icon(Icons.person, color: Colors.teal, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                displayName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _unblockUser(context, currentUserId, targetUserId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade800,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Engeli Kaldır'),
            ),
          ],
        ),
      ),
    );
  }

  /// Bir kullanıcının engelini kaldırma işlemini yönetir.
  Future<void> _unblockUser(BuildContext context, String currentUserId, String targetUserId) async {
    try {
      await BlockService().unblockUser(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcının engeli kaldırıldı.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Engellenen kullanıcı listesi boş olduğunda gösterilecek widget.
  Widget _buildEmptyState(String message, {IconData? icon}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.info_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}