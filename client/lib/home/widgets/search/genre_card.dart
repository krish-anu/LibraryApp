import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/utils/image_helper.dart';

/// A card widget displaying a genre with its book count and image.
class GenreCard extends StatelessWidget {
  final String name;
  final int count;
  final String imageUrl;
  final VoidCallback onTap;

  const GenreCard({
    super.key,
    required this.name,
    required this.count,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: imageProviderFromPath(imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              // ignore: deprecated_member_use
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            _buildGradientOverlay(),
            _buildContent(),
            _buildArrowIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // ignore: deprecated_member_use
          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$count books",
            style: TextStyle(color: Pallete.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowIcon() {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Pallete.primaryLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
      ),
    );
  }
}
