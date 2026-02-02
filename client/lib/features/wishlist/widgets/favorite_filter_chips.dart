import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

/// Filter chips for the favorites page.
class FavoriteFilterChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const FavoriteFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  static const filters = ['All', 'Available Now', 'Fiction', 'Non-Fiction'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onFilterChanged(filter),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Pallete.primaryLight
                      : Pallete.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? null : Border.all(color: Pallete.border),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected
                        ? Pallete.btnTextColor
                        : Pallete.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
