import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:libraryapp/models/book.dart';
import 'package:libraryapp/data/repository/favorites_repository.dart';
import 'package:libraryapp/data/repository/loan_repository.dart';
import 'package:libraryapp/data/repository/reserve_repository.dart';
import 'package:libraryapp/models/reserve.dart';

part 'book_details_viewmodel.g.dart';

/// State class for Book Details page
class BookDetailsState {
  final Book book;
  final bool isFavorite;
  final bool isLoadingFavorite;
  final bool isBorrowing;
  final bool isReserving;
  final String? error;
  final String? successMessage;
  final String memberId;

  const BookDetailsState({
    required this.book,
    this.isFavorite = false,
    this.isLoadingFavorite = true,
    this.isBorrowing = false,
    this.isReserving = false,
    this.error,
    this.successMessage,
    this.memberId = 'm1',
  });

  BookDetailsState copyWith({
    Book? book,
    bool? isFavorite,
    bool? isLoadingFavorite,
    bool? isBorrowing,
    bool? isReserving,
    String? error,
    String? successMessage,
    String? memberId,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return BookDetailsState(
      book: book ?? this.book,
      isFavorite: isFavorite ?? this.isFavorite,
      isLoadingFavorite: isLoadingFavorite ?? this.isLoadingFavorite,
      isBorrowing: isBorrowing ?? this.isBorrowing,
      isReserving: isReserving ?? this.isReserving,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      memberId: memberId ?? this.memberId,
    );
  }

  bool get isAvailable => book.copiesOwned > 0;
}

@riverpod
class BookDetailsViewModel extends _$BookDetailsViewModel {
  @override
  BookDetailsState build(Book book) {
    _checkFavoriteStatus(book.id);
    return BookDetailsState(book: book);
  }

  Future<void> _checkFavoriteStatus(String bookId) async {
    try {
      final repository = ref.read(favoritesRepositoryProvider);
      final result = await repository.checkFavorite(state.memberId, bookId);
      result.fold(
        (failure) => state = state.copyWith(isLoadingFavorite: false),
        (isFav) =>
            state = state.copyWith(isFavorite: isFav, isLoadingFavorite: false),
      );
    } catch (e) {
      state = state.copyWith(isLoadingFavorite: false);
    }
  }

  Future<bool> toggleFavorite() async {
    state = state.copyWith(isLoadingFavorite: true);
    try {
      final repository = ref.read(favoritesRepositoryProvider);
      final result = await repository.toggleFavorite(
        state.memberId,
        state.book.id,
        state.isFavorite,
      );
      return result.fold(
        (failure) {
          state = state.copyWith(
            isLoadingFavorite: false,
            error: failure.message,
          );
          return false;
        },
        (newStatus) {
          state = state.copyWith(
            isFavorite: newStatus,
            isLoadingFavorite: false,
            successMessage: newStatus
                ? 'Added "${state.book.title}" to favorites'
                : 'Removed "${state.book.title}" from favorites',
          );
          // Invalidate favorites providers
          ref.invalidate(fetchFavoritesProvider(state.memberId));
          ref.invalidate(fetchFavoriteIdsProvider(state.memberId));
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(isLoadingFavorite: false, error: e.toString());
      return false;
    }
  }

  Future<bool> borrowBook() async {
    if (!state.isAvailable) {
      state = state.copyWith(error: 'This book is not available');
      return false;
    }

    state = state.copyWith(isBorrowing: true, clearError: true);
    try {
      final repository = ref.read(loanRepositoryProvider);
      final result = await repository.borrowBook(state.book.id, state.memberId);
      return result.fold(
        (failure) {
          state = state.copyWith(isBorrowing: false, error: failure.message);
          return false;
        },
        (loan) {
          state = state.copyWith(
            isBorrowing: false,
            successMessage: 'Successfully borrowed "${state.book.title}"',
          );
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(isBorrowing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> reserveBook() async {
    state = state.copyWith(isReserving: true, clearError: true);
    try {
      final repository = ref.read(reserveRepositoryProvider);
      final reserve = Reserve(
        id: '',
        bookId: state.book.id,
        memberId: state.memberId,
        reservationDate: DateTime.now().toIso8601String(),
        status: 'pending',
      );
      final result = await repository.addReserve(reserve);
      return result.fold(
        (failure) {
          state = state.copyWith(isReserving: false, error: failure.message);
          return false;
        },
        (reservation) {
          state = state.copyWith(
            isReserving: false,
            successMessage: 'Successfully reserved "${state.book.title}"',
          );
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(isReserving: false, error: e.toString());
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
