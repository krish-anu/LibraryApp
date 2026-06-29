import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:libraryapp/auth/config/asgardeo_runtime_config.dart';
import 'package:libraryapp/core/constants/server_constant.dart';

/// WSO2 Identity Platform app-native authentication configuration.
class AsgardeoDirectConfig {
  static String get clientId => AsgardeoRuntimeConfig.clientId;
  // Public client - no client secret needed for mobile apps
  static const String clientSecret = '';
  static String get baseUrl => AsgardeoRuntimeConfig.baseUrl;
  static String get tokenEndpoint => AsgardeoRuntimeConfig.tokenEndpoint;
  static String get authorizeEndpoint => '$baseUrl/oauth2/authorize/';
  static String get authenticationEndpoint => '$baseUrl/oauth2/authn';
  static String get userInfoEndpoint => AsgardeoRuntimeConfig.userInfoEndpoint;
  static String get scim2Endpoint => AsgardeoRuntimeConfig.scim2Endpoint;
  static String get scim2MeEndpoint => AsgardeoRuntimeConfig.scim2MeEndpoint;
  static String get scim2UsersEndpoint =>
      AsgardeoRuntimeConfig.scim2UsersEndpoint;
  // Self-registration endpoint
  static String get selfRegisterEndpoint =>
      AsgardeoRuntimeConfig.selfRegisterEndpoint;
  // Alternative registration endpoint
  static String get publicRegisterEndpoint =>
      AsgardeoRuntimeConfig.publicRegisterEndpoint;
  static String get introspectEndpoint =>
      AsgardeoRuntimeConfig.introspectEndpoint;

  // Browser-based registration URL (Asgardeo hosted page)
  // This is the officially supported way for Asgardeo cloud
  static String get registrationUrl => AsgardeoRuntimeConfig.registrationUrl;

  // Alternative: Asgardeo's self-service portal
  static String get selfServicePortalUrl =>
      AsgardeoRuntimeConfig.selfServicePortalUrl;

  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'books_read',
    'books_manage',
    'loans_manage',
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
  final String? name;
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
    this.name,
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
      name: json['name'] as String?,
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
    final parts = [
      firstName,
      lastName,
    ].map((s) => s?.trim()).where((s) => s != null && s.isNotEmpty);
    final firstAndLast = parts.join(' ');
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
  static const _pkceCharacters =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  Map<String, dynamic>? _tryDecodeJsonObject(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  String _snippet(String body, {int maxLength = 160}) {
    final compact = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) {
      return '';
    }
    if (compact.length <= maxLength) {
      return compact;
    }
    return '${compact.substring(0, maxLength)}...';
  }

  String _errorMessageFromResponse({
    required http.Response response,
    required Uri endpoint,
    required String action,
    required String fallback,
  }) {
    final json = _tryDecodeJsonObject(response.body);
    if (json != null) {
      return (json['error_description'] ??
              json['detail'] ??
              json['description'] ??
              json['scimType'] ??
              json['error'] ??
              fallback)
          .toString();
    }

    final contentType = (response.headers['content-type'] ?? '').toLowerCase();
    final responseLooksHtml =
        contentType.contains('text/html') ||
        response.body.trimLeft().startsWith('<');
    if (response.statusCode == 404 && responseLooksHtml) {
      return 'Asgardeo $action returned 404 HTML from $endpoint. '
          'Check ASGARDEO_BASE_URL. It should be the tenant base URL only, '
          'for example https://api.<region>.asgardeo.io/t/<org>, without '
          '/oauth2/token or any other endpoint path.';
    }

    final snippet = _snippet(response.body);
    if (snippet.isEmpty) {
      return '$fallback (${response.statusCode})';
    }

    return '$fallback (${response.statusCode}): $snippet';
  }

  String _messageFromException(Object error) {
    final message = error.toString();
    const badStatePrefix = 'Bad state: ';
    if (message.startsWith(badStatePrefix)) {
      return message.substring(badStatePrefix.length);
    }
    return message;
  }

  String _randomUrlSafeValue(int length) {
    final random = Random.secure();
    return List.generate(
      length,
      (_) => _pkceCharacters[random.nextInt(_pkceCharacters.length)],
    ).join();
  }

