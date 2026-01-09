import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

class BookInfoSection extends StatelessWidget {
  final String title;
  final String author;
  final double rating;

  const BookInfoSection({
    super.key,
    required this.title,
    required this.author,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Title
        Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Author
        Center(
          child: Text(
            author,
            style: TextStyle(color: Pallete.textSecondary, fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
        // Stats row
        _buildStatsRow(),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _InfoItem(
            icon: Icons.star,
            iconColor: Colors.amber,
            value: '$rating',
            label: '(1.2k)',
          ),
          const _Divider(),
          const _InfoItem(
            icon: Icons.menu_book,
            iconColor: Pallete.textSecondary,
            value: '208 Pages',
          ),
          const _Divider(),
          const _InfoItem(
            icon: Icons.language,
            iconColor: Pallete.textSecondary,
            value: 'English',
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String? label;

  const _InfoItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (label != null)
          Text(
            ' $label',
            style: TextStyle(color: Pallete.textSecondary, fontSize: 12),
          ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 20, width: 1, color: Pallete.border);
  }
}
