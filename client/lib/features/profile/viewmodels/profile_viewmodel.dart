import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:libraryapp/models/user_profile.dart';
import 'package:libraryapp/models/profile_stats.dart';
import 'package:libraryapp/models/user.dart';
import 'package:libraryapp/data/repository/user_repository.dart';
import 'package:libraryapp/core/providers/current_user_notifier.dart';
import 'package:libraryapp/auth/repositories/auth_local_repository.dart';

part 'profile_viewmodel.g.dart';

/// State class for Profile page
class ProfileState {
  final UserProfile? userProfile;
  final ProfileStats? profileStats;
  final User? currentUser;
  final bool isLoading;
  final bool isSigningOut;
  final String? error;

  const ProfileState({
    this.userProfile,
    this.profileStats,
    this.currentUser,
    this.isLoading = false,
    this.isSigningOut = false,
    this.error,
  });

  ProfileState copyWith({
    UserProfile? userProfile,
    ProfileStats? profileStats,
    User? currentUser,
    bool? isLoading,
    bool? isSigningOut,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      userProfile: userProfile ?? this.userProfile,
      profileStats: profileStats ?? this.profileStats,
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      isSigningOut: isSigningOut ?? this.isSigningOut,
      error: clearError ? null : (error ?? this.error),
    );
  }

  String get displayName =>
      userProfile?.name ?? currentUser?.userName ?? 'User';
  String get displayEmail => userProfile?.email ?? currentUser?.email ?? '';
  String get memberId => userProfile?.memberId ?? currentUser?.id ?? '';
  String? get profileImage => userProfile?.profileImage;
  DateTime? get joinedDate => userProfile?.joinedDate;
}

@riverpod
class ProfileViewModel extends _$ProfileViewModel {
  @override
  ProfileState build() {
    loadProfileData();
    return const ProfileState(isLoading: true);
  }

  Future<void> loadProfileData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      state = state.copyWith(isLoading: false, error: 'User not logged in');
      return;
    }

    state = state.copyWith(currentUser: currentUser);

    await Future.wait([
      _loadUserProfile(currentUser.id),
      _loadUserStats(currentUser.id),
    ]);

    state = state.copyWith(isLoading: false);
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      final repository = ref.read(userRepositoryProvider);
      final result = await repository.getUserById(userId);
      result.fold(
        (failure) => state = state.copyWith(error: failure.message),
        (profile) => state = state.copyWith(userProfile: profile),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _loadUserStats(String userId) async {
    try {
      final repository = ref.read(userRepositoryProvider);
      final result = await repository.getUserStats(userId);
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
