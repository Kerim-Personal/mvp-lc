import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'support_ticket_detail_screen.dart';

class MySupportRequestsScreen extends StatefulWidget {
  const MySupportRequestsScreen({super.key});

  @override
  State<MySupportRequestsScreen> createState() => _MySupportRequestsScreenState();
}

class _MySupportRequestsScreenState extends State<MySupportRequestsScreen> {
  final _auth = FirebaseAuth.instance;
  late final String? _uid = _auth.currentUser?.uid;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Taleplerim')),
      body: _uid == null
          ? const Center(child: Text('Giriş gerekli.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('support')
                  .where('userId', isEqualTo: _uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (c, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Hata: ${snap.error}'));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('Henüz talebiniz yok.'));
                }
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (ctx, i) {
                    final d = docs[i];
                    final data = d.data();
                    final status = (data['status'] as String?) ?? 'open';
                    return ListTile(
                      title: Text(data['subject'] ?? '—'),
                      subtitle: Text((data['message'] as String?) ?? ''),
                      trailing: _statusChip(status),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SupportTicketDetailScreen(ticketId: d.id, ticketData: data),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _statusChip(String status) {
    Color c;
    switch (status) {
      case 'closed':
        c = Colors.green; break;
      case 'in_progress':
        c = Colors.orange; break;
      default:
        c = Colors.blueGrey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
