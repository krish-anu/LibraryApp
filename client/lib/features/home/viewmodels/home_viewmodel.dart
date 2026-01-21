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
  final bool isLoading;
  final String? error;

  const HomeState({
    this.books = const [],
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    List<Book>? books,
    List<Category>? categories,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      books: books ?? this.books,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

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
    return const HomeState(isLoading: true);
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
        (failure) =>
            state = state.copyWith(isLoading: false, error: failure.message),
        (books) => state = state.copyWith(
          books: books,
          isLoading: state.categories.isEmpty,
        ),
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadCategories() async {
    if (!ref.mounted) return;
    try {
      final categories = await ref.read(fetchCategoriesProvider.future);
      if (!ref.mounted) return;
      state = state.copyWith(
        categories: categories,
        isLoading: state.books.isEmpty,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _loadInitialData();
  }
}
