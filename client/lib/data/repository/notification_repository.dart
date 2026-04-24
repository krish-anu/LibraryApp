import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:libraryapp/core/constants/server_constant.dart';
import 'package:libraryapp/core/failure/failure.dart';
import 'package:libraryapp/core/services/authenticated_http_client.dart';
import 'package:libraryapp/models/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

class NotificationRepository {
  Future<Either<Failure, List<AppNotification>>> getNotifications() async {
    try {
      final response = await AuthenticatedHttpClient.get(
        Uri.parse('${ServerConstant.serverURL}/notifications'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return right(
          data
              .map(
                (item) => AppNotification.fromMap(item as Map<String, dynamic>),
              )
              .toList(),
        );
      }
      return left(Failure(_extractErrorMessage(response.body)));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final response = await AuthenticatedHttpClient.get(
        Uri.parse('${ServerConstant.serverURL}/notifications/unread-count'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return right((data['unread'] as num?)?.toInt() ?? 0);
      }
      return left(Failure(_extractErrorMessage(response.body)));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, AppNotification>> markAsRead(
    String notificationId,
  ) async {
    try {
      final response = await AuthenticatedHttpClient.post(
        Uri.parse(
          '${ServerConstant.serverURL}/notifications/$notificationId/read',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return right(AppNotification.fromMap(data));
      }
      return left(Failure(_extractErrorMessage(response.body)));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, int>> markAllAsRead() async {
    try {
      final response = await AuthenticatedHttpClient.post(
        Uri.parse('${ServerConstant.serverURL}/notifications/read-all'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return right((data['marked'] as num?)?.toInt() ?? 0);
      }
      return left(Failure(_extractErrorMessage(response.body)));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, bool>> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    try {
      final response = await AuthenticatedHttpClient.post(
        Uri.parse('${ServerConstant.serverURL}/notifications/device-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'platform': platform}),
      );
      if (response.statusCode == 200) {
        return right(true);
      }
      return left(Failure(_extractErrorMessage(response.body)));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, bool>> unregisterDeviceToken({
    required String token,
    required String platform,
  }) async {
    try {
      final response = await AuthenticatedHttpClient.delete(
        Uri.parse('${ServerConstant.serverURL}/notifications/device-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'platform': platform}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return right(data['success'] as bool? ?? false);
      }
      return left(Failure(_extractErrorMessage(response.body)));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail =
            decoded['detail'] ?? decoded['error'] ?? decoded['message'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }
      }
    } catch (_) {}
    return body.trim().isEmpty ? 'Notification request failed' : body.trim();
  }
}
