import 'package:flutter/material.dart';
import 'package:lingua_chat/screens/admin_panel_screen.dart';
import 'package:lingua_chat/screens/admin_notification_screen.dart';

class AdministrationCard extends StatelessWidget {
  final String role; // 'admin', 'moderator', 'user'
  const AdministrationCard({super.key, required this.role});

  bool get _canNotify => role == 'admin';

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      ListTile(
        leading: const Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
        title: const Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Support, banned & reported users'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
        ),
      ),
    ];

    if (_canNotify) {
      tiles.addAll([
        const Divider(height: 1, indent: 72, endIndent: 12),
        ListTile(
          leading: const Icon(Icons.notifications_active, color: Colors.indigo),
          title: const Text('Notification Panel', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Kullanıcılara push bildirimi gönder'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminNotificationScreen()),
          ),
        ),
      ]);
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: tiles,
      ),
    );
  }
}
