import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:libraryapp/core/constants/server_constant.dart';
import 'package:libraryapp/core/failure/failure.dart';
import 'package:libraryapp/core/services/authenticated_http_client.dart';
import 'package:libraryapp/models/book.dart';

part 'favorites_repository.g.dart';

@riverpod
FavoritesRepository favoritesRepository(Ref ref) {
  return FavoritesRepository();
}

@riverpod
Future<List<Book>> fetchFavorites(Ref ref, String memberId) async {
  final repository = ref.watch(favoritesRepositoryProvider);
  final res = await repository.getFavorites(memberId);
  return res.fold((l) => throw l.message, (r) => r);
}

@riverpod
Future<Set<String>> fetchFavoriteIds(Ref ref, String memberId) async {
  final repository = ref.watch(favoritesRepositoryProvider);
  final res = await repository.getFavoriteIds(memberId);
  return res.fold((l) => throw l.message, (r) => r);
}

class FavoritesRepository {
  Future<Either<Failure, List<Book>>> getFavorites(String memberId) async {
    try {
      final res = await AuthenticatedHttpClient.get(
        Uri.parse('${ServerConstant.serverURL}/favorites/$memberId'),
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final books = data.map((e) => _parseBook(e)).toList();
        return right(books);
      } else {
        return left(Failure(res.body));
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, Set<String>>> getFavoriteIds(String memberId) async {
    try {
      final res = await AuthenticatedHttpClient.get(
        Uri.parse('${ServerConstant.serverURL}/favorites/$memberId/ids'),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> ids = data['book_ids'] ?? [];
        return right(ids.map((e) => e.toString()).toSet());
      } else {
        return left(Failure(res.body));
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, bool>> addFavorite(
    String memberId,
    String bookId,
  ) async {
    try {
      final res = await AuthenticatedHttpClient.post(
        Uri.parse('${ServerConstant.serverURL}/favorites/$memberId/$bookId'),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return right(data['is_favorite'] ?? true);
      } else {
        return left(Failure(res.body));
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, bool>> removeFavorite(
    String memberId,
    String bookId,
  ) async {
    try {
      final res = await AuthenticatedHttpClient.delete(
        Uri.parse('${ServerConstant.serverURL}/favorites/$memberId/$bookId'),
      );

      if (res.statusCode == 200) {
        return right(false);
      } else {
        return left(Failure(res.body));
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, bool>> toggleFavorite(
    String memberId,
    String bookId,
    bool isFavorite,
  ) async {
    if (isFavorite) {
      return removeFavorite(memberId, bookId);
    } else {
      return addFavorite(memberId, bookId);
    }
  }

  Future<Either<Failure, bool>> checkFavorite(
    String memberId,
    String bookId,
  ) async {
    try {
      final res = await AuthenticatedHttpClient.get(
        Uri.parse(
          '${ServerConstant.serverURL}/favorites/$memberId/$bookId/check',
        ),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return right(data['is_favorite'] ?? false);
      } else {
        return left(Failure(res.body));
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Book _parseBook(Map<String, dynamic> e) {
    return Book(
      id: e['id']?.toString() ?? '',
      title: e['title'] ?? '',
      author: e['author'] ?? '',
      category: e['category'] ?? '',
      description: e['description'] ?? '',
      rating: (e['rating'] ?? 0).toDouble(),
      publicationYear: (e['publication_year'] ?? 0).toInt(),
      copiesOwned: (e['copies_owned'] ?? 0).toInt(),
      image: e['image'] ?? '',
    );
  }
}
