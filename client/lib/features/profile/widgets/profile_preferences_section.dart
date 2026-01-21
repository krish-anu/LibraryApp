import 'package:flutter/material.dart';
import 'profile_section_title.dart';
import 'profile_toggle_item.dart';

/// Preferences section with toggles.
class ProfilePreferencesSection extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onDarkModeChanged;

  const ProfilePreferencesSection({
    super.key,
    required this.isDark,
    required this.onDarkModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ProfileSectionTitle(title: "APP PREFERENCES"),
        ProfileToggleItem(
          icon: Icons.notifications_outlined,
          title: "Push Notifications",
          value: true,
          onChanged: (_) {},
        ),
        ProfileToggleItem(
          icon: Icons.dark_mode_outlined,
          title: "Dark Mode",
          value: isDark,
          onChanged: onDarkModeChanged,
        ),
      ],
    );
  }
}
