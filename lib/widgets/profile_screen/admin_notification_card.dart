// lib/widgets/profile_screen/admin_notification_card.dart
import 'package:flutter/material.dart';
import 'package:lingua_chat/screens/admin_notification_screen.dart';

class AdminNotificationCard extends StatelessWidget {
  const AdminNotificationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.notifications_active, color: Colors.indigo),
        title: const Text('Notification Panel', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Send a push notification to users'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminNotificationScreen()),
          );
        },
      ),
    );
  }
}