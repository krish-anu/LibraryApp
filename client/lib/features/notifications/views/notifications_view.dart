import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/common/common_app_bar.dart';
import 'package:libraryapp/features/notifications/viewmodels/notifications_controller.dart';
import 'package:libraryapp/models/app_notification.dart';

class NotificationsView extends ConsumerWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: CommonAppBar(
        title: 'Notifications',
        centerTitle: true,
        actions: [
          if (state.notifications.isNotEmpty)
            TextButton(
              onPressed: state.unreadCount == 0
                  ? null
                  : () => controller.markAllAsRead(),
              child: const Text(
                'Read all',
                style: TextStyle(color: Pallete.primaryLight),
              ),
            ),
        ],
      ),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Pallete.primaryLight),
            )
          : RefreshIndicator(
              onRefresh: controller.refresh,
              color: Pallete.primaryLight,
              child: state.notifications.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 140),
                        _EmptyNotifications(),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notification = state.notifications[index];
                        return _NotificationCard(
                          notification: notification,
                          onTap: () => controller.markAsRead(notification.id),
                        );
                      },
                    ),
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  String _formattedDate(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} ${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.read
                ? Pallete.cardBackground
                : Pallete.primaryLight.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.read
                  ? Pallete.border
                  : Pallete.primaryLight.withValues(alpha: 0.24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: const TextStyle(
                        color: Pallete.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (!notification.read)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Pallete.primaryLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notification.body,
                style: const TextStyle(
                  color: Pallete.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Pallete.cardBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      notification.category.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        color: Pallete.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formattedDate(notification.createdAt),
                    style: const TextStyle(
                      color: Pallete.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Icon(
          Icons.notifications_none_rounded,
          size: 64,
          color: Pallete.textSecondary,
        ),
        SizedBox(height: 16),
        Text(
          'No notifications yet',
          style: TextStyle(
            color: Pallete.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Borrowing updates, reminders, fines, and admin actions will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Pallete.textSecondary),
        ),
      ],
    );
  }
}
