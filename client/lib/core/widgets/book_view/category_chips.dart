import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

class CategoryChips extends StatelessWidget {
  final String category;

  const CategoryChips({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        spacing: 8,
        children: [
          // _CategoryChip(label: 'Classic'),
          _CategoryChip(label: category),
          // _CategoryChip(label: 'American Lit'),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Pallete.categoryChipBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Pallete.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
