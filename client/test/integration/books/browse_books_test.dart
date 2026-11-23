import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/features/search/viewmodels/search_viewmodel.dart';

import '../../test_helpers.dart';

void main() {
  test('browse state groups books into genres with accurate counts', () {
    final state = SearchState(
      allBooks: [
        sampleBook(id: '1', category: 'Technology'),
        sampleBook(id: '2', category: 'Technology'),
        sampleBook(id: '3', category: 'History'),
      ],
    );

    final genres = {for (final genre in state.genres) genre['name']: genre};
    expect(genres['Technology']?['count'], 2);
    expect(genres['History']?['count'], 1);
  });
}
