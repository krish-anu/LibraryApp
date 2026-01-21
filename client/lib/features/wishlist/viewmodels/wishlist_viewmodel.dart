import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:libraryapp/models/book.dart';
import 'package:libraryapp/core/providers/favorites_notifier.dart';

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
    // Watch the global favorites notifier for reactive updates
    final favoritesState = ref.watch(favoritesProvider);

    return WishlistState(
      favorites: favoritesState.favorites,
      isLoading: favoritesState.isLoading,
      error: favoritesState.error,
      memberId: favoritesState.memberId,
    );
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void clearFilter() {
    state = state.copyWith(selectedFilter: 'All');
  }

  Future<void> refresh() async {
    await ref.read(favoritesProvider.notifier).loadFavorites();
  }

  Future<bool> removeFavorite(String bookId) async {
    return ref.read(favoritesProvider.notifier).removeFavorite(bookId);
  }

  Future<bool> addFavorite(Book book) async {
    return ref.read(favoritesProvider.notifier).addFavorite(book);
  }

  Future<bool> toggleFavorite(Book book) async {
    return ref.read(favoritesProvider.notifier).toggleFavorite(book);
  }
}
