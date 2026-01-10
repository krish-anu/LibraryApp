import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/providers/theme_provider.dart';
import 'package:libraryapp/core/providers/current_user_notifier.dart';
import 'package:libraryapp/home/widgets/profile/profile_avatar.dart';
import 'package:libraryapp/home/widgets/profile/profile_stats.dart';
import 'package:libraryapp/home/widgets/profile/profile_menu_item.dart';
import 'package:libraryapp/home/widgets/profile/profile_toggle_item.dart';
import 'package:libraryapp/home/widgets/profile/profile_section_title.dart';
import 'package:libraryapp/core/widgets/common/common_app_bar.dart';

/// User profile page with settings and preferences.
class Profile extends ConsumerWidget {
  const Profile({super.key});

  static const _profileImageUrl =
      "https://imgs.search.brave.com/3B_SYXXUKA9Ou_fT79_C_16EtIRigAAFd0itd7KO3oM/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9zdGF0/aWMudmVjdGVlenku/Y29tL3N5c3RlbS9y/ZXNvdXJjZXMvdGh1/bWJuYWlscy8wMjIv/OTU1LzI5Ni9zbWFs/bC9wb3J0cmFpdC1v/Zi1idXNpbmVzc3Bl/cnNvbi1hbmQtdGhl/LWdlbmVyYXRpb24t/cGVyc29uYWxpdGll/cy1vZi1uZXctZXhl/Y3V0aXZlcy13aXRo/LWdvb2QtaWRlYXMt/cGVyc29uYWxpdHkt/YW5kLXZpc2lvbi1w/aG90by5qcGc";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: const CommonAppBar(
        title: 'Profile',
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: null,
            child: Text('Edit', style: TextStyle(color: Pallete.primaryLight)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileHeader(currentUser),
            const SizedBox(height: 24),
            const ProfileStats(),
            const SizedBox(height: 24),
            _buildAccountSection(),
            const SizedBox(height: 16),
            _buildPreferencesSection(ref, isDark),
            const SizedBox(height: 16),
            _buildSupportSection(),
            const SizedBox(height: 24),
            _buildSignOutButton(),
            const SizedBox(height: 8),
            _buildVersionInfo(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // AppBar moved to CommonAppBar to reduce duplication across pages.

  Widget _buildProfileHeader(currentUser) {
    return Column(
      children: [
        const ProfileAvatar(imageUrl: _profileImageUrl),
        const SizedBox(height: 16),
        Text(
          currentUser?.userName ?? "Jane Doe",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        _buildMemberId(currentUser),
        const SizedBox(height: 12),
        _buildActiveBadge(),
      ],
    );
  }

  Widget _buildMemberId(currentUser) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.badge_outlined, color: Pallete.textSecondary, size: 16),
        const SizedBox(width: 4),
        Text(
          "Member ID: ${currentUser?.id ?? '#8392102'}",
          style: TextStyle(color: Pallete.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildActiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Pallete.scaffoldBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Pallete.primaryLight, size: 16),
          SizedBox(width: 4),
          Text(
            "ACTIVE MEMBER",
            style: TextStyle(
              color: Pallete.primaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Column(
      children: const [
        ProfileSectionTitle(title: "ACCOUNT"),
        ProfileMenuItem(
          icon: Icons.person_outline,
          title: "Personal Information",
        ),
        ProfileMenuItem(icon: Icons.lock_outline, title: "Change Password"),
        ProfileMenuItem(icon: Icons.credit_card, title: "My Digital Card"),
      ],
    );
  }

  Widget _buildPreferencesSection(WidgetRef ref, bool isDark) {
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
          onChanged: (value) => ref.read(isDarkProvider.notifier).state = value,
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return const Column(
      children: [
        ProfileSectionTitle(title: "SUPPORT"),
        ProfileMenuItem(icon: Icons.help_outline, title: "Help & Support"),
      ],
    );
  }

  Widget _buildSignOutButton() {
    return TextButton(
      onPressed: () {},
      child: const Text(
        "← Sign Out",
        style: TextStyle(color: Color(0xFFE57373), fontSize: 16),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Text(
      "App Version 1.0.2",
      style: TextStyle(color: Pallete.textSecondary, fontSize: 12),
    );
  }
}
