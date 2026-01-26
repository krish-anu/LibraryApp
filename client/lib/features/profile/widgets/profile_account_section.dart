import 'package:flutter/material.dart';
import 'profile_section_title.dart';
import 'profile_menu_item.dart';

/// Account section with menu items.
class ProfileAccountSection extends StatelessWidget {
  final VoidCallback onEditProfile;
  

  const ProfileAccountSection({
    super.key,
    required this.onEditProfile,
    
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
        // Removed Change Password and My Digital Card options per request.
      ],
    );
  }
}
