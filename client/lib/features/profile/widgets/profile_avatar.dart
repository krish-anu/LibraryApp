import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

/// Profile avatar with border decoration.
class ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;

  const ProfileAvatar({super.key, required this.imageUrl, this.radius = 50});

  static const _fallbackAsset = 'assets/person.webp';

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final normalizedUrl = imageUrl.trim();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Pallete.primaryLight, width: 3),
      ),
      child: ClipOval(
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: normalizedUrl.isEmpty
              ? Image.asset(_fallbackAsset, fit: BoxFit.cover)
              : Image.network(
                  normalizedUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
                    return Image.asset(_fallbackAsset, fit: BoxFit.cover);
                  },
                ),
        ),
      ),
    );
  }
}
