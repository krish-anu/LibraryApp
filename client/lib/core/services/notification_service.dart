import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:libraryapp/core/widgets/BottomNavigator/nav_keys.dart';
import 'package:libraryapp/features/notifications/views/notifications_view.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<void> _messageEvents =
      StreamController<void>.broadcast();

  bool _initialized = false;

  Stream<void> get messageEvents => _messageEvents.stream;
  Stream<String> get tokenRefreshStream => const Stream<String>.empty();

  String get platformName {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  Future<void> ensureInitialized() async {
    if (_initialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (_) {
        _messageEvents.add(null);
        _openNotificationsView();
      },
    );

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<String?> getDeviceToken() async {
    return null;
  }

  Future<void> unregisterDeviceTokenFromBackend({
    required String accessToken,
  }) async {
    return;
  }

  void _openNotificationsView() {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute(builder: (context) => const NotificationsView()),
    );
  }

  Future<void> dispose() async {
    await _messageEvents.close();
  }
}
