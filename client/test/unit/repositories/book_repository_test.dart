import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/data/repository/book_repository.dart';

void main() {
  test('book repository maps successful API data into books', () async {
    final repository = BookRepository(
      get: (_) async => http.Response(
        '[{"id":"b1","title":"Clean Code","author":"Robert Martin",'
        '"category":"Tech","description":"Readable code",'
        '"rating":4.7,"publication_year":2008,"copies_owned":3,'
        '"image":"cover.webp","language":"English","pages":464,'
        '"rating_count":99}]',
        200,
      ),
    );

    final result = await repository.getAllBooks(forceRefresh: true);

    result.fold((failure) => fail('Expected books, got ${failure.message}'), (
      books,
    ) {
      expect(books, hasLength(1));
      expect(books.single.title, 'Clean Code');
      expect(books.single.rating, 4.7);
      expect(books.single.copiesOwned, 3);
    });
  });

  test('book repository returns a failure for non-success responses', () async {
    final repository = BookRepository(
      get: (_) async => http.Response('service unavailable', 503),
    );

    final result = await repository.getAllBooks(forceRefresh: true);

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure.message, 'service unavailable'),
      (_) => fail('Expected a failure'),
    );
  });

  test(
    'invalidating the cache forces the next request to reload books',
    () async {
      var calls = 0;
      final repository = BookRepository(
        get: (_) async {
          calls += 1;
          return http.Response(
            '[{"id":"b1","title":"Version $calls","author":"Author",'
            '"category":"Tech","copies_owned":1}]',
            200,
          );
        },
      );

      final first = await repository.getAllBooks(forceRefresh: true);
      final cached = await repository.getAllBooks();
      repository.invalidateCache();
      final refreshed = await repository.getAllBooks();

      expect(calls, 2);
      expect(first.getOrElse((_) => []).single.title, 'Version 1');
      expect(cached.getOrElse((_) => []).single.title, 'Version 1');
      expect(refreshed.getOrElse((_) => []).single.title, 'Version 2');
    },
  );
}
