// lib/widgets/vocabot/vocabot_settings.dart
// Dil seçim ekranı ve filtre toggle bileşenleri.

import 'package:flutter/material.dart';

class FullScreenSettings extends StatefulWidget {
  final Map<String,String> supportedLanguages;
  final Map<String,String> languageFlags;
  final String targetLanguage;
  final Widget Function(String) buildTile;
  final VoidCallback onClose;
  final void Function(String) onChange;

  const FullScreenSettings({
    super.key,
    required this.supportedLanguages,
    required this.languageFlags,
    required this.targetLanguage,
    required this.buildTile,
    required this.onClose,
    required this.onChange,
  });

  @override
  State<FullScreenSettings> createState() => _FullScreenSettingsState();
}

class _FullScreenSettingsState extends State<FullScreenSettings> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _popularOnly = false;

  static const Set<String> _popularLanguages = {
    'en','es','fr','de','tr','it','pt','ru','ar','ja','ko','zh','nl','sv'
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MapEntry<String,String>> _filtered() {
    Iterable<MapEntry<String,String>> entries = widget.supportedLanguages.entries;
    if (_popularOnly) {
      entries = entries.where((e) => _popularLanguages.contains(e.key));
    }
    final qRaw = _query.trim();
    if (qRaw.isNotEmpty) {
      final q = qRaw.toLowerCase();
      entries = entries.where((e) => e.key.toLowerCase().contains(q) || e.value.toLowerCase().contains(q));
    }
    return entries.toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filtered();
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 1.00), width: 1),
                    ),
                    child: const Icon(Icons.settings_outlined, color: Colors.cyanAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.white70),
                  )
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.cyanAccent,
                decoration: InputDecoration(
                  hintText: 'Search language',
                  hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent, size: 20),
                  suffixIcon: _query.isEmpty ? null : IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.60), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.3),
                  ),
                ),
                onChanged: (v) => setState(()=> _query = v),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.60), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilterToggle(
                      label: 'All Languages',
                      icon: Icons.public,
                      isSelected: !_popularOnly,
                      onTap: () => setState(() => _popularOnly = false),
                      count: widget.supportedLanguages.length,
                    ),
                    FilterToggle(
                      label: 'Popular',
                      icon: Icons.star_rounded,
                      isSelected: _popularOnly,
                      onTap: () => setState(() => _popularOnly = true),
                      count: _popularLanguages.length,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.40), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.translate_outlined, color: Colors.cyanAccent, size: 20),
                          const SizedBox(width: 8),
                          Text('Learning Language (${entries.length})', style: TextStyle(color: Colors.cyanAccent.withAlpha(230), fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final bool narrow = constraints.maxWidth < 300;
                            final int columns = narrow ? 2 : 3;
                            if (entries.isEmpty) {
                              return const Center(
                                child: Text('Sonuç yok', style: TextStyle(color: Colors.white60, fontSize: 13)),
                              );
                            }
                            return RawScrollbar(
                              thumbVisibility: true,
                              trackVisibility: false,
                              thickness: 4,
                              radius: const Radius.circular(8),
                              thumbColor: Colors.cyanAccent,
                              child: GridView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(right: 4, bottom: 8),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 1.3,
                                ),
                                itemCount: entries.length,
                                itemBuilder: (ctx, i) {
                                  final code = entries[i].key;
                                  return widget.buildTile(code);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.90), width: 1),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, color: Colors.orangeAccent, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Last messages stored on your device.',
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500, height: 1.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int count;

  const FilterToggle({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.cyanAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.black : Colors.cyanAccent, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

