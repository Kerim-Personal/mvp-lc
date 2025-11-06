// lib/widgets/profile_screen/app_settings_card.dart
import 'package:flutter/material.dart';
import 'package:vocachat/services/audio_service.dart';
// KALDIRILDI: BlockedUsersScreen import'u
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vocachat/services/translation_service.dart';
import 'package:vocachat/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsCard extends StatefulWidget {
  const AppSettingsCard({super.key});
  @override
  State<AppSettingsCard> createState() => _AppSettingsCardState();
}

class _AppSettingsCardState extends State<AppSettingsCard> {
  bool _autoTranslate = false;
  String _nativeLanguage = 'en';
  late double _musicVolume;
  static const String _kAutoTranslateKey = 'autoTranslate';

  @override
  void initState() {
    super.initState();
    _musicVolume = AudioService.instance.musicVolume;
    _loadUserPrefs();
  }

  Future<void> _loadUserPrefs() async {
    SharedPreferences? prefs;
    bool hasLocal = false;
    try {
      prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_kAutoTranslateKey)) {
        final localAuto = prefs.getBool(_kAutoTranslateKey) ?? false;
        setState(() => _autoTranslate = localAuto);
        hasLocal = true;
      }
    } catch (_) {}

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final data = snap.data();
        if (data != null) {
          setState(() { _nativeLanguage = (data['nativeLanguage'] as String?) ?? 'en'; });
          if (!hasLocal) {
            final remoteAuto = (data['autoTranslate'] as bool?) ?? false;
            setState(() => _autoTranslate = remoteAuto);
            try { await prefs?.setBool(_kAutoTranslateKey, remoteAuto); } catch (_) {}
          }
        }
      } catch (_) {}
    }

    if (_autoTranslate && _nativeLanguage != 'en') {
      TranslationService.instance.preDownloadModels(_nativeLanguage);
    }
  }

  Future<void> _updateAutoTranslate(bool value) async {
    setState(() => _autoTranslate = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kAutoTranslateKey, value);
    } catch (_) {}
    if (value) {
      TranslationService.instance.preDownloadModels(_nativeLanguage);
    }
  }

  String _getLanguageName(String code) {
    const languageMap = {
      'tr': 'Turkish',
      'en': 'English',
      'es': 'Spanish',
      'de': 'German',
      'fr': 'French',
    };
    return languageMap[code] ?? code.toUpperCase();
  }

  Widget _buildTranslationSection() {
    return ValueListenableBuilder<TranslationModelDownloadState>(
      valueListenable: TranslationService.instance.downloadState,
      builder: (context, state, _) {
        final showProgress = state.inProgress && state.targetCode == _nativeLanguage;
        final completed = state.completed && state.targetCode == _nativeLanguage;
        final languageName = _getLanguageName(_nativeLanguage);
        return Column(
          children: [
            SwitchListTile(
              title: const Text('Auto Translation', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_autoTranslate ? 'On' : 'Off'),
              value: _autoTranslate,
              onChanged: (v) => _updateAutoTranslate(v),
              secondary: const Icon(Icons.translate, color: Colors.teal),
              activeColor: Colors.teal,
            ),
            if (_autoTranslate)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showProgress) ...[
                      Row(children: [
                        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$languageName model downloading... (${state.downloaded}/${state.total})',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: state.total == 0 ? null : (state.downloaded / state.total).clamp(0.0, 1.0),
                          minHeight: 6,
                        ),
                      ),
                    ] else if (state.error != null && state.targetCode == _nativeLanguage) ...[
                      Row(children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Model download error: ${state.error}',
                            style: const TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        )
                      ]),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => TranslationService.instance.preDownloadModels(_nativeLanguage),
                          child: const Text('Retry'),
                        ),
                      )
                    ] else if (completed) ...[
                      Row(children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text('$languageName model ready', style: const TextStyle(fontSize: 12, color: Colors.green))
                      ]),
                    ] else ...[
                      Row(children: [
                        const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$languageName model will download before first translation.',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        )
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
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _musicVolume <= 0.0
                          ? Icons.volume_off_rounded
                          : (_musicVolume < 0.34
                              ? Icons.volume_mute_rounded
                              : (_musicVolume < 0.67
                                  ? Icons.volume_down_rounded
                                  : Icons.volume_up_rounded)),
                      color: _musicVolume > 0 ? Colors.orange : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Music Volume', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                      _musicVolume <= 0 ? 'Off' : '${(_musicVolume * 100).round()}%',
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ],
                ),
                Slider(
                  value: _musicVolume.clamp(0.0, 1.0),
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  label: _musicVolume <= 0 ? 'Off' : '${(_musicVolume * 100).round()}%',
                  onChanged: (v) async {
                    setState(() => _musicVolume = v);
                    await AudioService.instance.setMusicVolume(v);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildTranslationSection(),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.palette_outlined, color: Colors.purple),
            title: const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(() {
              final mode = ThemeService.instance.themeMode;
              if (mode == ThemeMode.dark) return 'Dark';
              if (mode == ThemeMode.system) return 'System';
              return 'Light';
            }()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (ctx) {
                  final current = ThemeService.instance.themeMode;
                  final cs = Theme.of(context).colorScheme;
                  final selectedColor = cs.primary;
                  Color? inactiveIconColor = Theme.of(context).iconTheme.color;
                  Color subtleText = cs.onSurface.withValues(alpha: 0.75);
                  Widget buildOption(ThemeMode mode, String title, IconData icon) {
                    final selected = current == mode;
                    return ListTile(
                      leading: Icon(icon, color: selected ? selectedColor : inactiveIconColor),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected ? selectedColor : subtleText,
                        ),
                      ),
                      trailing: selected
                          ? Icon(Icons.check_circle, color: selectedColor)
                          : Icon(Icons.circle_outlined, size: 18, color: subtleText.withValues(alpha: 0.55)),
                      onTap: () {
                        Navigator.pop(ctx);
                        ThemeService.instance.setThemeMode(mode);
                        setState(() {});
                      },
                    );
                  }
                  return SafeArea(
                    child: AnimatedBuilder(
                      animation: ThemeService.instance,
                      builder: (_, __) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Theme Mode',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Divider(height: 1, thickness: 0.6, color: cs.onSurface.withValues(alpha: 0.08)),
                            buildOption(ThemeMode.light, 'Light', Icons.wb_sunny_outlined),
                            buildOption(ThemeMode.dark, 'Dark', Icons.nights_stay_outlined),
                            buildOption(ThemeMode.system, 'System', Icons.settings_suggest_outlined),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
