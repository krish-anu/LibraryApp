import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/models/profile_stats.dart' as model;

/// Statistics widget displaying user activity metrics.
class ProfileStatsWidget extends StatelessWidget {
  final model.ProfileStats? stats;

  const ProfileStatsWidget({super.key, this.stats});

  @override
  Widget build(BuildContext context) {
    final displayStats = stats ?? model.ProfileStats();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Pallete.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                Icons.menu_book,
                displayStats.activeLoans.toString(),
                "BORROWS",
                Pallete.primaryLight,
              ),
              _buildStatItem(
                Icons.history,
                displayStats.booksRead.toString(),
                "READ",
                Pallete.textSecondary,
              ),
              _buildStatItem(
                Icons.attach_money,
                displayStats.formattedFines,
                "FINES",
                displayStats.totalFines > 0
                    ? Colors.redAccent
                    : Pallete.primaryLight,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                Icons.bookmark_outline,
                displayStats.activeReservations.toString(),
                "RESERVED",
                Pallete.textSecondary,
              ),
              _buildStatItem(
                Icons.library_books,
                displayStats.totalBorrows.toString(),
                "TOTAL LOANS",
                Pallete.primaryLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color iconColor,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Pallete.scaffoldBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Pallete.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Pallete.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}
