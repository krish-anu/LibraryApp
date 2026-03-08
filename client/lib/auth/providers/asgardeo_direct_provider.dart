import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libraryapp/auth/services/asgardeo_direct_auth_service.dart';

part 'asgardeo_direct_provider.g.dart';

/// State for direct Asgardeo authentication
class AsgardeoDirectState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? accessToken;
  final String? refreshToken;
  final String? idToken;
  final String? error;
  final AsgardeoUser? user;

  const AsgardeoDirectState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.accessToken,
    this.refreshToken,
    this.idToken,
    this.error,
    this.user,
  });

  AsgardeoDirectState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? accessToken,
    String? refreshToken,
    String? idToken,
    String? error,
    AsgardeoUser? user,
    bool clearError = false,
    bool clearTokens = false,
    bool clearUser = false,
  }) {
    return AsgardeoDirectState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      accessToken: clearTokens ? null : (accessToken ?? this.accessToken),
      refreshToken: clearTokens ? null : (refreshToken ?? this.refreshToken),
      idToken: clearTokens ? null : (idToken ?? this.idToken),
      error: clearError ? null : (error ?? this.error),
      user: clearUser ? null : (user ?? this.user),
    );
  }
}

/// Provider for direct Asgardeo authentication
@Riverpod(keepAlive: true)
class AsgardeoDirectAuth extends _$AsgardeoDirectAuth {
  final AsgardeoDirectAuthService _authService = AsgardeoDirectAuthService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'asgardeo_access_token';
  static const String _refreshTokenKey = 'asgardeo_refresh_token';
  static const String _idTokenKey = 'asgardeo_id_token';

  @override
  AsgardeoDirectState build() {
    // Try to restore session on startup
    _restoreSession();
    return const AsgardeoDirectState();
  }

  /// Restore session from secure storage
  Future<void> _restoreSession() async {
    try {
      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      final idToken = await _secureStorage.read(key: _idTokenKey);

      if (accessToken != null) {
        state = state.copyWith(
          isLoggedIn: true,
          accessToken: accessToken,
          refreshToken: refreshToken,
          idToken: idToken,
        );

        // Fetch user info
        await getUserInfo();
      }
    } catch (e) {
      debugPrint('Error restoring session: $e');
    }
  }

  /// Save tokens to secure storage
  Future<void> _saveTokens(AsgardeoTokenResponse tokens) async {
    try {
      await _secureStorage.write(
        key: _accessTokenKey,
        value: tokens.accessToken,
      );
      if (tokens.refreshToken != null) {
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: tokens.refreshToken!,
        );
      }
      if (tokens.idToken != null) {
        await _secureStorage.write(key: _idTokenKey, value: tokens.idToken!);
      }
    } catch (e) {
      debugPrint('Error saving tokens: $e');
    }
  }

  /// Clear tokens from secure storage
  Future<void> _clearTokens() async {
    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _idTokenKey);
    } catch (e) {
      debugPrint('Error clearing tokens: $e');
    }
  }

  /// Login with username and password
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authService.login(
      username: username,
      password: password,
    );

    if (result.success && result.data != null) {
      final tokens = result.data!;
      await _saveTokens(tokens);

      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        idToken: tokens.idToken,
      );

      final syncResult = await _authService.syncUserWithBackend(
        accessToken: tokens.accessToken,
      );
      if (!syncResult.success) {
        debugPrint(
          'Backend user sync failed: ${syncResult.error ?? 'unknown error'}',
        );
      }

      // Fetch user info after login
      await getUserInfo(syncWithBackend: false);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error ?? 'Login failed',
      );
      return false;
    }
  }

  /// Register a new user
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? username,
    String? phoneNumber,
    String? streetAddress,
    String? locality,
    String? region,
    String? postalCode,
    String? country,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authService.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      username: username,
      phoneNumber: phoneNumber,
      streetAddress: streetAddress,
      locality: locality,
      region: region,
      postalCode: postalCode,
      country: country,
    );

    if (result.success) {
      state = state.copyWith(isLoading: false);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error ?? 'Registration failed',
      );
      return false;
    }
  }

  /// Update user information
  Future<bool> updateUserInfo({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? streetAddress,
    String? locality,
    String? region,
    String? postalCode,
    String? country,
    String? picture,
  }) async {
    if (state.accessToken == null) {
      state = state.copyWith(error: 'No access token available');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authService.updateUserInfo(
      accessToken: state.accessToken!,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      streetAddress: streetAddress,
      locality: locality,
      region: region,
      postalCode: postalCode,
      country: country,
      picture: picture,
    );

    if (result.success) {
      // Refresh user info after update
      await getUserInfo();
      state = state.copyWith(isLoading: false);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error ?? 'Update failed',
      );
      return false;
    }
  }

  /// Get user info from Asgardeo
  Future<bool> getUserInfo({bool syncWithBackend = true}) async {
    if (state.accessToken == null) {
      state = state.copyWith(error: 'No access token available');
      return false;
    }

    final result = await _authService.getUserInfo(state.accessToken!);

    if (result.success && result.data != null) {
      state = state.copyWith(user: result.data);
      if (syncWithBackend) {
        final syncResult = await _authService.syncUserWithBackend(
          accessToken: state.accessToken!,
        );
        if (!syncResult.success) {
          debugPrint(
            'Backend user sync failed: ${syncResult.error ?? 'unknown error'}',
          );
        }
      }
      return true;
    } else {
      state = state.copyWith(error: result.error);
      return false;
    }
  }

  /// Refresh the access token
  Future<bool> refreshAccessToken() async {
    if (state.refreshToken == null) {
      return false;
    }

    final result = await _authService.refreshToken(state.refreshToken!);

    if (result.success && result.data != null) {
      final tokens = result.data!;
      await _saveTokens(tokens);

      state = state.copyWith(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken ?? state.refreshToken,
        idToken: tokens.idToken ?? state.idToken,
      );
      return true;
    }

    return false;
  }

  /// Logout and clear session
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    // Revoke token on server
    if (state.accessToken != null) {
      final result = await _authService.logoutWithBackend(
        accessToken: state.accessToken!,
      );
      if (!result.success) {
        await _authService.revokeToken(state.accessToken!);
      }
    }

    // Clear local storage
    await _clearTokens();

    // Reset state
    state = const AsgardeoDirectState();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
