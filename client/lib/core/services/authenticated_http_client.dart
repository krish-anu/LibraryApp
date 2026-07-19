import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// An HTTP client wrapper that automatically injects the Asgardeo access token
/// from secure storage into the Authorization header for all requests.
class AuthenticatedHttpClient {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _accessTokenKey = 'asgardeo_access_token';
  static const Duration _requestTimeout = Duration(seconds: 15);
  static Future<bool> Function()? _tokenRefresher;
  static Future<void> Function()? _sessionExpiredHandler;
  static Future<bool>? _refreshInFlight;
  static Future<void>? _sessionExpiryInFlight;

  /// Registers the auth provider callback used to renew an expired token.
  static void configureTokenRefresher(Future<bool> Function() refresher) {
    _tokenRefresher = refresher;
  }

  /// Registers the auth provider callback used when token recovery fails.
  static void configureSessionExpiredHandler(Future<void> Function() handler) {
    _sessionExpiredHandler = handler;
  }

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

  static Future<http.Response> _sendWithRefresh({
    required Uri url,
    required Future<http.Response> Function(Map<String, String>) send,
    Map<String, String>? headers,
  }) async {
    final requestHeaders = await _authHeaders(headers);
    final response = await _sendWithTimeout(send(requestHeaders), url);
    if (response.statusCode == 403) {
      await _handleSessionExpired();
      return response;
    }
    if (response.statusCode != 401) {
      return response;
    }

    // Another concurrent request may already have refreshed the token while
    // this request was in flight. In that case, retry without refreshing it
    // a second time.
    final latestHeaders = await _authHeaders(headers);
    if (latestHeaders['Authorization'] != requestHeaders['Authorization']) {
      return _sendWithTimeout(send(latestHeaders), url);
    }

    if (!await _refreshToken()) {
      await _handleSessionExpired();
      return response;
    }

    final retryResponse = await _sendWithTimeout(
      send(await _authHeaders(headers)),
      url,
    );
    if (retryResponse.statusCode == 401 || retryResponse.statusCode == 403) {
      await _handleSessionExpired();
    }
    return retryResponse;
  }

  static Future<http.Response> _sendWithTimeout(
    Future<http.Response> request,
    Uri url,
  ) {
    return request.timeout(
      _requestTimeout,
      onTimeout: () =>
          throw TimeoutException('Request timed out while connecting to $url'),
    );
  }

  static Future<bool> _refreshToken() {
    final activeRefresh = _refreshInFlight;
    if (activeRefresh != null) {
      return activeRefresh;
    }

    final refresher = _tokenRefresher;
    if (refresher == null) {
      return Future.value(false);
    }

    late final Future<bool> refresh;
    refresh = refresher().whenComplete(() {
      if (identical(_refreshInFlight, refresh)) {
        _refreshInFlight = null;
      }
    });
    _refreshInFlight = refresh;
    return refresh;
  }

  static Future<void> _handleSessionExpired() {
    final activeExpiry = _sessionExpiryInFlight;
    if (activeExpiry != null) {
      return activeExpiry;
    }

    final handler = _sessionExpiredHandler;
    if (handler == null) {
      return Future.value();
    }

    late final Future<void> expiry;
    expiry = handler().whenComplete(() {
      if (identical(_sessionExpiryInFlight, expiry)) {
        _sessionExpiryInFlight = null;
      }
    });
    _sessionExpiryInFlight = expiry;
    return expiry;
  }

  /// Authenticated GET request.
  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
      _sendWithRefresh(
        url: url,
        headers: headers,
        send: (requestHeaders) => http.get(url, headers: requestHeaders),
      );

  /// Authenticated POST request.
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _sendWithRefresh(
    url: url,
    headers: headers,
    send: (requestHeaders) =>
        http.post(url, headers: requestHeaders, body: body),
  );

  /// Authenticated PUT request.
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _sendWithRefresh(
    url: url,
    headers: headers,
    send: (requestHeaders) =>
        http.put(url, headers: requestHeaders, body: body),
  );

  /// Authenticated DELETE request.
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _sendWithRefresh(
    url: url,
    headers: headers,
    send: (requestHeaders) =>
        http.delete(url, headers: requestHeaders, body: body),
  );
}
