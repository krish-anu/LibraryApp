import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:libraryapp/core/constants/server_constant.dart';
import 'package:libraryapp/core/widgets/BottomNavigator/nav_keys.dart';
import 'package:libraryapp/features/notifications/views/notifications_view.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.ensureInitialized();
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'library_notifications',
    'Library Notifications',
    description: 'Notifications for library activity and due reminders',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<void> _messageEvents =
      StreamController<void>.broadcast();

  bool _initialized = false;
  bool _firebaseAvailable = false;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;

  Stream<void> get messageEvents => _messageEvents.stream;
  Stream<String> get tokenRefreshStream =>
      _firebaseAvailable ? FirebaseMessaging.instance.onTokenRefresh : const Stream<String>.empty();

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

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _firebaseAvailable = true;
    } catch (error) {
      debugPrint('Firebase notifications unavailable: $error');
      _initialized = true;
      return;
    }

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

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    final messaging = FirebaseMessaging.instance;

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      unawaited(_showForegroundNotification(message));
      _messageEvents.add(null);
    });
    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((_) {
      _messageEvents.add(null);
      _openNotificationsView();
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _messageEvents.add(null);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openNotificationsView();
      });
    }

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (!_firebaseAvailable) return;
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<String?> getDeviceToken() async {
    if (!_firebaseAvailable) return null;
    return FirebaseMessaging.instance.getToken();
  }

  Future<void> unregisterDeviceTokenFromBackend({
    required String accessToken,
  }) async {
    if (!_firebaseAvailable) return;
    final token = await getDeviceToken();
    if (token == null || token.isEmpty) return;

    try {
      await http.delete(
        Uri.parse('${ServerConstant.serverURL}/notifications/device-token'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': token, 'platform': platformName}),
      );
    } catch (error) {
      debugPrint('Failed to unregister device token: $error');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? 'Library Notification';
    final body =
        notification?.body ??
        message.data['body']?.toString() ??
        'You have a new library update.';

    await _localNotifications.show(
      message.messageId.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
    );
  }

  void _openNotificationsView() {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute(builder: (context) => const NotificationsView()),
    );
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    await _messageEvents.close();
  }
}
