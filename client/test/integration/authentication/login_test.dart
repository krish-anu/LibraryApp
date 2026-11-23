import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/auth/pages/login_page.dart';

import '../../test_helpers.dart';

void main() {
  testWidgets('login rejects an incomplete credential submission', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const Login()));

    await tester.enterText(
      find.byType(TextFormField).first,
      'member@example.com',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();

    expect(find.text('Please enter your password'), findsOneWidget);
    expect(find.text('Please enter your username or email'), findsNothing);
  });
}
