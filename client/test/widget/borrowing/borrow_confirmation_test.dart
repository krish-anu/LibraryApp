import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/core/widgets/book_view/borrow_confirmation_sheet.dart';

import '../../test_helpers.dart';

void main() {
  testWidgets('borrow confirmation reflects book availability', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: BorrowConfirmationSheet(book: sampleBook())),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('READY TO BORROW'), findsOneWidget);
    expect(find.text('Clean Code'), findsOneWidget);
    expect(find.text('Confirm Borrow'), findsNWidgets(2));
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('unavailable book offers reservation confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BorrowConfirmationSheet(book: sampleBook(copiesOwned: 0)),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('RESERVE THIS BOOK'), findsOneWidget);
    expect(find.text('Confirm Reservation'), findsNWidgets(2));
  });
}
