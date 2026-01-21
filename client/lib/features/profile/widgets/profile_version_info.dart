import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

/// Version info widget.
class ProfileVersionInfo extends StatelessWidget {
  const ProfileVersionInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      "App Version 1.0.2",
      style: TextStyle(color: Pallete.textSecondary, fontSize: 12),
    );
  }
}
