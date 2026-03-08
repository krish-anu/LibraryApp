import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:libraryapp/core/constants/server_constant.dart';

/// Asgardeo Direct Authentication Configuration
/// Uses Resource Owner Password Credentials (ROPC) grant for in-app authentication
class AsgardeoDirectConfig {
  static const String clientId = String.fromEnvironment(
    'ASGARDEO_CLIENT_ID',
    defaultValue: '1O70sZaVwlin70uGYeJlfKhvv2sa',
  );
  // Public client - no client secret needed for mobile apps
  static const String clientSecret = '';
  static const String baseUrl = String.fromEnvironment(
    'ASGARDEO_BASE_URL',
    defaultValue: 'https://api.eu.asgardeo.io/t/orgd2ib6',
  );
  static const String tokenEndpoint = '$baseUrl/oauth2/token';
  static const String userInfoEndpoint = '$baseUrl/oauth2/userinfo';
  static const String scim2Endpoint = '$baseUrl/scim2';
  static const String scim2MeEndpoint = '$baseUrl/scim2/Me';
  static const String scim2UsersEndpoint = '$baseUrl/scim2/Users';
  // Self-registration endpoint
  static const String selfRegisterEndpoint =
      '$baseUrl/api/identity/user/v1.0/me';
  // Alternative registration endpoint
  static const String publicRegisterEndpoint =
      '$baseUrl/api/asgardeo/selfservice/v1/self-register';
  static const String introspectEndpoint = '$baseUrl/oauth2/introspect';

  // Browser-based registration URL (Asgardeo hosted page)
  // This is the officially supported way for Asgardeo cloud
  static const String registrationUrl =
      '$baseUrl/accountrecoveryendpoint/register.do?client_id=$clientId';

