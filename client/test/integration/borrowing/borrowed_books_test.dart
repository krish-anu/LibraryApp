import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/features/borrowed/widgets/borrowed_stats.dart';

void main() {
  testWidgets('borrowed summary reports total, due-soon, and overdue counts', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BorrowedStats(totalBorrowed: 5, dueSoon: 2, overdue: 1),
        ),
      ),
    );

    expect(find.text('5 books'), findsOneWidget);
    expect(find.text('Borrowed'), findsOneWidget);
    expect(find.text('Due Soon'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
}
