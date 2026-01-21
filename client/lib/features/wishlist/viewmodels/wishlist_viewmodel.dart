import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:libraryapp/models/book.dart';
import 'package:libraryapp/data/repository/favorites_repository.dart';

part 'wishlist_viewmodel.g.dart';

/// State class for Wishlist page
class WishlistState {
  final List<Book> favorites;
  final String selectedFilter;
  final bool isLoading;
  final String? error;
  final String memberId;

  const WishlistState({
    this.favorites = const [],
    this.selectedFilter = 'All',
    this.isLoading = false,
    this.error,
    this.memberId = 'm1',
  });

  WishlistState copyWith({
    List<Book>? favorites,
    String? selectedFilter,
    bool? isLoading,
    String? error,
    String? memberId,
  }) {
    return WishlistState(
      favorites: favorites ?? this.favorites,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      memberId: memberId ?? this.memberId,
    );
  }

  /// Get filtered favorites based on selected filter
  List<Book> get filteredFavorites {
    switch (selectedFilter) {
      case 'Available Now':
        return favorites.where((book) => book.copiesOwned > 0).toList();
      case 'Fiction':
        return favorites
            .where(
              (book) =>
                  book.category.toLowerCase() == 'fiction' ||
                  book.category.toLowerCase() == 'science fiction' ||
                  book.category.toLowerCase() == 'fantasy',
            )
            .toList();
      case 'Non-Fiction':
        return favorites
            .where(
              (book) =>
                  book.category.toLowerCase() != 'fiction' &&
                  book.category.toLowerCase() != 'science fiction' &&
                  book.category.toLowerCase() != 'fantasy',
            )
            .toList();
      default:
        return favorites;
    }
  }

  bool get isEmpty => favorites.isEmpty;
  bool get hasNoResults => filteredFavorites.isEmpty && favorites.isNotEmpty;
}

@riverpod
class WishlistViewModel extends _$WishlistViewModel {
  @override
  WishlistState build() {
    // Defer loading until after build completes to avoid accessing state before initialization
    Future.microtask(() => _loadFavorites());
    return const WishlistState(isLoading: true);
  }

  Future<void> _loadFavorites() async {
    if (!ref.mounted) return;
    try {
      final memberId = state.memberId;
      final repository = ref.read(favoritesRepositoryProvider);
      final result = await repository.getFavorites(memberId);
      if (!ref.mounted) return;
      result.fold(
        (failure) =>
            state = state.copyWith(isLoading: false, error: failure.message),
        (favorites) =>
            state = state.copyWith(favorites: favorites, isLoading: false),
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void clearFilter() {
    state = state.copyWith(selectedFilter: 'All');
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _loadFavorites();
  }

  Future<bool> removeFavorite(String bookId) async {
    try {
      final repository = ref.read(favoritesRepositoryProvider);
      final result = await repository.removeFavorite(state.memberId, bookId);
      return result.fold((failure) => false, (success) {
        // Remove from local state
        final updatedFavorites = state.favorites
            .where((book) => book.id != bookId)
            .toList();
        state = state.copyWith(favorites: updatedFavorites);
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<bool> addFavorite(Book book) async {
    try {
      final repository = ref.read(favoritesRepositoryProvider);
      final result = await repository.addFavorite(state.memberId, book.id);
      return result.fold((failure) => false, (success) {
        // Add to local state
        final updatedFavorites = [...state.favorites, book];
        state = state.copyWith(favorites: updatedFavorites);
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleFavorite(Book book) async {
    final isFavorite = state.favorites.any((b) => b.id == book.id);
    if (isFavorite) {
      return removeFavorite(book.id);
    } else {
      return addFavorite(book);
    }
  }
}
