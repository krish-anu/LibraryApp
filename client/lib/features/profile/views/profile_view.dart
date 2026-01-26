import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/providers/theme_provider.dart';
import 'package:libraryapp/core/widgets/common/common_app_bar.dart';
import 'package:libraryapp/features/profile/viewmodels/profile_viewmodel.dart';
import 'package:libraryapp/features/profile/widgets/widgets.dart';
import 'package:libraryapp/features/profile/views/edit_profile_view.dart';
import 'package:libraryapp/features/profile/views/help_support_view.dart';
import 'package:libraryapp/auth/pages/login_page.dart';

/// User profile page with settings and preferences.
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileViewModelProvider);
    final viewModel = ref.read(profileViewModelProvider.notifier);
    final isDark = ref.watch(isDarkProvider);

    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: CommonAppBar(
        title: 'Profile',
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _navigateToEditProfile(context, ref),
            child: const Text(
              'Edit',
              style: TextStyle(color: Pallete.primaryLight),
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Pallete.primaryLight),
            )
          : state.error != null
          ? _buildErrorState(context, viewModel, state.error!)
          : RefreshIndicator(
              onRefresh: () => viewModel.loadProfileData(),
              color: Pallete.primaryLight,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    ProfileHeader(
                      userProfile: state.userProfile,
                      currentUser: state.currentUser,
                      asgardeoUserInfo: state.asgardeoUserInfo,
                    ),
                    const SizedBox(height: 24),
                    ProfileStatsWidget(stats: state.profileStats),
                    const SizedBox(height: 24),
                    ProfileAccountSection(
                      onEditProfile: () => _navigateToEditProfile(context, ref),
                    ),
                    const SizedBox(height: 16),
                    ProfilePreferencesSection(
                      isDark: isDark,
                      onDarkModeChanged: (value) {
                        ref.read(isDarkProvider.notifier).state = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    ProfileSupportSection(
                      onHelpSupport: () => _navigateToHelpSupport(context),
                    ),
                    const SizedBox(height: 24),
                    ProfileSignOutButton(
                      isSigningOut: state.isSigningOut,
                      onSignOut: () => _showSignOutDialog(context, ref),
                    ),
                    const SizedBox(height: 8),
                    const ProfileVersionInfo(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ProfileViewModel viewModel,
    String error,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Pallete.textSecondary, size: 64),
          const SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(color: Pallete.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => viewModel.loadProfileData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Pallete.primaryLight,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEditProfile(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final state = ref.read(profileViewModelProvider);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileView(userProfile: state.userProfile),
      ),
    );

    if (result == true) {
      ref.read(profileViewModelProvider.notifier).loadProfileData();
    }
  }

  void _navigateToHelpSupport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpSupportView()),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: Pallete.primaryLight,
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Pallete.cardBackground,
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Pallete.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: Pallete.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _signOut(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await ref.read(profileViewModelProvider.notifier).signOut();

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Signed out successfully'),
          backgroundColor: Pallete.primaryLight,
        ),
      );

      await navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Login()),
        (route) => false,
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to sign out. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
