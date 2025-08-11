// lib/widgets/profile_screen/support_card.dart
import 'package:flutter/material.dart';
import 'package:lingua_chat/screens/help_and_support_screen.dart';

class SupportCard extends StatelessWidget {
  // HATA ÇÖZÜMÜ: Widget'ın yapıcısı artık 'const' değil.
  const SupportCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.help_outline_rounded, color: Colors.green),
            title: const Text('Yardım & Destek', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HelpAndSupportScreen()),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.description_outlined, color: Colors.blueGrey),
            title: const Text('Kullanıcı Sözleşmesi', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {},
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.grey),
            title: const Text('Gizlilik Politikası', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}