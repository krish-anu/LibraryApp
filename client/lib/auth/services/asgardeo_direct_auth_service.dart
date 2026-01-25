import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Asgardeo Direct Authentication Configuration
/// Uses Resource Owner Password Credentials (ROPC) grant for in-app authentication
class AsgardeoDirectConfig {
  static const String clientId = '1O70sZaVwlin70uGYeJlfKhvv2sa';
  static const String clientSecret = ''; // Add if required by your Asgardeo app
  static const String baseUrl = 'https://api.eu.asgardeo.io/t/orgd2ib6';
  static const String tokenEndpoint = '$baseUrl/oauth2/token';
  static const String userInfoEndpoint = '$baseUrl/oauth2/userinfo';
  static const String registerEndpoint = '$baseUrl/scim2/Me';
  static const String introspectEndpoint = '$baseUrl/oauth2/introspect';
  static const List<String> scopes = ['openid', 'profile', 'email'];
}

/// Response from token endpoint
class AsgardeoTokenResponse {
  final String accessToken;
  final String? refreshToken;
  final String? idToken;
  final int expiresIn;
  final String tokenType;

  AsgardeoTokenResponse({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
    required this.expiresIn,
    required this.tokenType,
  });

  factory AsgardeoTokenResponse.fromJson(Map<String, dynamic> json) {
    return AsgardeoTokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      idToken: json['id_token'] as String?,
      expiresIn: json['expires_in'] as int,
      tokenType: json['token_type'] as String,
    );
  }
}

/// User info from Asgardeo
class AsgardeoUser {
  final String? sub;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? phoneNumber;
  final String? picture;
  final bool emailVerified;

  AsgardeoUser({
    this.sub,
    this.email,
    this.firstName,
    this.lastName,
    this.username,
    this.phoneNumber,
    this.picture,
    this.emailVerified = false,
  });

  factory AsgardeoUser.fromJson(Map<String, dynamic> json) {
    return AsgardeoUser(
      sub: json['sub'] as String?,
      email: json['email'] as String?,
      firstName: json['given_name'] as String?,
      lastName: json['family_name'] as String?,
      username: json['username'] ?? json['preferred_username'] as String?,
      phoneNumber: json['phone_number'] as String?,
      picture: json['picture'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
    );
  }

  String get fullName {
    final parts = [firstName, lastName].where((s) => s != null && s.isNotEmpty);
    return parts.isNotEmpty ? parts.join(' ') : (username ?? email ?? '');
  }
}

/// Result wrapper for auth operations
class AuthResult<T> {
  final T? data;
  final String? error;
  final bool success;

  AuthResult.success(this.data) : success = true, error = null;

  AuthResult.failure(this.error) : success = false, data = null;
}

/// Service for direct Asgardeo authentication (no browser redirect)
class AsgardeoDirectAuthService {
  /// Login using username/password with Resource Owner Password Grant
  Future<AuthResult<AsgardeoTokenResponse>> login({
    required String username,
    required String password,
  }) async {
    try {
      debugPrint('Attempting direct login to Asgardeo...');

      final body = {
        'grant_type': 'password',
        'client_id': AsgardeoDirectConfig.clientId,
        'username': username,
        'password': password,
        'scope': AsgardeoDirectConfig.scopes.join(' '),
      };

      // Add client secret if configured
      if (AsgardeoDirectConfig.clientSecret.isNotEmpty) {
        body['client_secret'] = AsgardeoDirectConfig.clientSecret;
      }

      final response = await http.post(
        Uri.parse(AsgardeoDirectConfig.tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      debugPrint('Login response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final tokenResponse = AsgardeoTokenResponse.fromJson(json);
        debugPrint('Login successful!');
        return AuthResult.success(tokenResponse);
      } else {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        final errorDescription =
            errorJson['error_description'] ??
            errorJson['error'] ??
            'Login failed';
        debugPrint('Login failed: $errorDescription');
        return AuthResult.failure(errorDescription.toString());
      }
    } catch (e, s) {
      debugPrint('Login error: $e\n$s');
      return AuthResult.failure('Connection error: ${e.toString()}');
    }
  }

  /// Get user info using access token
  Future<AuthResult<AsgardeoUser>> getUserInfo(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse(AsgardeoDirectConfig.userInfoEndpoint),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResult.success(AsgardeoUser.fromJson(json));
      } else {
        return AuthResult.failure(
          'Failed to get user info: ${response.statusCode}',
        );
      }
    } catch (e) {
      return AuthResult.failure('Error getting user info: ${e.toString()}');
    }
  }

  /// Register a new user using SCIM2 endpoint
  /// Note: This requires the SCIM2 API to be enabled in Asgardeo
  Future<AuthResult<Map<String, dynamic>>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? username,
  }) async {
    try {
      debugPrint('Attempting to register user in Asgardeo...');

      // SCIM2 user schema
      final scimUser = {
        'schemas': ['urn:ietf:params:scim:schemas:core:2.0:User'],
        'userName': username ?? email,
        'password': password,
        'emails': [
          {'value': email, 'primary': true},
        ],
        'name': {'givenName': firstName, 'familyName': lastName},
      };

      final response = await http.post(
        Uri.parse(AsgardeoDirectConfig.registerEndpoint),
        headers: {
          'Content-Type': 'application/scim+json',
          'Accept': 'application/scim+json',
        },
        body: jsonEncode(scimUser),
      );

      debugPrint('Register response status: ${response.statusCode}');
      debugPrint('Register response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('Registration successful!');
        return AuthResult.success(json);
      } else {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        final errorDetail =
            errorJson['detail'] ??
            errorJson['scimType'] ??
            errorJson['description'] ??
            'Registration failed';
        debugPrint('Registration failed: $errorDetail');
        return AuthResult.failure(errorDetail.toString());
      }
    } catch (e, s) {
      debugPrint('Registration error: $e\n$s');
      return AuthResult.failure('Connection error: ${e.toString()}');
    }
  }

  /// Refresh access token using refresh token
  Future<AuthResult<AsgardeoTokenResponse>> refreshToken(
    String refreshToken,
  ) async {
    try {
      final body = {
        'grant_type': 'refresh_token',
        'client_id': AsgardeoDirectConfig.clientId,
        'refresh_token': refreshToken,
      };

      if (AsgardeoDirectConfig.clientSecret.isNotEmpty) {
        body['client_secret'] = AsgardeoDirectConfig.clientSecret;
      }

      final response = await http.post(
        Uri.parse(AsgardeoDirectConfig.tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResult.success(AsgardeoTokenResponse.fromJson(json));
      } else {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResult.failure(
          errorJson['error_description'] ?? 'Token refresh failed',
        );
      }
    } catch (e) {
      return AuthResult.failure('Error refreshing token: ${e.toString()}');
    }
  }

  /// Revoke access token (logout)
  Future<bool> revokeToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${AsgardeoDirectConfig.baseUrl}/oauth2/revoke'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'token': token, 'client_id': AsgardeoDirectConfig.clientId},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error revoking token: $e');
      return false;
    }
  }
}
