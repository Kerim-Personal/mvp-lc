import 'package:flutter/material.dart';
import 'package:lingua_chat/screens/admin_panel_screen.dart';

class AdminPanelCard extends StatelessWidget {
  const AdminPanelCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
        title: const Text('Yönetim Paneli', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Destek, banlı ve raporlanan kullanıcılar'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
          );
        },
      ),
    );
  }
}
