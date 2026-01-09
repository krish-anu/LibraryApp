import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback? onAddToList;
  final VoidCallback? onWriteReview;

  const ActionButtons({super.key, this.onAddToList, this.onWriteReview});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.favorite,
              label: 'Add to List',
              onPressed: onAddToList ?? () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: Icons.rate_review,
              label: 'Write Review',
              onPressed: onWriteReview ?? () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Pallete.primaryLight, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Pallete.border),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
