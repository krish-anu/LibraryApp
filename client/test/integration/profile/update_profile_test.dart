import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/models/user_profile.dart';

void main() {
  test('profile update preserves identity while changing contact details', () {
    final original = UserProfile(
      id: 'user-1',
      memberId: 'M001',
      name: 'Ada Lovelace',
      email: 'ada@example.com',
      phone: '0710000000',
      address: 'Old address',
    );

    final updated = original.copyWith(
      phone: '0771234567',
      address: '42 Library Road',
    );
    final roundTrip = UserProfile.fromJson(updated.toJson());

    expect(roundTrip.id, original.id);
    expect(roundTrip.memberId, original.memberId);
    expect(roundTrip.email, original.email);
    expect(roundTrip.phone, '0771234567');
    expect(roundTrip.address, '42 Library Road');
  });
}
