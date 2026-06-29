import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:libraryapp/auth/config/asgardeo_runtime_config.dart';

part 'asgardeo_auth_provider.g.dart';

/// Asgardeo OAuth Configuration
class AsgardeoConfig {
  static String get clientId => AsgardeoRuntimeConfig.clientId;
  static String get redirectUrl => AsgardeoRuntimeConfig.redirectUrl;
  static String get discoveryUrl => AsgardeoRuntimeConfig.discoveryUrl;
  static String get userInfoEndpoint => AsgardeoRuntimeConfig.userInfoEndpoint;
  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'books_read',
    'books_manage',
    'loans_manage',
  ];
}

/// State class for Asgardeo authentication
class AsgardeoAuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? idToken;
  final String? accessToken;
  final String? error;
  final AsgardeoUserInfo? userInfo;

  const AsgardeoAuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.idToken,
    this.accessToken,
    this.error,
    this.userInfo,
  });

  AsgardeoAuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? idToken,
    String? accessToken,
    String? error,
    AsgardeoUserInfo? userInfo,
    bool clearError = false,
    bool clearTokens = false,
  }) {
    return AsgardeoAuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      idToken: clearTokens ? null : (idToken ?? this.idToken),
      accessToken: clearTokens ? null : (accessToken ?? this.accessToken),
      error: clearError ? null : (error ?? this.error),
      userInfo: clearTokens ? null : (userInfo ?? this.userInfo),
    );
  }
}

/// User info retrieved from Asgardeo
class AsgardeoUserInfo {
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? email;
  final String? dateOfBirth;
  final String? country;
  final String? mobile;
  final String? photo;
  final String? sub;

  const AsgardeoUserInfo({
    this.name,
    this.firstName,
    this.lastName,
    this.username,
    this.email,
    this.dateOfBirth,
    this.country,
    this.mobile,
    this.photo,
    this.sub,
  });

  factory AsgardeoUserInfo.fromJson(Map<String, dynamic> json) {
    return AsgardeoUserInfo(
      name: json['name'] as String?,
      firstName: json['given_name'] as String?,
      lastName: json['family_name'] as String?,
      username: json['username'] ?? json['preferred_username'] as String?,
      email: json['email'] as String?,
      dateOfBirth: json['birthdate'] as String?,
      country: json['address'] != null
          ? (json['address'] as Map<String, dynamic>)['country'] as String?
          : null,
      mobile: json['phone_number'] as String?,
      photo: json['picture'] as String?,
      sub: json['sub'] as String?,
    );
  }

  String get fullName {
    final firstAndLast = [
      firstName,
      lastName,
    ].map((s) => s?.trim()).where((s) => s != null && s.isNotEmpty).join(' ');
    if (firstAndLast.isNotEmpty) {
      return firstAndLast;
    }
    return name?.trim().isNotEmpty == true
        ? name!.trim()
        : (username?.trim().isNotEmpty == true
              ? username!.trim()
              : (email ?? ''));
  }
}

/// Asgardeo Authentication Provider
@Riverpod(keepAlive: true)
class AsgardeoAuth extends _$AsgardeoAuth {
  final FlutterAppAuth _appAuth = FlutterAppAuth();

  @override
  AsgardeoAuthState build() {
    return const AsgardeoAuthState();
  }

  /// Perform login with Asgardeo OAuth
  Future<bool> login() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      AsgardeoRuntimeConfig.ensureConfigured();
      debugPrint('Starting Asgardeo login...');

      final AuthorizationTokenResponse result = await _appAuth
          .authorizeAndExchangeCode(
            AuthorizationTokenRequest(
              AsgardeoConfig.clientId,
              AsgardeoConfig.redirectUrl,
              discoveryUrl: AsgardeoConfig.discoveryUrl,
              scopes: AsgardeoConfig.scopes,
              promptValues: ['login'], // Force login prompt every time
            ),
          );

      debugPrint('Login successful! Access token received.');
      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        idToken: result.idToken,
        accessToken: result.accessToken,
      );
      return true;
    } catch (e, s) {
      debugPrint('Error while login to Asgardeo: $e - stack: $s');
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        error: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Retrieve user details from Asgardeo userinfo endpoint
  Future<AsgardeoUserInfo?> retrieveUserDetails() async {
    if (state.accessToken == null) {
      state = state.copyWith(error: 'No access token available');
      return null;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      AsgardeoRuntimeConfig.ensureConfigured();
      final response = await http.get(
        Uri.parse(AsgardeoConfig.userInfoEndpoint),
        headers: {'Authorization': 'Bearer ${state.accessToken}'},
      );

      if (response.statusCode == 200) {
        final profile = jsonDecode(response.body) as Map<String, dynamic>;
        final userInfo = AsgardeoUserInfo.fromJson(profile);

        state = state.copyWith(isLoading: false, userInfo: userInfo);
        return userInfo;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to get user profile: ${response.statusCode}',
        );
        return null;
      }
    } catch (e, s) {
      debugPrint('Error retrieving user details: $e - stack: $s');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to retrieve user details: ${e.toString()}',
      );
      return null;
    }
  }

  /// Perform logout from Asgardeo
  Future<bool> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      AsgardeoRuntimeConfig.ensureConfigured();
      await _appAuth.endSession(
        EndSessionRequest(
          idTokenHint: state.idToken,
          postLogoutRedirectUrl: AsgardeoConfig.redirectUrl,
          discoveryUrl: AsgardeoConfig.discoveryUrl,
        ),
      );

      state = const AsgardeoAuthState();
      return true;
    } catch (e, s) {
      debugPrint('Error while logout from Asgardeo: $e - stack: $s');
      // Even if logout fails on server, clear local state
      state = const AsgardeoAuthState();
      return false;
    }
  }

  /// Clear any error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
