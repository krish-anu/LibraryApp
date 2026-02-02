import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

/// A dropdown widget for sorting search results.
class SortDropdown extends StatelessWidget {
  final String sortBy;
  final ValueChanged<String?> onChanged;

  const SortDropdown({
    super.key,
    required this.sortBy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Pallete.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButton<String>(
        value: sortBy,
        dropdownColor: Pallete.cardBackground,
        underline: const SizedBox(),
        isDense: true,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: Pallete.iconColor,
          size: 18,
        ),
        style: const TextStyle(color: Pallete.textPrimary, fontSize: 14),
        items: ['Popular', 'Newest', 'Title'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text('Sort by: $value'),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
