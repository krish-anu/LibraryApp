import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/features/search/viewmodels/search_viewmodel.dart';

import '../../test_helpers.dart';

void main() {
  test('search combines query, category, author, and rating sort', () {
    final state = SearchState(
      allBooks: [
        sampleBook(
          id: '1',
          title: 'Clean Architecture',
          author: 'Robert Martin',
          category: 'Technology',
          rating: 4.5,
        ),
        sampleBook(
          id: '2',
          title: 'Clean Code',
          author: 'Robert Martin',
          category: 'Technology',
          rating: 4.9,
        ),
        sampleBook(
          id: '3',
          title: 'Ancient Worlds',
          author: 'A. Historian',
          category: 'History',
          rating: 5,
        ),
      ],
      searchQuery: 'clean',
      selectedCategory: 'Technology',
      selectedAuthor: 'Robert Martin',
      sortBy: 'Rating',
    );

    expect(state.filteredBooks.map((book) => book.title), [
      'Clean Code',
      'Clean Architecture',
    ]);
  });
}
