import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showBack;
  final VoidCallback? onBack;
  final PreferredSizeWidget? bottom;

  const CommonAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.showBack = true,
    this.onBack,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Pallete.scaffoldBackground,
      elevation: 0,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Pallete.iconColor),
              onPressed: onBack ?? () => Navigator.maybePop(context),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: Pallete.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      centerTitle: centerTitle,
      actions: actions,
      bottom: bottom,
    );
  }
}
