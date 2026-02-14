import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/providers/current_user_notifier.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

/// Header widget displaying greeting and notification icon.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final name = user?.userName.trim();
    final firstName =
        (name == null || name.isEmpty) ? 'Reader' : name.split(RegExp(r'\s+')).first;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()}, $firstName',
              style: const TextStyle(
                color: Pallete.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ready to dive into a new world?',
              style: TextStyle(color: Pallete.textSecondary, fontSize: 14),
            ),
          ],
        ),
        _buildNotificationButton(),
      ],
    );
  }

  Widget _buildNotificationButton() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Pallete.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.notifications_outlined,
        color: Pallete.iconColor,
        size: 24,
      ),
    );
  }
}
