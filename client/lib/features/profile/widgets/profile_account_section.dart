import 'package:flutter/material.dart';
import 'profile_section_title.dart';
import 'profile_menu_item.dart';

/// Account section with menu items.
class ProfileAccountSection extends StatelessWidget {
  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onDigitalCard;

  const ProfileAccountSection({
    super.key,
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onDigitalCard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ProfileSectionTitle(title: "ACCOUNT"),
        ProfileMenuItem(
          icon: Icons.person_outline,
          title: "Personal Information",
          onTap: onEditProfile,
        ),
        ProfileMenuItem(
          icon: Icons.lock_outline,
          title: "Change Password",
          onTap: onChangePassword,
        ),
        ProfileMenuItem(
          icon: Icons.credit_card,
          title: "My Digital Card",
          onTap: onDigitalCard,
        ),
      ],
    );
  }
}
