import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/common/common_app_bar.dart';

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
    return CommonAppBar(
      title: title,
      centerTitle: true,
      actions: [
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
              color: isFavorite ? Pallete.primaryLight : Pallete.iconColor,
            ),
            onPressed: onFavoritePressed,
          ),
        IconButton(
          icon: const Icon(Icons.ios_share, color: Pallete.iconColor),
          onPressed: () {},
        ),
      ],
    );
  }
}
