import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:libraryapp/models/user_profile.dart';
import 'package:libraryapp/models/profile_stats.dart';
import 'package:libraryapp/models/user.dart';
import 'package:libraryapp/data/repository/user_repository.dart';
import 'package:libraryapp/core/providers/current_user_notifier.dart';
import 'package:libraryapp/auth/repositories/auth_local_repository.dart';
import 'package:libraryapp/auth/providers/asgardeo_direct_provider.dart';
import 'package:libraryapp/auth/services/asgardeo_direct_auth_service.dart';

part 'profile_viewmodel.g.dart';

/// State class for Profile page
class ProfileState {
  final UserProfile? userProfile;
  final ProfileStats? profileStats;
  final User? currentUser;
  final AsgardeoUser? asgardeoUserInfo;
  final bool isLoading;
  final bool isSigningOut;
  final String? error;

  const ProfileState({
    this.userProfile,
    this.profileStats,
    this.currentUser,
    this.asgardeoUserInfo,
    this.isLoading = false,
    this.isSigningOut = false,
    this.error,
  });

  ProfileState copyWith({
    UserProfile? userProfile,
    ProfileStats? profileStats,
    User? currentUser,
    AsgardeoUser? asgardeoUserInfo,
    bool? isLoading,
    bool? isSigningOut,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      userProfile: userProfile ?? this.userProfile,
      profileStats: profileStats ?? this.profileStats,
      currentUser: currentUser ?? this.currentUser,
      asgardeoUserInfo: asgardeoUserInfo ?? this.asgardeoUserInfo,
      isLoading: isLoading ?? this.isLoading,
      isSigningOut: isSigningOut ?? this.isSigningOut,
      error: clearError ? null : (error ?? this.error),
    );
  }

  String get displayName => asgardeoUserInfo?.fullName.isNotEmpty == true
      ? asgardeoUserInfo!.fullName
      : userProfile?.name ?? currentUser?.userName ?? 'User';
  String get displayEmail =>
      asgardeoUserInfo?.email ?? userProfile?.email ?? currentUser?.email ?? '';
  String get memberId =>
      asgardeoUserInfo?.sub ?? userProfile?.memberId ?? currentUser?.id ?? '';
  String? get profileImage =>
      asgardeoUserInfo?.picture ?? userProfile?.profileImage;
  String? get phone => asgardeoUserInfo?.phoneNumber ?? userProfile?.phone;
  String? get country => null; // AsgardeoUser doesn't have country field
  String? get dateOfBirth => null; // AsgardeoUser doesn't have DOB field
  DateTime? get joinedDate => userProfile?.joinedDate;
}

@riverpod
class ProfileViewModel extends _$ProfileViewModel {
  @override
  ProfileState build() {
    // Defer loading until after build completes to avoid accessing state before initialization
    Future.microtask(() => loadProfileData());
    return const ProfileState(isLoading: true);
  }

  Future<void> loadProfileData() async {
    if (!ref.mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);

    // First, check for Asgardeo user info
    final asgardeoState = ref.read(asgardeoDirectAuthProvider);
    if (asgardeoState.isLoggedIn) {
      state = state.copyWith(asgardeoUserInfo: asgardeoState.user);

      // If we don't have user info yet, try to retrieve it
      if (asgardeoState.user == null && asgardeoState.accessToken != null) {
        await ref.read(asgardeoDirectAuthProvider.notifier).getUserInfo();
        if (!ref.mounted) return;
        final updatedState = ref.read(asgardeoDirectAuthProvider);
        state = state.copyWith(asgardeoUserInfo: updatedState.user);
      }

      final asgardeoUserId = state.asgardeoUserInfo?.sub;
      if (asgardeoUserId != null && asgardeoUserId.isNotEmpty) {
        await Future.wait([
          _loadUserProfile(asgardeoUserId),
          _loadUserStats(asgardeoUserId),
        ]);
      }

      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false);
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: 'User not logged in');
      return;
    }

    if (!ref.mounted) return;
    state = state.copyWith(currentUser: currentUser);

    await Future.wait([
      _loadUserProfile(currentUser.id),
      _loadUserStats(currentUser.id),
    ]);

    if (!ref.mounted) return;
    state = state.copyWith(isLoading: false);
  }

  Future<void> _loadUserProfile(String userId) async {
    if (!ref.mounted) return;
    try {
      final repository = ref.read(userRepositoryProvider);
      final result = await repository.getUserById(userId);
      if (!ref.mounted) return;
      result.fold(
        (failure) => state = state.copyWith(error: failure.message),
        (profile) => state = state.copyWith(userProfile: profile),
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _loadUserStats(String userId) async {
    if (!ref.mounted) return;
    try {
      final repository = ref.read(userRepositoryProvider);
      final result = await repository.getUserStats(userId);
      if (!ref.mounted) return;
      result.fold((failure) {
        // Stats may not be critical, don't set error
      }, (stats) => state = state.copyWith(profileStats: stats));
    } catch (e) {
      // Don't fail for stats errors
    }
  }

  Future<void> refresh() async {
    await loadProfileData();
  }

  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return false;

    try {
      final repository = ref.read(userRepositoryProvider);
      final result = await repository.updateUser(currentUser.id, updateData);
      return result.fold(
        (failure) {
          state = state.copyWith(error: failure.message);
          return false;
        },
        (updatedProfile) {
          state = state.copyWith(userProfile: updatedProfile);
          // Update the current user provider
          ref
              .read(currentUserProvider.notifier)
              .addUser(
                currentUser.copyWith(
                  userName: updatedProfile.name,
                  email: updatedProfile.email,
                ),
              );
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> signOut() async {
    state = state.copyWith(isSigningOut: true);
    try {
      // Check if logged in via Asgardeo
      final asgardeoState = ref.read(asgardeoDirectAuthProvider);
      if (asgardeoState.isLoggedIn) {
        await ref.read(asgardeoDirectAuthProvider.notifier).logout();
      }

      final authLocal = ref.read(authLocalRepositoryProvider);
      await authLocal.clearToken();
      ref.read(currentUserProvider.notifier).clearUser();
      state = state.copyWith(isSigningOut: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSigningOut: false, error: e.toString());
      return false;
    }
  }
}
