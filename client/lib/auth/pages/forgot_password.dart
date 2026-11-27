import 'package:flutter/material.dart';
import 'package:libraryapp/auth/config/asgardeo_runtime_config.dart';
import 'package:url_launcher/url_launcher.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key, this.openRecovery});

  final Future<bool> Function()? openRecovery;

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  bool _opening = false;
  bool _failed = false;

  Future<void> _openRecovery() async {
    setState(() {
      _opening = true;
      _failed = false;
    });

    bool opened;
    try {
      final openRecovery = widget.openRecovery;
      opened = openRecovery != null
          ? await openRecovery()
          : await launchUrl(
              Uri.parse(AsgardeoRuntimeConfig.selfServicePortalUrl),
              mode: LaunchMode.externalApplication,
            );
    } on Exception {
      opened = false;
    } on StateError {
      opened = false;
    }

    if (!mounted) return;
    setState(() {
      _opening = false;
      _failed = !opened;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Open the account portal and select “Forgot password?” on its sign-in page.',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _opening ? null : _openRecovery,
                  child: Text(_opening ? 'Opening…' : 'Open account portal'),
                ),
                if (_failed) ...[
                  const SizedBox(height: 8),
                  const Text('Could not open the account portal. Try again.'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
