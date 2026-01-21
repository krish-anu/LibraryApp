import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

/// Header widget displaying greeting and notification icon.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()}, Reader',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ready to dive into a new world?',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
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
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
