import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/features/borrowed/widgets/borrowed_book_card.dart';

import '../../test_helpers.dart';

void main() {
  testWidgets('past due date displays overdue status and calculated fine', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BorrowedBookCard(
            book: sampleBook(),
            dueDate: DateTime.now().subtract(const Duration(days: 4)),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('OVERDUE'), findsOneWidget);
    expect(find.textContaining('days overdue'), findsOneWidget);
    expect(find.textContaining('Fine: LKR'), findsOneWidget);
  });
}
