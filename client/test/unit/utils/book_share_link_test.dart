import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/core/utils/book_share_link.dart';
import 'package:libraryapp/models/book.dart';

void main() {
  test('BookShareLink builds an app deep link', () {
    final uri = BookShareLink.buildUri(
      Book(
        id: 'book-1',
        title: 'QA Book',
        author: 'QA Author',
        category: 'Technology',
        description: 'Description',
        rating: 4.5,
        publicationYear: 2024,
        copiesOwned: 1,
        image: '',
      ),
    );

    expect(uri.scheme, 'libraryapp');
    expect(uri.host, 'book');
    expect(uri.queryParameters['title'], 'QA Book');
  });
}
