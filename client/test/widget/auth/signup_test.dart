import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/auth/pages/signup_page.dart';

import '../../test_helpers.dart';

void main() {
  testWidgets('signup validates required fields and expands address fields', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const SignupPage()));

    final button = find.widgetWithText(ElevatedButton, 'Sign Up');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    expect(find.text('Required'), findsNWidgets(2));
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter a password'), findsOneWidget);

    await tester.ensureVisible(find.text('Add Address (optional)'));
    await tester.tap(find.text('Add Address (optional)'));
    await tester.pumpAndSettle();
    expect(find.text('Street Address'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
  });
}
