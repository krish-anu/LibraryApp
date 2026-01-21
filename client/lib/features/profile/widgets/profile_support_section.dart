import 'package:flutter/material.dart';
import 'profile_section_title.dart';
import 'profile_menu_item.dart';

/// Support section with help menu items.
class ProfileSupportSection extends StatelessWidget {
  final VoidCallback onHelpSupport;

  const ProfileSupportSection({super.key, required this.onHelpSupport});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ProfileSectionTitle(title: "SUPPORT"),
        ProfileMenuItem(
          icon: Icons.help_outline,
          title: "Help & Support",
          onTap: onHelpSupport,
        ),
      ],
    );
  }
}
