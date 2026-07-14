import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/core/utils/book_share_link.dart';
import 'package:libraryapp/models/book.dart';

void main() {
  Book book() {
    return Book(
      id: 'book-qa-1',
      title: 'Quality Engineering',
      author: 'Ada Lovelace',
      category: 'Technology',
      description: 'Testing resilient systems.',
      rating: 4.8,
      publicationYear: 2026,
      copiesOwned: 3,
      image: '/books/book-qa-1/image',
      language: 'English',
      pages: 320,
      ratingCount: 42,
    );
  }

  test('buildUri and parse round-trip a book deep link', () {
    final original = book();
    final uri = BookShareLink.buildUri(original);
    final parsed = BookShareLink.parse(uri);

    expect(uri.scheme, 'libraryapp');
    expect(uri.host, 'book');
    expect(parsed, original);
  });

  test('parse returns null for unsupported links and links without title', () {
    expect(
      BookShareLink.parse(Uri.parse('https://example.com/book?id=1')),
      isNull,
    );
    expect(BookShareLink.parse(Uri.parse('libraryapp://book?id=1')), isNull);
  });

  test('buildShareText includes human-readable metadata and app link', () {
    final text = BookShareLink.buildShareText(book());

    expect(text, contains('Title: Quality Engineering'));
    expect(text, contains('Author: Ada Lovelace'));
    expect(text, contains('Category: Technology'));
    expect(text, contains('libraryapp://book'));
  });
}