  // Alternative: Asgardeo's self-service portal
  static const String selfServicePortalUrl =
      'https://myaccount.eu.asgardeo.io/t/orgd2ib6';

  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'phone',
    'address',
  ];
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
  final bool phoneNumberVerified;
  final String? picture;
  final bool emailVerified;
  // Address fields
  final String? streetAddress;
  final String? locality; // city
  final String? region; // state/province
  final String? postalCode;
  final String? country;
  final String? formattedAddress;

  AsgardeoUser({
    this.sub,
    this.email,
    this.firstName,
    this.lastName,
    this.username,
    this.phoneNumber,
    this.phoneNumberVerified = false,
    this.picture,
    this.emailVerified = false,
    this.streetAddress,
    this.locality,
    this.region,
    this.postalCode,
    this.country,
    this.formattedAddress,
  });

  factory AsgardeoUser.fromJson(Map<String, dynamic> json) {
    // Parse address object if present
    final address = json['address'] as Map<String, dynamic>?;

    return AsgardeoUser(
      sub: json['sub'] as String?,
      email: json['email'] as String?,
      firstName: json['given_name'] as String?,
      lastName: json['family_name'] as String?,
      username: json['username'] ?? json['preferred_username'] as String?,
      phoneNumber: json['phone_number'] as String?,
      phoneNumberVerified: json['phone_number_verified'] as bool? ?? false,
      picture: json['picture'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      streetAddress: address?['street_address'] as String?,
      locality: address?['locality'] as String?,
      region: address?['region'] as String?,
      postalCode: address?['postal_code'] as String?,
      country: address?['country'] as String?,
      formattedAddress: address?['formatted'] as String?,
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

  /// Sync Asgardeo user into backend database by verifying access token.
  Future<AuthResult<Map<String, dynamic>>> syncUserWithBackend({
    required String accessToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ServerConstant.serverURL}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'access_token': accessToken}),
      );

      // Handle non-JSON responses (e.g. plain text "Internal Server Error")
      Map<String, dynamic> resBodyMap;
      try {
        resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return AuthResult.failure(
          response.statusCode == 200
              ? 'Unexpected response from server'
              : 'Server error (${response.statusCode})',
        );
      }

      if (response.statusCode != 200) {
        return AuthResult.failure(
          resBodyMap['detail']?.toString() ?? 'Failed to sync user',
        );
      }
      return AuthResult.success(resBodyMap);
    } catch (e) {
      return AuthResult.failure('Connection error: ${e.toString()}');
    }
  }

  /// Logout via backend (revoke token on server).
  Future<AuthResult<bool>> logoutWithBackend({
    required String accessToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ServerConstant.serverURL}/auth/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'access_token': accessToken}),
      );

      if (response.statusCode != 200) {
        final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResult.failure(
          resBodyMap['detail']?.toString() ?? 'Logout failed',
        );
      }
      return AuthResult.success(true);
    } catch (e) {
      return AuthResult.failure('Connection error: ${e.toString()}');
    }
  }

  /// Register a new user - opens Asgardeo's registration page in browser
  /// Asgardeo's cloud user store is read-only for API writes,
  /// so browser-based registration is the officially supported method
  Future<AuthResult<Map<String, dynamic>>> register({
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
    try {
      debugPrint('Opening Asgardeo registration page in browser...');

      // Open Asgardeo's self-service portal for registration
      final url = Uri.parse(AsgardeoDirectConfig.selfServicePortalUrl);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return AuthResult.success({
          'success': true,
          'message':
              'Registration page opened in browser. Please complete registration there, then return to login.',
          'browser_registration': true,
        });
      } else {
        debugPrint('Could not launch registration URL');
        return AuthResult.failure(
          'Could not open registration page. Please try again.',
        );
      }
    } catch (e, s) {
      debugPrint('Registration error: $e\n$s');
      return AuthResult.failure('Error opening registration: ${e.toString()}');
    }
  }

  /// Get the server URL based on platform
  // ignore: unused_element
  String _getServerUrl() {
    // For Android emulator, use 10.0.2.2 to access host machine
    // For iOS simulator, use localhost
    // For physical devices, use actual server IP
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// Update user information using SCIM2 endpoint
  /// Requires a valid access token
  Future<AuthResult<Map<String, dynamic>>> updateUserInfo({
    required String accessToken,
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
    try {
      debugPrint('Attempting to update user info in Asgardeo...');

      // Build SCIM2 patch operations
      final operations = <Map<String, dynamic>>[];

      // Update name if provided
      if (firstName != null || lastName != null) {
        final nameOp = <String, dynamic>{
          'op': 'replace',
          'path': 'name',
          'value': <String, dynamic>{},
        };
        if (firstName != null) {
          (nameOp['value'] as Map<String, dynamic>)['givenName'] = firstName;
        }
        if (lastName != null) {
          (nameOp['value'] as Map<String, dynamic>)['familyName'] = lastName;
        }
        operations.add(nameOp);
      }

      // Update phone number if provided
      if (phoneNumber != null) {
        operations.add({
          'op': 'replace',
          'path': 'phoneNumbers',
          'value': [
            {'value': phoneNumber, 'type': 'mobile', 'primary': true},
          ],
        });
      }

      // Update address if any address field is provided
      if (streetAddress != null ||
          locality != null ||
          region != null ||
          postalCode != null ||
          country != null) {
        final addressValue = <String, dynamic>{'type': 'home', 'primary': true};
        if (streetAddress != null) {
          addressValue['streetAddress'] = streetAddress;
        }
        if (locality != null) addressValue['locality'] = locality;
        if (region != null) addressValue['region'] = region;
        if (postalCode != null) addressValue['postalCode'] = postalCode;
        if (country != null) addressValue['country'] = country;

        operations.add({
          'op': 'replace',
          'path': 'addresses',
          'value': [addressValue],
        });
      }

      // Update profile picture if provided
      if (picture != null) {
        operations.add({
          'op': 'replace',
          'path': 'photos',
          'value': [
            {'value': picture, 'type': 'photo', 'primary': true},
          ],
        });
      }

      if (operations.isEmpty) {
        return AuthResult.failure('No fields to update');
      }

      final patchRequest = {
        'schemas': ['urn:ietf:params:scim:api:messages:2.0:PatchOp'],
        'Operations': operations,
      };

      final response = await http.patch(
        Uri.parse(AsgardeoDirectConfig.scim2MeEndpoint), // /scim2/Me endpoint
        headers: {
          'Content-Type': 'application/scim+json',
          'Accept': 'application/scim+json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(patchRequest),
      );

      debugPrint('Update response status: ${response.statusCode}');
      debugPrint('Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('Update successful!');
        return AuthResult.success(json);
      } else {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        final errorDetail =
            errorJson['detail'] ??
            errorJson['scimType'] ??
            errorJson['description'] ??
            'Update failed';
        debugPrint('Update failed: $errorDetail');
        return AuthResult.failure(errorDetail.toString());
      }
    } catch (e, s) {
      debugPrint('Update error: $e\n$s');
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
