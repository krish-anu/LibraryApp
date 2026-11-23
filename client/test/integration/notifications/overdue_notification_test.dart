import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/models/app_notification.dart';

void main() {
  test('overdue notification parses metadata and can be marked read', () {
    final notification = AppNotification.fromMap({
      'id': 'notification-1',
      'title': 'Book overdue',
      'body': 'Clean Code is overdue.',
      'category': 'loan_overdue',
      'recipient_type': 'member',
      'recipient_id': 'member-1',
      'metadata': {'book_id': 'book-1', 'days_overdue': 3},
      'read': false,
      'created_at': '2026-11-20T10:00:00Z',
      'updated_at': '2026-11-20T10:00:00Z',
    });

    expect(notification.category, 'loan_overdue');
    expect(notification.metadata['days_overdue'], 3);
    expect(notification.read, isFalse);

    final read = notification.copyWith(
      read: true,
      readAt: DateTime(2026, 11, 23),
    );
    expect(read.read, isTrue);
    expect(read.readAt, DateTime(2026, 11, 23));
  });
}
