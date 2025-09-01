// lib/screens/banned_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Oturum bulunamadı.')));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 12),
                      const Text('Bir hata oluştu. Lütfen tekrar deneyin.'),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Çıkış Yap'),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data();
        final reason = (data?['bannedReason'] as String?)?.trim();
        final details = (data?['bannedDetails'] as String?)?.trim();
        final bannedAt = data?['bannedAt'] as Timestamp?;
        final formattedDate = bannedAt != null
            ? DateFormat('d MMMM y HH:mm', 'tr_TR').format(bannedAt.toDate())
            : null;
        final isPremium = (data?['isPremium'] as bool?) == true;

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
                  if (formattedDate != null) ...[
                    const SizedBox(height: 8),
                    Text('Tarih: $formattedDate', style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
                  const SizedBox(height: 12),
                  if (isPremium)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/support');
                      },
                      icon: const Icon(Icons.support_agent),
                      label: const Text('Destek Talebi Oluştur (Pro)'))
                  else
                    TextButton.icon(
                      onPressed: () async {
                        final uid = currentUser.uid;
                        final subject = 'Yasak İtirazı - $uid';
                        final body = [
                          'Merhaba, hesabımın yasaklanmasına itiraz ediyorum.',
                          if (reason != null && reason.isNotEmpty) 'Sebep: $reason',
                          if (formattedDate != null) 'Tarih: $formattedDate',
                          if (details != null && details.isNotEmpty) 'Detaylar: $details',
                          '',
                          'Lütfen inceleyip geri dönüş yapar mısınız?\nTeşekkürler.'
                        ].join('\n');
                        final uri = Uri(
                          scheme: 'mailto',
                          path: 'info@codenzi.com',
                          query: Uri.encodeFull('subject=$subject&body=$body'),
                        );
                        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('E-posta uygulaması açılamadı.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('E‑posta ile İtiraz Et'),
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
