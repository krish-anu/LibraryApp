import 'package:flutter/material.dart';

/// Sign out button widget.
class ProfileSignOutButton extends StatelessWidget {
  final bool isSigningOut;
  final VoidCallback onSignOut;

  const ProfileSignOutButton({
    super.key,
    required this.isSigningOut,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isSigningOut ? null : onSignOut,
      child: isSigningOut
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFE57373),
              ),
            )
          : const Text(
              "← Sign Out",
              style: TextStyle(color: Color(0xFFE57373), fontSize: 16),
            ),
    );
  }
}
