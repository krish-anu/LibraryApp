import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/features/profile/widgets/profile_header.dart';
import 'package:libraryapp/features/profile/widgets/profile_sign_out_button.dart';
import 'package:libraryapp/models/user_profile.dart';

void main() {
  testWidgets('profile presents member identity and handles sign out', (
    tester,
  ) async {
    var signedOut = false;
    final profile = UserProfile(
      id: 'user-1',
      memberId: 'M001',
      name: 'Ada Lovelace',
      email: 'ada@example.com',
      phone: '+94 77 123 4567',
      joinedDate: DateTime(2024, 1, 1),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              ProfileHeader(userProfile: profile),
              ProfileSignOutButton(
                isSigningOut: false,
                onSignOut: () => signedOut = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
    expect(find.text('Member ID: M001'), findsOneWidget);
    expect(find.text('Member since Jan 2024'), findsOneWidget);
    await tester.tap(find.text('← Sign Out'));
    expect(signedOut, isTrue);
  });
}
