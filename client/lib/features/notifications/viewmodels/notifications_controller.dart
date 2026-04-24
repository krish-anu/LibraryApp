import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/services/notification_service.dart';
import 'package:libraryapp/data/repository/notification_repository.dart';
import 'package:libraryapp/models/app_notification.dart';

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );

class NotificationsState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;
  final String memberId;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
    this.memberId = '',
  });

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
    String? memberId,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      unreadCount: unreadCount ?? this.unreadCount,
      memberId: memberId ?? this.memberId,
    );
  }
}

class NotificationsController extends Notifier<NotificationsState> {
  StreamSubscription<void>? _messageEventsSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  String _registeredMemberId = '';

  NotificationRepository get _repository =>
      ref.read(notificationRepositoryProvider);

  @override
  NotificationsState build() {
    _messageEventsSubscription ??= NotificationService.instance.messageEvents
        .listen((_) {
          if (state.memberId.isEmpty) return;
          unawaited(refresh());
        });

    ref.onDispose(() {
      _messageEventsSubscription?.cancel();
      _tokenRefreshSubscription?.cancel();
    });

    return const NotificationsState();
  }

  Future<void> setMemberId(String memberId) async {
    final normalizedMemberId = memberId.trim();
    if (state.memberId == normalizedMemberId) return;

    if (normalizedMemberId.isEmpty) {
      await _tokenRefreshSubscription?.cancel();
      _registeredMemberId = '';
      state = const NotificationsState();
      return;
    }

    state = state.copyWith(memberId: normalizedMemberId);
    await _bootstrapPushRegistration(normalizedMemberId);
    await refresh();
  }

  Future<void> refresh() async {
    if (state.memberId.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);
    final notificationsResult = await _repository.getNotifications();
    final unreadResult = await _repository.getUnreadCount();

    notificationsResult.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (notifications) {
        final unreadCount = unreadResult.fold(
          (_) => notifications.where((item) => !item.read).length,
          (count) => count,
        );
        state = state.copyWith(
          notifications: notifications,
          unreadCount: unreadCount,
          isLoading: false,
        );
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    final existing = state.notifications.where(
      (item) => item.id == notificationId,
    );
    if (existing.isNotEmpty && existing.first.read) {
      return;
    }

    final result = await _repository.markAsRead(notificationId);
    result.fold((_) {}, (updated) {
      final notifications = state.notifications
          .map((item) => item.id == notificationId ? updated : item)
          .toList();
      state = state.copyWith(
        notifications: notifications,
        unreadCount: notifications.where((item) => !item.read).length,
      );
    });
  }

  Future<void> markAllAsRead() async {
    final result = await _repository.markAllAsRead();
    result.fold((_) {}, (_) {
      final now = DateTime.now();
      final notifications = state.notifications
          .map((item) => item.copyWith(read: true, readAt: now))
          .toList();
      state = state.copyWith(notifications: notifications, unreadCount: 0);
    });
  }

  Future<void> _bootstrapPushRegistration(String memberId) async {
    await NotificationService.instance.requestPermissions();
    final token = await NotificationService.instance.getDeviceToken();
    final platform = NotificationService.instance.platformName;

    if (token != null && token.isNotEmpty) {
      await _repository.registerDeviceToken(token: token, platform: platform);
      _registeredMemberId = memberId;
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = NotificationService.instance.tokenRefreshStream
        .listen((refreshedToken) {
          if (_registeredMemberId.isEmpty) return;
          unawaited(
            _repository.registerDeviceToken(
              token: refreshedToken,
              platform: platform,
            ),
          );
        });
  }
}