  String _pkceChallenge(String verifier) {
    return base64Url
        .encode(sha256.convert(utf8.encode(verifier)).bytes)
        .replaceAll('=', '');
  }

  String _flowError(Map<String, dynamic> response, String fallback) {
    final nextStep = response['nextStep'];
    if (nextStep is Map<String, dynamic>) {
      final messages = nextStep['messages'];
      if (messages is List) {
        for (final item in messages) {
          if (item is Map<String, dynamic>) {
            final message = item['message']?.toString().trim();
            if (message != null && message.isNotEmpty) {
              return message;
            }
          }
        }
      }
    }

    return response['error_description']?.toString() ??
        response['description']?.toString() ??
        response['message']?.toString() ??
        response['error']?.toString() ??
        fallback;
  }

  Map<String, dynamic>? _usernamePasswordAuthenticator(
    Map<String, dynamic> response,
  ) {
    final nextStep = response['nextStep'];
    if (nextStep is! Map<String, dynamic>) {
      return null;
    }

    final authenticators = nextStep['authenticators'];
    if (authenticators is! List) {
      return null;
    }

    for (final item in authenticators) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final requiredParams = item['requiredParams'];
      if (requiredParams is List &&
          requiredParams.contains('username') &&
          requiredParams.contains('password')) {
        return item;
      }
    }
    return null;
  }

  /// Authenticate inside the app using WSO2's App-Native Authentication API.
  /// The flow still uses Authorization Code + PKCE and never stores the password.
  Future<AuthResult<AsgardeoTokenResponse>> login({
    required String username,
    required String password,
  }) async {
    try {
      AsgardeoRuntimeConfig.ensureConfigured();
      final normalizedUsername = username.trim();
      if (normalizedUsername.isEmpty || password.isEmpty) {
        return AuthResult.failure('Username and password are required.');
      }

      final verifier = _randomUrlSafeValue(64);
      final state = _randomUrlSafeValue(32);
      final redirectUri = AsgardeoRuntimeConfig.redirectUrl;
      final authorizeUri = Uri.parse(AsgardeoDirectConfig.authorizeEndpoint);

      final initiationResponse = await http.post(
        authorizeUri,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': AsgardeoDirectConfig.clientId,
          'response_type': 'code',
          'redirect_uri': redirectUri,
          'scope': AsgardeoDirectConfig.scopes.join(' '),
          'response_mode': 'direct',
          'state': state,
          'code_challenge': _pkceChallenge(verifier),
          'code_challenge_method': 'S256',
        },
      );

      final initiation = _tryDecodeJsonObject(initiationResponse.body);
      if (initiationResponse.statusCode != 200 || initiation == null) {
        return AuthResult.failure(
          _errorMessageFromResponse(
            response: initiationResponse,
            endpoint: authorizeUri,
            action: 'app-native authentication initiation',
            fallback:
                'Unable to start sign in. Enable App-Native Authentication for this application in WSO2 Identity Platform.',
          ),
        );
      }

      final flowId = initiation['flowId']?.toString();
      final authenticator = _usernamePasswordAuthenticator(initiation);
      final authenticatorId = authenticator?['authenticatorId']?.toString();
      if (flowId == null ||
          flowId.isEmpty ||
          authenticatorId == null ||
          authenticatorId.isEmpty) {
        return AuthResult.failure(
          _flowError(
            initiation,
            'Username and password authentication is not available in the configured WSO2 login flow.',
          ),
        );
      }

      final authenticationUri = Uri.parse(
        AsgardeoDirectConfig.authenticationEndpoint,
      );
      final authenticationResponse = await http.post(
        authenticationUri,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'flowId': flowId,
          'selectedAuthenticator': {
            'authenticatorId': authenticatorId,
            'params': {'username': normalizedUsername, 'password': password},
          },
        }),
      );

      final authentication = _tryDecodeJsonObject(authenticationResponse.body);
      if (authenticationResponse.statusCode != 200 || authentication == null) {
        return AuthResult.failure(
          _errorMessageFromResponse(
            response: authenticationResponse,
            endpoint: authenticationUri,
            action: 'app-native authentication',
            fallback: 'Sign in failed.',
          ),
        );
      }

      final authData = authentication['authData'];
      final code = authData is Map<String, dynamic>
          ? authData['code']?.toString()
          : authentication['code']?.toString();
      if (authentication['flowStatus'] != 'SUCCESS_COMPLETED' ||
          code == null ||
          code.isEmpty) {
        return AuthResult.failure(
          _flowError(
            authentication,
            'Sign in requires an additional authentication step that this screen does not yet support.',
          ),
        );
      }

      final tokenUri = Uri.parse(AsgardeoDirectConfig.tokenEndpoint);
      final tokenResponse = await http.post(
        tokenUri,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'client_id': AsgardeoDirectConfig.clientId,
          'code_verifier': verifier,
        },
      );

      final tokenJson = _tryDecodeJsonObject(tokenResponse.body);
      if (tokenResponse.statusCode != 200 || tokenJson == null) {
        return AuthResult.failure(
          _errorMessageFromResponse(
            response: tokenResponse,
            endpoint: tokenUri,
            action: 'authorization code exchange',
            fallback: 'Unable to complete sign in.',
          ),
        );
      }

      return AuthResult.success(AsgardeoTokenResponse.fromJson(tokenJson));
    } catch (error) {
      return AuthResult.failure(
        'Sign in failed: ${_messageFromException(error)}',
      );
    }
  }

  /// Get user info using access token
  Future<AuthResult<AsgardeoUser>> getUserInfo(String accessToken) async {
    try {
      AsgardeoRuntimeConfig.ensureConfigured();
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
      AsgardeoRuntimeConfig.ensureConfigured();
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
      AsgardeoRuntimeConfig.ensureConfigured();
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

      if (response.statusCode == 200) {
        final json = _tryDecodeJsonObject(response.body);
        if (json == null) {
          return AuthResult.failure(
            'Update failed: Asgardeo returned a non-JSON response.',
          );
        }
        debugPrint('Update successful!');
        return AuthResult.success(json);
      } else {
        final errorDetail = _errorMessageFromResponse(
          response: response,
          endpoint: Uri.parse(AsgardeoDirectConfig.scim2MeEndpoint),
          action: 'profile update',
          fallback: 'Update failed',
        );
        debugPrint('Update failed: $errorDetail');
        return AuthResult.failure(errorDetail.toString());
      }
    } catch (e, s) {
      debugPrint('Update error: $e\n$s');
      return AuthResult.failure(_messageFromException(e));
    }
  }

  /// Refresh access token using refresh token
  Future<AuthResult<AsgardeoTokenResponse>> refreshToken(
    String refreshToken,
  ) async {
    try {
      AsgardeoRuntimeConfig.ensureConfigured();
      final body = {
        'grant_type': 'refresh_token',
        'client_id': AsgardeoDirectConfig.clientId,
        'refresh_token': refreshToken,
      };

      if (AsgardeoDirectConfig.clientSecret.isNotEmpty) {
        body['client_secret'] = AsgardeoDirectConfig.clientSecret;
      }

      final tokenUri = Uri.parse(AsgardeoDirectConfig.tokenEndpoint);
      final response = await http.post(
        tokenUri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (response.statusCode == 200) {
        final json = _tryDecodeJsonObject(response.body);
        if (json == null) {
          return AuthResult.failure(
            'Token refresh failed: Asgardeo returned a non-JSON response.',
          );
        }
        return AuthResult.success(AsgardeoTokenResponse.fromJson(json));
      } else {
        return AuthResult.failure(
          _errorMessageFromResponse(
            response: response,
            endpoint: tokenUri,
            action: 'token refresh',
            fallback: 'Token refresh failed',
          ),
        );
      }
    } catch (e) {
      return AuthResult.failure(_messageFromException(e));
    }
  }

  /// Revoke access token (logout)
  Future<bool> revokeToken(String token) async {
    try {
      AsgardeoRuntimeConfig.ensureConfigured();
      final response = await http.post(
        Uri.parse(AsgardeoRuntimeConfig.revokeEndpoint),
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
