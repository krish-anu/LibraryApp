import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/utils/image_helper.dart';

class BookCoverSection extends StatelessWidget {
  final String imageUrl;
  final bool isAvailable;

  const BookCoverSection({
    super.key,
    required this.imageUrl,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 20),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image(
                image: imageProviderFromPath(imageUrl),
                height: 220,
                width: 150,
                fit: BoxFit.cover,
              ),
            ),
            if (isAvailable) const _AvailabilityBadge(),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Pallete.primaryLight,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'AVAILABLE',
            style: TextStyle(
              color: Pallete.btnTextColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
