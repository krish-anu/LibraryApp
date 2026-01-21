import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

/// Profile avatar with border decoration.
class ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;

  const ProfileAvatar({super.key, required this.imageUrl, this.radius = 50});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Pallete.primaryLight, width: 3),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (exception, stackTrace) {},
        child: null,
      ),
    );
  }
}
