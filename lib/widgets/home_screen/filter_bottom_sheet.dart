// lib/widgets/home_screen/filter_bottom_sheet.dart

import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final String? selectedOption;
  final Map<String, String>? displayLabels; // For mapping keys to display names e.g., 'male_key' -> 'Male'

  const FilterBottomSheet({
    super.key,
    required this.title,
    required this.options,
    this.selectedOption,
    this.displayLabels,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _currentSelection;

  @override
  void initState() {
    super.initState();
    _currentSelection = widget.selectedOption;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final onSurface = cs.onSurface;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
        border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.25))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface),
          ),
          const SizedBox(height: 20),
          ...widget.options.map((option) {
            final isSelected = _currentSelection == option;
            final displayLabel = widget.displayLabels?[option] ?? option;
            final baseColor = onSurface.withOpacity(0.85);
            return ListTile(
              title: Text(
                displayLabel,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: baseColor,
                ),
              ),
              trailing: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? cs.primary : theme.iconTheme.color?.withOpacity(0.6),
              ),
              onTap: () {
                setState(() {
                  _currentSelection = option;
                });
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: isSelected
                  ? cs.primary.withOpacity(0.12)
                  : Colors.transparent,
            );
          }).toList(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onSurface.withOpacity(0.8),
                    side: BorderSide(color: theme.dividerColor.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Clear Filter'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _currentSelection),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: isDark ? 0 : 5,
                  ),
                  child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}