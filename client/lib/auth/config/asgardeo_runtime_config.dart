import 'package:flutter/foundation.dart';

class AsgardeoRuntimeConfig {
  static const String _clientId = String.fromEnvironment(
    'ASGARDEO_CLIENT_ID',
    defaultValue: '',
  );
  static const String _baseUrl = String.fromEnvironment(
    'ASGARDEO_BASE_URL',
    defaultValue: '',
  );
  static const String _redirectUrl = String.fromEnvironment(
    'ASGARDEO_REDIRECT_URL',
    defaultValue: 'com.krishnaanu.libraryapp://callback',
  );
  static const String _selfServicePortalUrl = String.fromEnvironment(
    'ASGARDEO_SELF_SERVICE_PORTAL_URL',
    defaultValue: '',
  );

  static String get redirectUrl {
    final configured = _redirectUrl.trim();
    if (configured.isNotEmpty) {
      return configured;
    }

    // Keep Android aligned with Firebase while preserving the current iOS URI.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'com.krishnaanu.libraryapp://callback';
    }

    return 'com.example.libraryapp://callback';
  }

  static String get clientId =>
      _requiredValue(key: 'ASGARDEO_CLIENT_ID', value: _clientId);

  static String get baseUrl => _validateBaseUrl(
    _normalizeUrl(_requiredValue(key: 'ASGARDEO_BASE_URL', value: _baseUrl)),
  );

  static String get discoveryUrl =>
      '$baseUrl/oauth2/token/.well-known/openid-configuration';
  static String get tokenEndpoint => '$baseUrl/oauth2/token';
  static String get userInfoEndpoint => '$baseUrl/oauth2/userinfo';
  static String get introspectEndpoint => '$baseUrl/oauth2/introspect';
  static String get revokeEndpoint => '$baseUrl/oauth2/revoke';
  static String get scim2Endpoint => '$baseUrl/scim2';
  static String get scim2MeEndpoint => '$scim2Endpoint/Me';
  static String get scim2UsersEndpoint => '$scim2Endpoint/Users';
  static String get selfRegisterEndpoint =>
      '$baseUrl/api/identity/user/v1.0/me';
  static String get publicRegisterEndpoint =>
      '$baseUrl/api/asgardeo/selfservice/v1/self-register';
  static String get registrationUrl =>
      '$baseUrl/accountrecoveryendpoint/register.do?client_id=$clientId';

  static String get selfServicePortalUrl {
    final configured = _normalizeOptionalUrl(_selfServicePortalUrl);
    if (configured != null) {
      return configured;
    }

    final derived = _deriveSelfServicePortalUrl(baseUrl);
    if (derived != null) {
      return derived;
    }

    throw StateError(
      'Missing Asgardeo self-service portal URL. Pass '
      '--dart-define=ASGARDEO_SELF_SERVICE_PORTAL_URL=https://myaccount.<region>.asgardeo.io/t/<org>.',
    );
  }

  static void ensureConfigured() {
    clientId;
    baseUrl;
  }

  static String _requiredValue({required String key, required String value}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw StateError(
        'Missing required Asgardeo configuration: $key. '
        'Start Flutter with --dart-define=$key=your-value.',
      );
    }
    return trimmed;
  }

  static String _normalizeUrl(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static String _validateBaseUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty || uri.scheme.isEmpty) {
      throw StateError(
        'ASGARDEO_BASE_URL must be a valid URL like '
        'https://api.<region>.asgardeo.io/t/<org>.',
      );
    }

    const disallowedPathFragments = [
      '/oauth2/',
      '/scim2',
      '/accountrecoveryendpoint',
      '/api/asgardeo/',
      '/api/identity/',
    ];
    final hasEndpointPath = disallowedPathFragments.any(uri.path.contains);
    if (hasEndpointPath || uri.hasQuery || uri.fragment.isNotEmpty) {
      throw StateError(
        'ASGARDEO_BASE_URL must be the tenant base URL only, for example '
        'https://api.<region>.asgardeo.io/t/<org>. Do not include '
        '/oauth2/token, /oauth2/authorize, or any other endpoint path.',
      );
    }

    return value;
  }

  static String? _normalizeOptionalUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return _normalizeUrl(trimmed);
  }

  static String? _deriveSelfServicePortalUrl(String tenantBaseUrl) {
    final uri = Uri.tryParse(tenantBaseUrl);
    if (uri == null || uri.host.isEmpty || !uri.path.startsWith('/t/')) {
      return null;
    }

    final host = uri.host;
    if (!host.startsWith('api.')) {
      return null;
    }

    return Uri(
      scheme: uri.scheme.isEmpty ? 'https' : uri.scheme,
      host: 'myaccount.${host.substring(4)}',
      path: uri.path,
    ).toString();
  }
}
