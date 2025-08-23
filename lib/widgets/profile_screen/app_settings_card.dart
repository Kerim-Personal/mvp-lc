// lib/widgets/profile_screen/app_settings_card.dart
import 'package:flutter/material.dart';
import 'package:lingua_chat/services/audio_service.dart'; // Müzik servisini import ediyoruz
import 'package:lingua_chat/screens/blocked_users_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/services/translation_service.dart';

class AppSettingsCard extends StatefulWidget {
  const AppSettingsCard({super.key});

  @override
  State<AppSettingsCard> createState() => _AppSettingsCardState();
}

class _AppSettingsCardState extends State<AppSettingsCard> {
  late bool _isMusicEnabled;
  bool _autoTranslate = false; // yeni
  String _nativeLanguage = 'en';

  @override
  void initState() {
    super.initState();
    // Widget ilk oluşturulduğunda müziğin mevcut durumunu servisten alıyoruz
    _isMusicEnabled = AudioService.instance.isMusicEnabled;
    _loadUserPrefs();
  }

  Future<void> _loadUserPrefs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = snap.data();
      if (data != null) {
        setState(() {
          _autoTranslate = (data['autoTranslate'] as bool?) ?? false;
          _nativeLanguage = (data['nativeLanguage'] as String?) ?? 'en';
        });
      }
    } catch (_) {}
  }

  Future<void> _updateAutoTranslate(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _autoTranslate = value);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'autoTranslate': value});
    if (value) {
      TranslationService.instance.preDownloadModels(_nativeLanguage);
    }
  }

  // GÜNCELLEME: Dil kodunu dil adına çeviren yardımcı metot
  String _getLanguageName(String code) {
    // Bu haritayı uygulamanızdaki desteklenen dillerle genişletebilirsiniz.
    const languageMap = {
      'tr': 'Türkçe',
      'en': 'English',
      'es': 'Español',
      'de': 'Deutsch',
      'fr': 'Français',
    };
    return languageMap[code] ?? code.toUpperCase();
  }

  Widget _buildTranslationSection() {
    return ValueListenableBuilder<TranslationModelDownloadState>(
      valueListenable: TranslationService.instance.downloadState,
      builder: (context, state, _) {
        final showProgress =
            state.inProgress && state.targetCode == _nativeLanguage;
        final completed = state.completed && state.targetCode == _nativeLanguage;
        // GÜNCELLEME: Dil adını alıyoruz
        final languageName = _getLanguageName(_nativeLanguage);

        return Column(
          children: [
            SwitchListTile(
              title: const Text('Otomatik Çeviri',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_autoTranslate ? 'Açık' : 'Kapalı'),
              value: _autoTranslate,
              onChanged: (v) => _updateAutoTranslate(v),
              secondary: const Icon(Icons.translate, color: Colors.teal),
              activeColor: Colors.teal,
            ),
            if (_autoTranslate)
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showProgress) ...[
                      Row(
                        children: [
                          const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                              CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(
                                  '$languageName çeviri modeli indiriliyor... (${state.downloaded}/${state.total})',
                                  style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: state.total == 0
                              ? null
                              : (state.downloaded / state.total)
                              .clamp(0.0, 1.0),
                          minHeight: 6,
                        ),
                      ),
                    ] else if (state.error != null &&
                        state.targetCode == _nativeLanguage) ...[
                      Row(children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text('Model indirme hatası: ${state.error}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.red)))
                      ]),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => TranslationService.instance
                              .preDownloadModels(_nativeLanguage),
                          child: const Text('Tekrar Dene'),
                        ),
                      )
                    ] else if (completed) ...[
                      // GÜNCELLEME: Metin, dil adını içerecek şekilde değiştirildi.
                      Row(children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text('$languageName çeviri modeli hazır',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.green))
                      ]),
                    ] else ...[
                      Row(children: [
                        const Icon(Icons.info_outline,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                'İlk çeviri öncesi $languageName modeli indirilecek.',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)))
                      ])
                    ]
                  ],
                ),
              )
          ],
        );
      },
    );
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
            title: const Text('Müzik',
                style: TextStyle(fontWeight: FontWeight.w600)),
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
              _isMusicEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: Colors.orange,
            ),
            activeColor: Colors.teal,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildTranslationSection(),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.palette_outlined, color: Colors.purple),
            title: const Text('Görünüm',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Sistem Varsayılanı'),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
            onTap: () {},
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.redAccent),
            title: const Text('Engellenenler',
                style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
