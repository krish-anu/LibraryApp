import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/auth/pages/forgot_password.dart';

void main() {
  testWidgets('forgot password route builds without crashing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ForgotPassword())),
    );

    expect(find.byType(ForgotPassword), findsOneWidget);
    expect(find.byType(Placeholder), findsOneWidget);
  });
}
