import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

class BookViewAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isFavorite;
  final bool isLoadingFavorite;
  final VoidCallback? onFavoritePressed;

  const BookViewAppBar({
    super.key,
    required this.title,
    this.isFavorite = false,
    this.isLoadingFavorite = false,
    this.onFavoritePressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Pallete.scaffoldBackground,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      centerTitle: true,
      actions: [
        // Favorite button
        if (isLoadingFavorite)
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Pallete.primaryLight,
              ),
            ),
          )
        else
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Pallete.primaryLight : Colors.white,
            ),
            onPressed: onFavoritePressed,
          ),
        IconButton(
          icon: const Icon(Icons.ios_share, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }
}
