import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/features/profile/widgets/profile_stats_widget.dart';
import 'package:libraryapp/models/profile_stats.dart';

void main() {
  testWidgets('fine summary formats currency and activity counts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileStatsWidget(
            stats: ProfileStats(
              totalBorrows: 8,
              booksRead: 5,
              totalFines: 12.5,
              activeLoans: 2,
              activeReservations: 1,
            ),
          ),
        ),
      ),
    );

    expect(find.text('LKR 12.50'), findsOneWidget);
    expect(find.text('FINES'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('BORROWS'), findsOneWidget);
  });
}
