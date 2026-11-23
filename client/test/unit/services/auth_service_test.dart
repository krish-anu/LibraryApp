import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/auth/repositories/auth_remote_repository.dart';
import 'package:libraryapp/auth/services/asgardeo_direct_auth_service.dart';

void main() {
  test('AuthResult represents successful and failed operations', () {
    final success = AuthResult.success('token');
    final failure = AuthResult<String>.failure('invalid credentials');

    expect(success.success, isTrue);
    expect(success.data, 'token');
    expect(success.error, isNull);
    expect(failure.success, isFalse);
    expect(failure.data, isNull);
    expect(failure.error, 'invalid credentials');
  });

  test('legacy password login is rejected in favor of Asgardeo', () async {
    final result = await AuthRemoteRepository().login(
      'member@example.com',
      'Password1',
    );

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure.message, contains('Asgardeo PKCE')),
      (_) => fail('Legacy login must not succeed'),
    );
  });
}
