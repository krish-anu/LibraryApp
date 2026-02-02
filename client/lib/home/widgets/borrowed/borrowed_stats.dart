import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

/// Statistics summary widget for borrowed books.
class BorrowedStats extends StatelessWidget {
  final int totalBorrowed;
  final int dueSoon;
  final int overdue;

  const BorrowedStats({
    super.key,
    required this.totalBorrowed,
    required this.dueSoon,
    required this.overdue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Pallete.primaryColor, Pallete.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.library_books,
                color: Pallete.primaryLight,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'Loan Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Pallete.primaryLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalBorrowed books',
                  style: const TextStyle(
                    color: Pallete.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.menu_book,
                  value: totalBorrowed.toString(),
                  label: 'Borrowed',
                  color: Pallete.primaryLight,
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.schedule,
                  value: dueSoon.toString(),
                  label: 'Due Soon',
                  color: Pallete.warning,
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.warning_amber,
                  value: overdue.toString(),
                  label: 'Overdue',
                  color: Pallete.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            color: Pallete.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Pallete.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 60,
      color: Pallete.border.withValues(alpha: 0.5),
    );
  }
}
