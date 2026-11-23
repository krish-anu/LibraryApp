import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/core/providers/current_user_notifier.dart';
import 'package:libraryapp/features/profile/widgets/profile_sign_out_button.dart';
import 'package:libraryapp/models/user.dart';

void main() {
  testWidgets('sign out action clears the current member session', (
    tester,
  ) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              home: Scaffold(
                body: ProfileSignOutButton(
                  isSigningOut: false,
                  onSignOut: () =>
                      ref.read(currentUserProvider.notifier).clearUser(),
                ),
              ),
            );
          },
        ),
      ),
    );
    container
        .read(currentUserProvider.notifier)
        .addUser(
          User(
            userName: 'Member',
            email: 'member@example.com',
            id: 'm1',
            token: 'token',
          ),
        );
    expect(container.read(currentUserProvider), isNotNull);

    await tester.tap(find.text('← Sign Out'));
    await tester.pump();
    expect(container.read(currentUserProvider), isNull);
  });
}
