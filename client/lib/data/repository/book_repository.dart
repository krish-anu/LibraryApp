import 'dart:convert';
// import 'package:flutter_riverpod/misc.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:libraryapp/core/constants/server_constant.dart';
import 'package:libraryapp/core/failure/failure.dart';
import 'package:libraryapp/models/book.dart';

part 'book_repository.g.dart';

@riverpod
BookRepository bookRepository(Ref ref) {
  return BookRepository();
}

@riverpod
Future<List<Book>> fetchAllBooks(Ref ref) async {
  final repository = ref.watch(bookRepositoryProvider);
  final res = await repository.getAllBooks();
  return res.fold((l) => throw l.message, (r) => r);
}

class BookRepository {
  Future<Either<Failure, List<Book>>> getAllBooks() async {
    try {
      final res = await http.get(
        Uri.parse('${ServerConstant.serverURL}/books'),
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final books = data.map((e) {
          return Book(
            id: e['id']?.toString() ?? '',
            title: e['title']?.toString() ?? '',
            author: 'Unknown Author',
            category: e['category']?.toString() ?? '',
            description: 'No description available.',
            rating: 0.0,
            publicationYear: e['publication_year'] as int? ?? 0,
            copiesOwned: e['copies_owned'] as int? ?? 0,
            image: 'https://via.placeholder.com/150',
          );
        }).toList();
        return right(books);
      } else {
        return left(Failure(res.body));
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
