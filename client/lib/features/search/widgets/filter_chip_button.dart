import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

/// A reusable filter chip button for search filters.
class FilterChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterChipButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Pallete.primaryLight : Pallete.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Pallete.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Pallete.textSecondary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
