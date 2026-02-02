import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

/// A toggle menu item with switch control.
class ProfileToggleItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ProfileToggleItem({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
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
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Pallete.primaryLight,
          activeTrackColor: const Color(0xFF1B5E20),
        ),
      ),
    );
  }
}
