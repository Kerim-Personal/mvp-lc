import 'package:flutter/material.dart';

class AppSettingsCard extends StatefulWidget {
  const AppSettingsCard({super.key});

  @override
  State<AppSettingsCard> createState() => _AppSettingsCardState();
}

class _AppSettingsCardState extends State<AppSettingsCard> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Bildirimler'),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            secondary: const Icon(Icons.notifications_none_rounded, color: Colors.blue),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.palette_outlined, color: Colors.purple),
            title: const Text('Görünüm'),
            subtitle: const Text('Sistem Varsayılanı'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}