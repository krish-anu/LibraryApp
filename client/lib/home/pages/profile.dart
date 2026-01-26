import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/auth/pages/login_page.dart';
import 'package:libraryapp/auth/repositories/auth_local_repository.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/providers/theme_provider.dart';
import 'package:libraryapp/core/providers/current_user_notifier.dart';
import 'package:libraryapp/home/widgets/profile/profile_avatar.dart';
import 'package:libraryapp/home/widgets/profile/profile_stats.dart';
import 'package:libraryapp/home/widgets/profile/profile_menu_item.dart';
import 'package:libraryapp/home/widgets/profile/profile_toggle_item.dart';
import 'package:libraryapp/home/widgets/profile/profile_section_title.dart';
import 'package:libraryapp/core/widgets/common/common_app_bar.dart';
import 'package:libraryapp/data/repository/user_repository.dart';
import 'package:libraryapp/home/pages/edit_profile.dart';
import 'package:libraryapp/home/pages/help_support.dart';
import 'package:libraryapp/models/profile_stats.dart' as model;
import 'package:libraryapp/models/user_profile.dart';

/// User profile page with settings and preferences.
class Profile extends ConsumerStatefulWidget {
  const Profile({super.key});

  @override
  ConsumerState<Profile> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<Profile> {
  static const _profileImageUrl =
      "https://imgs.search.brave.com/3B_SYXXUKA9Ou_fT79_C_16EtIRigAAFd0itd7KO3oM/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9zdGF0/aWMudmVjdGVlenku/Y29tL3N5c3RlbS9y/ZXNvdXJjZXMvdGh1/bWJuYWlscy8wMjIv/OTU1LzI5Ni9zbWFs/bC9wb3J0cmFpdC1v/Zi1idXNpbmVzc3Bl/cnNvbi1hbmQtdGhlLWdlbmVyYXRpb24t/cGVyc29uYWxpdGll/cy1vZi1uZXctZXhl/Y3V0aXZlcy13aXRo/LWdvb2QtaWRlYXMt/cGVyc29uYWxpdHkt/YW5kLXZpc2lvbi1w/aG90by5qcGc";

  UserProfile? _userProfile;
  model.ProfileStats? _profileStats;
  bool _isLoading = true;
  String? _error;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _error = 'User not logged in';
      });
      return;
    }

    final repository = ref.read(userRepositoryProvider);

    // Fetch user profile
    final profileResult = await repository.getUserById(currentUser.id);
    profileResult.fold(
      (failure) {
        setState(() => _error = failure.message);
      },
      (profile) {
        setState(() => _userProfile = profile);
      },
    );

    // Fetch user stats
    final statsResult = await repository.getUserStats(currentUser.id);
    statsResult.fold(
      (failure) {
        // Stats may not be critical, so we don't set error
        debugPrint('Failed to load stats: ${failure.message}');
      },
      (stats) {
        setState(() => _profileStats = stats);
      },
    );

    setState(() => _isLoading = false);
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfile(userProfile: _userProfile),
      ),
    );

    if (result == true) {
      // Refresh profile data after edit
      setState(() => _isLoading = true);
      await _loadProfileData();
    }
  }

  void _navigateToHelpSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpSupport()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: CommonAppBar(
        title: 'Profile',
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _navigateToEditProfile,
            child: const Text(
              'Edit',
              style: TextStyle(color: Pallete.primaryLight),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Pallete.primaryLight),
            )
          : _error != null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              color: Pallete.primaryLight,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileHeader(currentUser),
                    const SizedBox(height: 24),
                    ProfileStats(stats: _profileStats),
                    const SizedBox(height: 24),
                    _buildAccountSection(),
                    const SizedBox(height: 16),
                    _buildPreferencesSection(isDark),
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
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Pallete.textSecondary, size: 64),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            style: TextStyle(color: Pallete.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadProfileData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Pallete.primaryLight,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ignore: strict_top_level_inference
  Widget _buildProfileHeader(dynamic currentUser) {
    final displayName = _userProfile?.name ?? currentUser?.userName ?? "User";
    final displayEmail = _userProfile?.email ?? currentUser?.email ?? "";
    final memberId = _userProfile?.memberId ?? currentUser?.id ?? "";

    return Column(
      children: [
        ProfileAvatar(imageUrl: _userProfile?.profileImage ?? _profileImageUrl),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          displayEmail,
          style: TextStyle(color: Pallete.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 4),
        _buildMemberId(memberId),
        const SizedBox(height: 8),
        if (_userProfile?.phone != null && _userProfile!.phone!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone_outlined,
                  color: Pallete.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _userProfile!.phone!,
                  style: TextStyle(color: Pallete.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        if (_userProfile?.joinedDate != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Pallete.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Member since ${_formatDate(_userProfile!.joinedDate!)}',
                  style: TextStyle(color: Pallete.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        _buildActiveBadge(),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildMemberId(String memberId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.badge_outlined, color: Pallete.textSecondary, size: 16),
        const SizedBox(width: 4),
        Text(
          "Member ID: $memberId",
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
      children: [
        const ProfileSectionTitle(title: "ACCOUNT"),
        ProfileMenuItem(
          icon: Icons.person_outline,
          title: "Personal Information",
          onTap: _navigateToEditProfile,
        ),
        // Removed Change Password and My Digital Card options per request.
      ],
    );
  }

  Widget _buildPreferencesSection(bool isDark) {
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
    return Column(
      children: [
        const ProfileSectionTitle(title: "SUPPORT"),
        ProfileMenuItem(
          icon: Icons.help_outline,
          title: "Help & Support",
          onTap: _navigateToHelpSupport,
        ),
      ],
    );
  }

  Widget _buildSignOutButton() {
    return TextButton(
      onPressed: _isSigningOut ? null : _showSignOutDialog,
      child: _isSigningOut
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFE57373),
              ),
            )
          : const Text(
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

  // ignore: unused_element
  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: Pallete.primaryLight,
      ),
    );
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      final authLocalRepository = ref.read(authLocalRepositoryProvider);
      await authLocalRepository.clearToken();
      ref.read(currentUserProvider.notifier).clearUser();

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Signed out successfully'),
          backgroundColor: Pallete.primaryLight,
        ),
      );

      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Login()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Failed to sign out. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Pallete.cardBackground,
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Pallete.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Pallete.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: _isSigningOut
                ? null
                : () async {
                    Navigator.pop(context);
                    await _signOut();
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
}
