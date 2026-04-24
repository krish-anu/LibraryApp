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
  final String? booksError;
  final String? categoriesError;

  const HomeState({
    this.books = const [],
    this.categories = const [],
    this.hasLoadedBooks = false,
    this.hasLoadedCategories = false,
    this.booksError,
    this.categoriesError,
  });

  HomeState copyWith({
    List<Book>? books,
    List<Category>? categories,
    bool? hasLoadedBooks,
    bool? hasLoadedCategories,
    String? booksError,
    String? categoriesError,
    bool clearBooksError = false,
    bool clearCategoriesError = false,
  }) {
    return HomeState(
      books: books ?? this.books,
      categories: categories ?? this.categories,
      hasLoadedBooks: hasLoadedBooks ?? this.hasLoadedBooks,
      hasLoadedCategories: hasLoadedCategories ?? this.hasLoadedCategories,
      booksError: clearBooksError ? null : (booksError ?? this.booksError),
      categoriesError: clearCategoriesError
          ? null
          : (categoriesError ?? this.categoriesError),
    );
  }

  bool get isLoading => !hasLoadedBooks;
  bool get isCategoriesLoading => !hasLoadedCategories;

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

  Future<void> _loadBooks({bool forceRefresh = false}) async {
    if (!ref.mounted) return;
    try {
      final repository = ref.read(bookRepositoryProvider);
      final result = await repository.getAllBooks(forceRefresh: forceRefresh);
      if (!ref.mounted) return;
      result.fold(
        (failure) => state = state.copyWith(
          hasLoadedBooks: true,
          booksError: failure.message,
        ),
        (books) => state = state.copyWith(
          books: books,
          hasLoadedBooks: true,
          clearBooksError: true,
        ),
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(hasLoadedBooks: true, booksError: e.toString());
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
        clearCategoriesError: true,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        hasLoadedCategories: true,
        categoriesError: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    ref.invalidate(fetchCategoriesProvider);
    state = state.copyWith(
      hasLoadedBooks: false,
      hasLoadedCategories: false,
      clearBooksError: true,
      clearCategoriesError: true,
    );
    await Future.wait([_loadBooks(forceRefresh: true), _loadCategories()]);
  }

  Future<void> refreshCategories() async {
    ref.invalidate(fetchCategoriesProvider);
    state = state.copyWith(
      hasLoadedCategories: false,
      clearCategoriesError: true,
    );
    await _loadCategories();
  }
}
