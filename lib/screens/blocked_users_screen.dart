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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Engellenenler')),
        body: Center(child: Text('Devam etmek için giriş yapın.', style: theme.textTheme.bodyMedium)),
      );
    }

    final blockedStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('blockedUsers')
        .snapshots();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Engellenenler'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: isDark ? 0 : 1,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: blockedStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return _buildEmptyState(context, 'Kullanıcı verisi bulunamadı.');
          }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return _buildEmptyState(
                context,
                'Henüz kimseyi engellemediniz.',
                icon: Icons.shield_outlined,
              );
            }

          final blockedIds = docs.map((d) => d.id).toList(growable: false);

          return FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
            future: _fetchBlockedUsers(blockedIds),
            builder: (context, usersSnap) {
              if (usersSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!usersSnap.hasData || usersSnap.data!.isEmpty) {
                return _buildEmptyState(context, 'Engellenen kullanıcı bulunamadı.');
              }

              final userDocs = usersSnap.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: userDocs.length,
                itemBuilder: (context, index) {
                  final doc = userDocs[index];
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

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> _fetchBlockedUsers(List<String> userIds) {
    if (userIds.isEmpty) {
      return Future.value([]);
    }
    return Future.wait(
      userIds.map((uid) => FirebaseFirestore.instance.collection('users').doc(uid).get()),
    );
  }

  Widget _buildBlockedUserCard(BuildContext context, String currentUserId, String targetUserId, Map<String, dynamic>? userData) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayName = userData?['displayName'] ?? 'Bilinmeyen Kullanıcı';
    final avatarUrl = userData?['avatarUrl'] as String?;

    return Card(
      elevation: isDark ? 1.5 : 2,
      shadowColor: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isDark ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : Colors.teal.shade50,
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? ClipOval(
                      child: SvgPicture.network(
                        avatarUrl,
                        width: 48,
                        height: 48,
                        placeholderBuilder: (_) => Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 28),
                      ),
                    )
                  : Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                displayName,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _unblockUser(context, currentUserId, targetUserId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: isDark ? 0.25 : 1.0),
                foregroundColor: Theme.of(context).colorScheme.error,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Engeli Kaldır'),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildEmptyState(BuildContext context, String message, {IconData? icon}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.info_outline,
            size: 80,
            color: cs.onSurface.withValues(alpha: 0.30),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.65)),
            ),
          ),
        ],
      ),
    );
  }
}