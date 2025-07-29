// lib/widgets/profile_screen/app_settings_card.dart
import 'package:flutter/material.dart';
import 'package:lingua_chat/services/audio_service.dart'; // Müzik servisini import ediyoruz

class AppSettingsCard extends StatefulWidget {
  const AppSettingsCard({super.key});

  @override
  State<AppSettingsCard> createState() => _AppSettingsCardState();
}

class _AppSettingsCardState extends State<AppSettingsCard> {
  late bool _isMusicEnabled;

  @override
  void initState() {
    super.initState();
    // Widget ilk oluşturulduğunda müziğin mevcut durumunu servisten alıyoruz
    _isMusicEnabled = AudioService.instance.isMusicEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Müzik', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(_isMusicEnabled ? 'Açık' : 'Kapalı'),
            value: _isMusicEnabled,
            onChanged: (bool value) {
              // Arayüzdeki switch'in durumunu güncelliyoruz
              setState(() {
                _isMusicEnabled = value;
              });
              // Müzik servisine yeni durumu bildirerek müziği açıp kapatmasını sağlıyoruz
              AudioService.instance.toggleMusic(value);
            },
            secondary: Icon(
              _isMusicEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: Colors.orange,
            ),
            activeColor: Colors.teal,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.palette_outlined, color: Colors.purple),
            title: const Text('Görünüm', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Sistem Varsayılanı'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}