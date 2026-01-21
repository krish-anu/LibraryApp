import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:libraryapp/models/book.dart';
import 'package:libraryapp/core/providers/favorites_notifier.dart';
import 'package:libraryapp/core/providers/loans_notifier.dart';
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
    // Watch the global favorites state for reactive updates
    final favoritesState = ref.watch(favoritesProvider);
    final isFavorite = favoritesState.isFavorite(book.id);

    return BookDetailsState(
      book: book,
      isFavorite: isFavorite,
      isLoadingFavorite: favoritesState.isLoading,
    );
  }

  Future<bool> toggleFavorite() async {
    state = state.copyWith(isLoadingFavorite: true);
    try {
      final favoritesNotifier = ref.read(favoritesProvider.notifier);
      final success = await favoritesNotifier.toggleFavorite(state.book);

      if (!ref.mounted) return success;

      if (success) {
        final newStatus = !state.isFavorite;
        state = state.copyWith(
          isFavorite: newStatus,
          isLoadingFavorite: false,
          successMessage: newStatus
              ? 'Added "${state.book.title}" to favorites'
              : 'Removed "${state.book.title}" from favorites',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoadingFavorite: false,
          error: 'Failed to update favorites',
        );
        return false;
      }
    } catch (e) {
      if (!ref.mounted) return false;
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
      final loansNotifier = ref.read(loansProvider.notifier);
      final success = await loansNotifier.borrowBook(
        state.book.id,
        state.memberId,
      );

      if (!ref.mounted) return success;

      if (success) {
        state = state.copyWith(
          isBorrowing: false,
          successMessage: 'Successfully borrowed "${state.book.title}"',
        );
        return true;
      } else {
        state = state.copyWith(
          isBorrowing: false,
          error: 'Failed to borrow book',
        );
        return false;
      }
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(isBorrowing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> reserveBook() async {
    state = state.copyWith(isReserving: true, clearError: true);
    try {
      final loansNotifier = ref.read(loansProvider.notifier);
      final reserve = Reserve(
        id: '',
        bookId: state.book.id,
        memberId: state.memberId,
        reservationDate: DateTime.now().toIso8601String(),
        status: 'pending',
      );
      final success = await loansNotifier.reserveBook(reserve);

      if (!ref.mounted) return success;

      if (success) {
        state = state.copyWith(
          isReserving: false,
          successMessage: 'Successfully reserved "${state.book.title}"',
        );
        return true;
      } else {
        state = state.copyWith(
          isReserving: false,
          error: 'Failed to reserve book',
        );
        return false;
      }
    } catch (e) {
      if (!ref.mounted) return false;
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
