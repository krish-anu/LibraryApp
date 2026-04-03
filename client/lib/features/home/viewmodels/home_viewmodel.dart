import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:libraryapp/models/book.dart';
import 'package:libraryapp/models/category.dart';
import 'package:libraryapp/data/repository/book_repository.dart';
import 'package:libraryapp/data/repository/category_repository.dart';

part 'home_viewmodel.g.dart';

/// State class for Home page
class HomeState {
  final List<Book> books;
  final List<Category> categories;
  final bool hasLoadedBooks;
  final bool hasLoadedCategories;
  final String? error;

  const HomeState({
    this.books = const [],
    this.categories = const [],
    this.hasLoadedBooks = false,
    this.hasLoadedCategories = false,
    this.error,
  });

  HomeState copyWith({
    List<Book>? books,
    List<Category>? categories,
    bool? hasLoadedBooks,
    bool? hasLoadedCategories,
    String? error,
    bool clearError = false,
  }) {
    return HomeState(
      books: books ?? this.books,
      categories: categories ?? this.categories,
      hasLoadedBooks: hasLoadedBooks ?? this.hasLoadedBooks,
      hasLoadedCategories: hasLoadedCategories ?? this.hasLoadedCategories,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isLoading => !(hasLoadedBooks && hasLoadedCategories);

  /// Get trending books (first 6)
  List<Book> get trendingBooks => books.take(6).toList();

  /// Get recommended books (reversed order)
  List<Book> get recommendedBooks => books.reversed.take(6).toList();
}

@riverpod
class HomeViewModel extends _$HomeViewModel {
  @override
  HomeState build() {
    // Defer loading until after build completes to avoid accessing state before initialization
    Future.microtask(() => _loadInitialData());
    return const HomeState();
  }

  Future<void> _loadInitialData() async {
    if (!ref.mounted) return;
    await Future.wait([_loadBooks(), _loadCategories()]);
  }

  Future<void> _loadBooks() async {
    if (!ref.mounted) return;
    try {
      final repository = ref.read(bookRepositoryProvider);
      final result = await repository.getAllBooks();
      if (!ref.mounted) return;
      result.fold(
        (failure) => state = state.copyWith(
          hasLoadedBooks: true,
          error: failure.message,
        ),
        (books) =>
            state = state.copyWith(books: books, hasLoadedBooks: true),
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(hasLoadedBooks: true, error: e.toString());
    }
  }

  Future<void> _loadCategories() async {
    if (!ref.mounted) return;
    try {
      final categories = await ref.read(fetchCategoriesProvider.future);
      if (!ref.mounted) return;
      state = state.copyWith(
        categories: categories,
        hasLoadedCategories: true,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        hasLoadedCategories: true,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    ref.invalidate(fetchCategoriesProvider);
    state = state.copyWith(
      hasLoadedBooks: false,
      hasLoadedCategories: false,
      clearError: true,
    );
    await _loadInitialData();
  }
}
