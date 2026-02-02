import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

/// A tappable menu item with icon and title.
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: Pallete.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Pallete.textSecondary),
        title: Text(
          title,
          style: const TextStyle(color: Pallete.textPrimary, fontSize: 16),
        ),
        trailing: Icon(Icons.chevron_right, color: Pallete.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
