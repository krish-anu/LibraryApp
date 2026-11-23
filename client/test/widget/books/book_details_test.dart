import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/core/widgets/book_view/book_info_section.dart';
import 'package:libraryapp/core/widgets/book_view/summary_section.dart';

void main() {
  testWidgets('book details sections show metadata and invoke borrow action', (
    tester,
  ) async {
    var borrowed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              const BookInfoSection(
                title: 'Clean Code',
                author: 'Robert Martin',
                rating: 4.8,
                ratingCount: 120,
                pages: 464,
                language: 'English',
              ),
              SummarySection(
                description: 'Readable and maintainable software.',
                isAvailable: true,
                onBorrowPressed: () => borrowed = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Clean Code'), findsOneWidget);
    expect(find.text('Robert Martin'), findsOneWidget);
    expect(find.text('Readable and maintainable software.'), findsOneWidget);
    await tester.ensureVisible(find.text('Borrow Now'));
    await tester.tap(find.text('Borrow Now'));
    expect(borrowed, isTrue);
  });
}
