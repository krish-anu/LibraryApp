import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/core/widgets/book_view/category_chips.dart';
import 'package:libraryapp/core/widgets/book_view/summary_section.dart';

void main() {
  testWidgets(
    'book details connect category, summary, and availability action',
    (tester) async {
      var reserveRequested = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                const CategoryChips(category: 'Science'),
                SummarySection(
                  description: 'A journey through the universe.',
                  isAvailable: false,
                  onBorrowPressed: () => reserveRequested = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Science'), findsOneWidget);
      expect(find.text('A journey through the universe.'), findsOneWidget);
      await tester.tap(find.text('Reserve Now'));
      expect(reserveRequested, isTrue);
    },
  );
}
