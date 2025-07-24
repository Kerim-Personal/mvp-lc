// lib/widgets/home_screen/filter_bottom_sheet.dart

import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final String? selectedOption;
  final Map<String, String>? displayLabels; // For mapping keys to display names e.g., 'Male' -> 'Erkek'

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
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          ...widget.options.map((option) {
            final isSelected = _currentSelection == option;
            final displayLabel = widget.displayLabels?[option] ?? option;
            return ListTile(
              title: Text(displayLabel, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.teal)
                  : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
              onTap: () {
                setState(() {
                  _currentSelection = option;
                });
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: isSelected ? Colors.teal.withOpacity(0.1) : Colors.transparent,
            );
          }).toList(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context, null); // Return null to indicate clearing
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Filtreyi Temizle'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _currentSelection);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                  child: const Text('Uygula', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}