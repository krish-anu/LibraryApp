import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/features/search/widgets/search_results_grid.dart';
import 'package:libraryapp/features/search/widgets/search_text_field.dart';

void main() {
  testWidgets('search input emits text and empty results explain the outcome', (
    tester,
  ) async {
    var query = '';
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SearchTextField(
                controller: controller,
                onChanged: (value) => query = value,
              ),
              const Expanded(child: SearchResultsGrid(books: [])),
            ],
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'architecture');
    expect(query, 'architecture');
    expect(find.text('No books found'), findsOneWidget);
  });
}
