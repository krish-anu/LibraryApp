import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/utils/image_helper.dart';
import 'package:libraryapp/models/category.dart';

/// Section displaying category chips in a grid.
class CategoriesSection extends StatelessWidget {
  final List<Category> categories;
  final ValueChanged<String> onCategoryTap;

  const CategoriesSection({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  static const _categoryData = {
    'Sci-Fi': {
      'icon': Icons.rocket_launch_outlined,
      'color': Color(0xFF4A90D9),
    },
    'History': {
      'icon': Icons.account_balance_outlined,
      'color': Color(0xFF4A90D9),
    },
    'Fiction': {
      'icon': Icons.auto_stories_outlined,
      'color': Color(0xFF4A90D9),
    },
    'Mystery': {'icon': Icons.psychology_outlined, 'color': Color(0xFF4A90D9)},
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore Categories',
          style: TextStyle(
            color: Pallete.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildCategoryGrid(),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.8,
      children: categories.map(_buildCategoryChip).toList(),
    );
  }

  Widget _buildCategoryChip(Category category) {
    final data =
        _categoryData[category.name] ??
        {'icon': Icons.book_outlined, 'color': const Color(0xFF4A90D9)};

    return GestureDetector(
      onTap: () => onCategoryTap(category.name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Pallete.categoryChipBackground,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            _buildCategoryIcon(category, data),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  color: Pallete.categoryChipText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(Category category, Map<String, dynamic> data) {
    if (category.image != null && category.image!.isNotEmpty) {
      return SizedBox(
        width: 36,
        height: 36,
        child: ClipOval(
          child: Image(
            image: imageProviderFromPath(category.image),
            fit: BoxFit.cover,
            width: 36,
            height: 36,
          ),
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: data['color'] as Color,
        shape: BoxShape.circle,
      ),
      child: Icon(data['icon'] as IconData, color: Pallete.btnTextColor, size: 18),
    );
  }
}
