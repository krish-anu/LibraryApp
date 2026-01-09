import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

/// Statistics row displaying user activity metrics.
class ProfileStats extends StatelessWidget {
  final int borrows;
  final int read;
  final String fines;

  const ProfileStats({
    super.key,
    this.borrows = 3,
    this.read = 42,
    this.fines = '\$0.00',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Pallete.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            Icons.menu_book,
            borrows.toString(),
            "BORROWS",
            Pallete.primaryLight,
          ),
          _buildStatItem(
            Icons.history,
            read.toString(),
            "READ",
            Pallete.textSecondary,
          ),
          _buildStatItem(
            Icons.attach_money,
            fines,
            "FINES",
            Pallete.primaryLight,
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
            color: Colors.white,
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
