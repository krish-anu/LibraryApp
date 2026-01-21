import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

/// A tappable search bar that navigates to the search page.
class HomeSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const HomeSearchBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Pallete.searchBarBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Pallete.searchBarHint, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search title, author, ISBN...',
                style: TextStyle(color: Pallete.searchBarHint, fontSize: 15),
              ),
            ),
            Icon(Icons.tune, color: Pallete.searchBarHint, size: 22),
          ],
        ),
      ),
    );
  }
}
