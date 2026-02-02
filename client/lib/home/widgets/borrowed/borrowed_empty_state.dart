import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

/// Empty state widget when no books are borrowed.
class BorrowedEmptyState extends StatelessWidget {
  final VoidCallback? onBrowseBooks;

  const BorrowedEmptyState({super.key, this.onBrowseBooks});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Pallete.cardBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.library_books_outlined,
                size: 64,
                color: Pallete.primaryLight.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Borrowed Books',
              style: TextStyle(
                color: Pallete.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You haven\'t borrowed any books yet.\nExplore our collection and find your next read!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Pallete.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (onBrowseBooks != null)
              ElevatedButton.icon(
                onPressed: onBrowseBooks,
                icon: const Icon(Icons.explore, color: Colors.white),
                label: const Text(
                  'Browse Books',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Pallete.primaryLight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
