import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// An HTTP client wrapper that automatically injects the Asgardeo access token
/// from secure storage into the Authorization header for all requests.
class AuthenticatedHttpClient {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _accessTokenKey = 'asgardeo_access_token';
  static const Duration _requestTimeout = Duration(seconds: 15);

  /// Read the current access token from secure storage.
  static Future<String?> _getToken() async {
    return _secureStorage.read(key: _accessTokenKey);
  }

  /// Build default headers including Authorization if a token exists.
  static Future<Map<String, String>> _authHeaders([
    Map<String, String>? extra,
  ]) async {
    final token = await _getToken();
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  /// Authenticated GET request.
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final h = await _authHeaders(headers);
    return http
        .get(url, headers: h)
        .timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException(
            'Request timed out while connecting to $url',
          ),
        );
  }

  /// Authenticated POST request.
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final h = await _authHeaders(headers);
    return http
        .post(url, headers: h, body: body)
        .timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException(
            'Request timed out while connecting to $url',
          ),
        );
  }

  /// Authenticated PUT request.
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final h = await _authHeaders(headers);
    return http
        .put(url, headers: h, body: body)
        .timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException(
            'Request timed out while connecting to $url',
          ),
        );
  }

  /// Authenticated DELETE request.
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final h = await _authHeaders(headers);
    return http
        .delete(url, headers: h, body: body)
        .timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException(
            'Request timed out while connecting to $url',
          ),
        );
  }
}
