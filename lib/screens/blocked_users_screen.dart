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
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Engellenenler')),
        body: const Center(child: Text('Devam etmek için giriş yapın.')),
      );
    }

    final userDocStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Engellenenler')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userDocStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Kullanıcı verisi bulunamadı.'));
          }

          final data = snapshot.data!.data()!;
          final List<dynamic> blocked = (data['blockedUsers'] as List<dynamic>?) ?? const [];
          if (blocked.isEmpty) {
            return const Center(child: Text('Henüz kimseyi engellemediniz.'));
          }

          // Engellenen kullanıcı belgelerini yükle
          return FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
            future: Future.wait(blocked.map((uid) => FirebaseFirestore.instance.collection('users').doc(uid as String).get())),
            builder: (context, usersSnap) {
              if (!usersSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = usersSnap.data!;
              if (docs.isEmpty) {
                return const Center(child: Text('Henüz kimseyi engellemediniz.'));
              }
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final userData = doc.data();
                  final displayName = userData?['displayName'] ?? 'Bilinmeyen Kullanıcı';
                  final avatarUrl = userData?['avatarUrl'] as String?;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      child: avatarUrl != null
                          ? ClipOval(
                              child: SvgPicture.network(
                                avatarUrl,
                                width: 36,
                                height: 36,
                                placeholderBuilder: (context) => const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.teal),
                    ),
                    title: Text(displayName),
                    trailing: TextButton.icon(
                      onPressed: () async {
                        try {
                          await BlockService().unblockUser(
                            currentUserId: currentUser.uid,
                            targetUserId: doc.id,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Engel kaldırıldı.')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Hata: ${e.toString()}')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.undo, color: Colors.red),
                      label: const Text('Engeli kaldır', style: TextStyle(color: Colors.red)),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

