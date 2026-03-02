import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:libraryapp/models/book.dart';
import 'package:libraryapp/data/repository/book_repository.dart';

part 'search_viewmodel.g.dart';

/// State class for Search page
class SearchState {
  final List<Book> allBooks;
  final String searchQuery;
  final String? selectedCategory;
  final String? selectedAuthor;
  final String sortBy;
  final bool showSearchResults;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.allBooks = const [],
    this.searchQuery = '',
    this.selectedCategory,
    this.selectedAuthor,
    this.sortBy = 'Popular',
    this.showSearchResults = false,
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    List<Book>? allBooks,
    String? searchQuery,
    String? selectedCategory,
    String? selectedAuthor,
    String? sortBy,
    bool? showSearchResults,
    bool? isLoading,
    String? error,
    bool clearCategory = false,
    bool clearAuthor = false,
  }) {
    return SearchState(
      allBooks: allBooks ?? this.allBooks,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      selectedAuthor: clearAuthor
          ? null
          : (selectedAuthor ?? this.selectedAuthor),
      sortBy: sortBy ?? this.sortBy,
      showSearchResults: showSearchResults ?? this.showSearchResults,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get all unique categories from books
  List<String> get categories =>
      allBooks.map((b) => b.category).toSet().toList();

  /// Get all unique authors from books
  List<String> get authors => allBooks.map((b) => b.author).toSet().toList();

  /// Get filtered and sorted books
  List<Book> get filteredBooks {
    var books = allBooks.toList();

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      books = books
          .where(
            (book) =>
                book.title.toLowerCase().contains(query) ||
                book.author.toLowerCase().contains(query) ||
                book.description.toLowerCase().contains(query),
          )
          .toList();
    }

    // Filter by category
    if (selectedCategory != null) {
      books = books.where((book) => book.category == selectedCategory).toList();
    }

    // Filter by author
    if (selectedAuthor != null) {
      books = books.where((book) => book.author == selectedAuthor).toList();
    }

    // Sort books
    switch (sortBy) {
      case 'A-Z':
        books.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Rating':
        books.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Newest':
        books.sort((a, b) => b.publicationYear.compareTo(a.publicationYear));
        break;
      case 'Popular':
      default:
        books.sort((a, b) => b.ratingCount.compareTo(a.ratingCount));
    }

    return books;
  }

  /// Get genres with book counts for grid display
  List<Map<String, dynamic>> get genres {
    final Map<String, Map<String, dynamic>> genreMap = {};
    for (final book in allBooks) {
      final name = book.category;
      if (genreMap.containsKey(name)) {
        genreMap[name]!['count'] = (genreMap[name]!['count'] as int) + 1;
      } else {
        genreMap[name] = {'name': name, 'count': 1, 'image': book.image};
      }
    }
    return genreMap.values.toList();
  }
}

@riverpod
class SearchViewModel extends _$SearchViewModel {
  @override
  SearchState build({String? initialCategory}) {
    // Defer loading until after build completes to avoid accessing state before initialization
    Future.microtask(() => _loadBooks());
    return SearchState(
      isLoading: true,
      selectedCategory: initialCategory,
      showSearchResults: initialCategory != null,
    );
  }

  Future<void> _loadBooks() async {
    if (!ref.mounted) return;
    try {
      final repository = ref.read(bookRepositoryProvider);
      final result = await repository.getAllBooks();
      if (!ref.mounted) return;
      result.fold(
        (failure) =>
            state = state.copyWith(isLoading: false, error: failure.message),
        (books) => state = state.copyWith(allBooks: books, isLoading: false),
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(String? category) {
    state = state.copyWith(
      selectedCategory: category,
      clearCategory: category == null,
      showSearchResults: true,
    );
  }

  void setAuthor(String? author) {
    state = state.copyWith(selectedAuthor: author, clearAuthor: author == null);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void toggleSearchResults() {
    state = state.copyWith(showSearchResults: !state.showSearchResults);
  }

  void openSearch() {
    state = state.copyWith(showSearchResults: true);
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearCategory: true,
      clearAuthor: true,
      sortBy: 'Popular',
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _loadBooks();
  }
}
