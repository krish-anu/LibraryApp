import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/utils/image_helper.dart';
import 'package:libraryapp/models/book.dart';

/// Card displaying a favorite book with status and remove option.
class FavoriteBookCard extends StatelessWidget {
  final Book book;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const FavoriteBookCard({
    super.key,
    required this.book,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = book.copiesOwned > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Pallete.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Pallete.border),
        ),
        child: Row(
          children: [
            _buildBookCover(),
            const SizedBox(width: 16),
            Expanded(child: _buildBookInfo(isAvailable)),
            _buildFavoriteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCover() {
    return Container(
      width: 60,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image(
          image: imageProviderFromPath(book.image),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildBookInfo(bool isAvailable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          book.author,
          style: TextStyle(color: Pallete.textSecondary, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        _buildStatusBadge(isAvailable),
      ],
    );
  }

  Widget _buildStatusBadge(bool isAvailable) {
    if (isAvailable) {
      return Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Pallete.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'AVAILABLE',
            style: TextStyle(
              color: Pallete.success,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Icon(Icons.schedule, size: 12, color: Pallete.warning),
          const SizedBox(width: 4),
          Text(
            'WAITLIST: 2 WKS',
            style: TextStyle(
              color: Pallete.warning,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: onFavoriteToggle,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: Pallete.primaryLight,
          size: 28,
        ),
      ),
    );
  }
}
