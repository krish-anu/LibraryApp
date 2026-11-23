import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/providers/current_user_notifier.dart';
import 'package:libraryapp/models/user.dart';

void main() {
  test('current user provider stores and clears the authenticated user', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final user = User(
      userName: 'Ada',
      email: 'ada@example.com',
      id: 'member-1',
      token: 'secret-token',
    );

    expect(container.read(currentUserProvider), isNull);
    container.read(currentUserProvider.notifier).addUser(user);
    expect(container.read(currentUserProvider), user);

    container.read(currentUserProvider.notifier).clearUser();
    expect(container.read(currentUserProvider), isNull);
  });
}
