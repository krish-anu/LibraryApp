import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/models/user.dart';
import 'package:libraryapp/models/user_profile.dart';
import 'package:libraryapp/auth/services/asgardeo_direct_auth_service.dart';
import 'profile_avatar.dart';

/// Profile header displaying user info.
class ProfileHeader extends StatelessWidget {
  static const _defaultProfileImageUrl =
      "https://imgs.search.brave.com/3B_SYXXUKA9Ou_fT79_C_16EtIRigAAFd0itd7KO3oM/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9zdGF0/aWMudmVjdGVlenku/Y29tL3N5c3RlbS9y/ZXNvdXJjZXMvdGh1/bWJuYWlscy8wMjIv/OTU1LzI5Ni9zbWFs/bC9wb3J0cmFpdC1v/Zi1idXNpbmVzc3Bl/cnNvbi1hbmQtdGhlLWdlbmVyYXRpb24t/cGVyc29uYWxpdGll/cy1vZi1uZXctZXhl/Y3V0aXZlcy13aXRo/LWdvb2QtaWRlYXMt/cGVyc29uYWxpdHkt/YW5kLXZpc2lvbi1w/aG90by5qcGc";

  final UserProfile? userProfile;
  final User? currentUser;
  final AsgardeoUser? asgardeoUserInfo;

  const ProfileHeader({
    super.key,
    this.userProfile,
    this.currentUser,
    this.asgardeoUserInfo,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = asgardeoUserInfo?.fullName.isNotEmpty == true
        ? asgardeoUserInfo!.fullName
        : userProfile?.name ?? currentUser?.userName ?? "User";
    final displayEmail =
        asgardeoUserInfo?.email ??
        userProfile?.email ??
        currentUser?.email ??
        "";
    final memberId =
        asgardeoUserInfo?.sub ?? userProfile?.memberId ?? currentUser?.id ?? "";
    final phone = asgardeoUserInfo?.phoneNumber ?? userProfile?.phone;
    final profileImage =
        asgardeoUserInfo?.picture ??
        userProfile?.profileImage ??
        _defaultProfileImageUrl;

    return Column(
      children: [
        ProfileAvatar(imageUrl: profileImage),
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
        if (phone != null && phone.isNotEmpty)
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
                  phone,
                  style: TextStyle(color: Pallete.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        if (userProfile?.joinedDate != null)
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
                  'Member since ${_formatDate(userProfile!.joinedDate!)}',
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
}
