import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/auth/pages/forgot_password.dart';
import 'package:libraryapp/auth/pages/login_page.dart';

void main() {
  testWidgets('sign-in opens the password recovery page', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: Login())),
    );

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPassword), findsOneWidget);
    expect(find.text('Open account portal'), findsOneWidget);
  });

  testWidgets(
    'password recovery can retry if the account portal fails to open',
    (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ForgotPassword(openRecovery: () async => ++attempts > 1),
        ),
      );

      final button = find.text('Open account portal');
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(attempts, 1);
      expect(
        find.text('Could not open the account portal. Try again.'),
        findsOneWidget,
      );

      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(
        find.text('Could not open the account portal. Try again.'),
        findsNothing,
      );
    },
  );
}
