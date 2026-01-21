import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:libraryapp/models/book.dart';
import 'package:libraryapp/data/repository/favorites_repository.dart';

part 'favorites_notifier.g.dart';

/// Global favorites state that can be shared across all viewmodels
class FavoritesState {
  final List<Book> favorites;
  final Set<String> favoriteIds;
  final bool isLoading;
  final String? error;
  final String memberId;

  const FavoritesState({
    this.favorites = const [],
    this.favoriteIds = const {},
    this.isLoading = false,
    this.error,
    this.memberId = 'm1',
  });

  FavoritesState copyWith({
    List<Book>? favorites,
    Set<String>? favoriteIds,
    bool? isLoading,
    String? error,
    String? memberId,
  }) {
    return FavoritesState(
      favorites: favorites ?? this.favorites,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      memberId: memberId ?? this.memberId,
    );
  }

  bool isFavorite(String bookId) => favoriteIds.contains(bookId);
}

/// Global favorites notifier - single source of truth for favorites
@Riverpod(keepAlive: true)
class FavoritesNotifier extends _$FavoritesNotifier {
  @override
  FavoritesState build() {
    Future.microtask(() => loadFavorites());
    return const FavoritesState(isLoading: true);
  }

  Future<void> loadFavorites() async {
    if (!ref.mounted) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(favoritesRepositoryProvider);
      final memberId = state.memberId;

      // Load both favorites list and IDs
      final results = await Future.wait([
        repository.getFavorites(memberId),
        repository.getFavoriteIds(memberId),
      ]);

      if (!ref.mounted) return;

      final favoritesResult = results[0];
      final idsResult = results[1];

      favoritesResult.fold(
        (failure) =>
            state = state.copyWith(isLoading: false, error: failure.message),
        (favorites) {
          idsResult.fold(
            (failure) => state = state.copyWith(
              favorites: favorites as List<Book>,
              favoriteIds: (favorites).map((b) => b.id).toSet(),
              isLoading: false,
            ),
            (ids) => state = state.copyWith(
              favorites: favorites as List<Book>,
              favoriteIds: ids as Set<String>,
              isLoading: false,
            ),
          );
        },
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addFavorite(Book book) async {
    try {
      final repository = ref.read(favoritesRepositoryProvider);
      final result = await repository.addFavorite(state.memberId, book.id);

      return result.fold((failure) => false, (success) {
        if (!ref.mounted) return true;
        // Optimistically update local state
        final updatedFavorites = [...state.favorites, book];
        final updatedIds = {...state.favoriteIds, book.id};
        state = state.copyWith(
          favorites: updatedFavorites,
          favoriteIds: updatedIds,
        );
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFavorite(String bookId) async {
    try {
      final repository = ref.read(favoritesRepositoryProvider);
      final result = await repository.removeFavorite(state.memberId, bookId);

      return result.fold((failure) => false, (success) {
        if (!ref.mounted) return true;
        // Optimistically update local state
        final updatedFavorites = state.favorites
            .where((b) => b.id != bookId)
            .toList();
        final updatedIds = state.favoriteIds
            .where((id) => id != bookId)
            .toSet();
        state = state.copyWith(
          favorites: updatedFavorites,
          favoriteIds: updatedIds,
        );
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleFavorite(Book book) async {
    if (state.isFavorite(book.id)) {
      return removeFavorite(book.id);
    } else {
      return addFavorite(book);
    }
  }

  void setMemberId(String memberId) {
    if (state.memberId != memberId) {
      state = state.copyWith(memberId: memberId);
      loadFavorites();
    }
  }
}
