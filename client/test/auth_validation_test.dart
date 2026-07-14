import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/auth/pages/login_page.dart';
import 'package:libraryapp/auth/pages/signup_page.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(home: child),
  );
}

void main() {
  group('Login form validation', () {
    testWidgets('shows required field errors for blank login submit', (tester) async {
      await tester.pumpWidget(_wrap(const Login()));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();

      expect(find.text('Please enter your username or email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('toggles password visibility without losing typed password', (tester) async {
      await tester.pumpWidget(_wrap(const Login()));

      await tester.enterText(find.byType(TextFormField).at(1), 'Secret123');
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();

      expect(find.text('Secret123'), findsOneWidget);
      expect(find.byTooltip('Hide password'), findsOneWidget);
    });
  });

  group('Signup form validation', () {
    testWidgets('rejects malformed email, weak password, and mismatched confirmation', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const SignupPage()));

      await tester.enterText(find.byType(TextFormField).at(0), 'Ada');
      await tester.enterText(find.byType(TextFormField).at(1), 'Lovelace');
      await tester.enterText(find.byType(TextFormField).at(2), 'bad-email');
      await tester.enterText(find.byType(TextFormField).at(5), 'weak');
      await tester.enterText(find.byType(TextFormField).at(6), 'different');
      final signUpButton = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.ensureVisible(signUpButton);
      await tester.tap(signUpButton);
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('expands optional address section', (tester) async {
      await tester.pumpWidget(_wrap(const SignupPage()));

      expect(find.text('Street Address'), findsNothing);

      await tester.tap(find.text('Add Address (optional)'));
      await tester.pumpAndSettle();

      expect(find.text('Street Address'), findsOneWidget);
      expect(find.text('City'), findsOneWidget);
      expect(find.text('Country'), findsOneWidget);
    });
  });
}
