import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:libraryapp/models/book.dart';
import 'package:libraryapp/models/loan.dart';
import 'package:libraryapp/models/reserve.dart';
import 'package:libraryapp/data/repository/book_repository.dart';
import 'package:libraryapp/data/repository/loan_repository.dart';
import 'package:libraryapp/data/repository/reserve_repository.dart';

part 'borrowed_viewmodel.g.dart';

/// Represents a borrowed book item with loan details
class BorrowedItem {
  final Book book;
  final Loan loan;
  final DateTime dueDate;
  final int remainingDays;
  final BorrowStatus status;

  BorrowedItem({
    required this.book,
    required this.loan,
    required this.dueDate,
    required this.remainingDays,
    required this.status,
  });
}

/// Represents a reserved book item
class ReservedItem {
  final Book book;
  final Reserve reservation;

  ReservedItem({required this.book, required this.reservation});
}

enum BorrowStatus { active, dueSoon, overdue }

/// State class for Borrowed page
class BorrowedState {
  final List<Loan> loans;
  final List<Reserve> reservations;
  final List<Book> books;
  final bool isLoading;
  final String? error;
  final String memberId;

  const BorrowedState({
    this.loans = const [],
    this.reservations = const [],
    this.books = const [],
    this.isLoading = false,
    this.error,
    this.memberId = 'm1',
  });

  BorrowedState copyWith({
    List<Loan>? loans,
    List<Reserve>? reservations,
    List<Book>? books,
    bool? isLoading,
    String? error,
    String? memberId,
  }) {
    return BorrowedState(
      loans: loans ?? this.loans,
      reservations: reservations ?? this.reservations,
      books: books ?? this.books,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      memberId: memberId ?? this.memberId,
    );
  }

  /// Get borrowed items with status information
  List<BorrowedItem> get borrowedItems {
    final now = DateTime.now();
    final items = loans.map((loan) {
      final book = books.firstWhere(
        (b) => b.id == loan.bookId,
        orElse: () => books.isNotEmpty ? books.first : _emptyBook,
      );
      final dueDate = loan.returnedDate;
      final remainingDays = dueDate.difference(now).inDays;

      BorrowStatus status;
      if (remainingDays < 0) {
        status = BorrowStatus.overdue;
      } else if (remainingDays <= 3) {
        status = BorrowStatus.dueSoon;
      } else {
        status = BorrowStatus.active;
      }

      return BorrowedItem(
        book: book,
        loan: loan,
        dueDate: dueDate,
        remainingDays: remainingDays,
        status: status,
      );
    }).toList();

    // Sort: overdue first, then due soon, then by due date
    items.sort((a, b) {
      if (a.status == BorrowStatus.overdue && b.status != BorrowStatus.overdue) {
        return -1;
      }
      if (b.status == BorrowStatus.overdue && a.status != BorrowStatus.overdue) {
        return 1;
      }
      return a.dueDate.compareTo(b.dueDate);
    });

    return items;
  }

  /// Get reserved items
  List<ReservedItem> get reservedItems {
    return reservations.map((reservation) {
      final book = books.firstWhere(
        (b) => b.id == reservation.bookId,
        orElse: () => books.isNotEmpty ? books.first : _emptyBook,
      );
      return ReservedItem(book: book, reservation: reservation);
    }).toList();
  }

  /// Statistics
  int get totalBorrowed => loans.length;
  int get dueSoonCount =>
      borrowedItems.where((i) => i.status == BorrowStatus.dueSoon).length;
  int get overdueCount =>
      borrowedItems.where((i) => i.status == BorrowStatus.overdue).length;
  int get totalReserved => reservations.length;

  static final Book _emptyBook = Book(
    id: '',
    title: 'Unknown',
    author: 'Unknown',
    category: '',
    description: '',
    rating: 0,
    publicationYear: 0,
    copiesOwned: 0,
    image: '',
  );
}

@riverpod
class BorrowedViewModel extends _$BorrowedViewModel {
  @override
  BorrowedState build() {
    _loadInitialData();
    return const BorrowedState(isLoading: true);
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadBooks(), _loadLoans(), _loadReservations()]);
  }

  Future<void> _loadBooks() async {
    try {
      final repository = ref.read(bookRepositoryProvider);
      final result = await repository.getAllBooks();
      result.fold(
        (failure) => state = state.copyWith(error: failure.message),
        (books) => state = state.copyWith(books: books),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _loadLoans() async {
    try {
      final repository = ref.read(loanRepositoryProvider);
      final result = await repository.getAllLoans();
      result.fold(
        (failure) => state = state.copyWith(error: failure.message),
        (loans) => state = state.copyWith(loans: loans),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _loadReservations() async {
    try {
      final repository = ref.read(reserveRepositoryProvider);
      final result = await repository.getReservedByMember(state.memberId);
      result.fold((failure) {
        // Reservations might be empty, don't treat as error
      }, (reservations) => state = state.copyWith(reservations: reservations));
    } catch (e) {
      // Don't fail completely for reservation errors
    }
    state = state.copyWith(isLoading: false);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _loadInitialData();
  }

  Future<bool> returnBook(String loanId) async {
    try {
      final repository = ref.read(loanRepositoryProvider);
      final result = await repository.returnBook(loanId);
      return result.fold((failure) => false, (message) {
        refresh();
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<bool> renewLoan(String loanId) async {
    try {
      final repository = ref.read(loanRepositoryProvider);
      final result = await repository.renewLoan(loanId);
      return result.fold((failure) => false, (loan) {
        refresh();
        return true;
      });
    } catch (e) {
      return false;
    }
  }
}
