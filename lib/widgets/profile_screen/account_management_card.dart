import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/screens/edit_profile_screen.dart';
import 'package:lingua_chat/services/auth_service.dart';

class AccountManagementCard extends StatelessWidget {
  final DateTime? memberSince;
  final String userId;
  final AuthService authService;

  const AccountManagementCard({
    super.key,
    required this.memberSince,
    required this.userId,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = memberSince != null ? DateFormat('dd MMMM yyyy', 'tr_TR').format(memberSince!) : 'Bilinmiyor';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cake_rounded, color: Colors.pink),
            title: const Text('Üyelik Tarihi'),
            subtitle: Text(formattedDate),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.edit_note_rounded, color: Colors.blue),
            title: const Text('Profili Düzenle'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen(userId: userId)),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.teal),
            title: const Text('Çıkış Yap'),
            onTap: () async {
              await authService.signOut();
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            title: const Text('Hesabı Sil', style: TextStyle(color: Colors.redAccent)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}