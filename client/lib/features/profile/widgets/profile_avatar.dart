import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/utils/image_helper.dart';

/// Profile avatar with border decoration.
class ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;

  const ProfileAvatar({super.key, required this.imageUrl, this.radius = 50});

  static const _fallbackAsset = 'assets/person.webp';

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final imageProvider = imageProviderFromPath(imageUrl);

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
          child: Image(
            image: imageProvider,
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
