// lib/screens/banned_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Oturum bulunamadı.')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final reason = data?['bannedReason'] as String?;
        final details = data?['bannedDetails'] as String?;
        final bannedAt = data?['bannedAt'] as Timestamp?;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.block, size: 72, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Hesabınız Yasaklandı',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (reason != null && reason.isNotEmpty)
                    Text('Sebep: $reason', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                  if (details != null && details.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(details, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                  ],
                  if (bannedAt != null) ...[
                    const SizedBox(height: 8),
                    Text('Tarih: ${bannedAt.toDate()}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Çıkış Yap'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

