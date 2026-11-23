import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/core/widgets/book_view/summary_section.dart';

void main() {
  testWidgets('available book exposes and dispatches the borrow action', (
    tester,
  ) async {
    var borrowCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SummarySection(
            description: 'Available title',
            isAvailable: true,
            onBorrowPressed: () => borrowCount++,
          ),
        ),
      ),
    );

    expect(find.text('Borrow Now'), findsOneWidget);
    await tester.tap(find.text('Borrow Now'));
    expect(borrowCount, 1);
  });
}
