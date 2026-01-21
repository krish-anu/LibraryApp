import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:libraryapp/models/loan.dart';
import 'package:libraryapp/models/reserve.dart';
import 'package:libraryapp/data/repository/loan_repository.dart';
import 'package:libraryapp/data/repository/reserve_repository.dart';

part 'loans_notifier.g.dart';

/// Global loans/reservations state that can be shared across all viewmodels
class LoansState {
  final List<Loan> loans;
  final List<Reserve> reservations;
  final Set<String> borrowedBookIds;
  final Set<String> reservedBookIds;
  final bool isLoading;
  final String? error;
  final String memberId;

  const LoansState({
    this.loans = const [],
    this.reservations = const [],
    this.borrowedBookIds = const {},
    this.reservedBookIds = const {},
    this.isLoading = false,
    this.error,
    this.memberId = 'm1',
  });

  LoansState copyWith({
    List<Loan>? loans,
    List<Reserve>? reservations,
    Set<String>? borrowedBookIds,
    Set<String>? reservedBookIds,
    bool? isLoading,
    String? error,
    String? memberId,
  }) {
    return LoansState(
      loans: loans ?? this.loans,
      reservations: reservations ?? this.reservations,
      borrowedBookIds: borrowedBookIds ?? this.borrowedBookIds,
      reservedBookIds: reservedBookIds ?? this.reservedBookIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      memberId: memberId ?? this.memberId,
    );
  }

  bool isBorrowed(String bookId) => borrowedBookIds.contains(bookId);
  bool isReserved(String bookId) => reservedBookIds.contains(bookId);
}

/// Global loans notifier - single source of truth for loans and reservations
@Riverpod(keepAlive: true)
class LoansNotifier extends _$LoansNotifier {
  @override
  LoansState build() {
    Future.microtask(() => loadLoansAndReservations());
    return const LoansState(isLoading: true);
  }

  Future<void> loadLoansAndReservations() async {
    if (!ref.mounted) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final loanRepository = ref.read(loanRepositoryProvider);
      final reserveRepository = ref.read(reserveRepositoryProvider);
      final memberId = state.memberId;

      final results = await Future.wait([
        loanRepository.getAllLoans(),
        reserveRepository.getReservedByMember(memberId),
      ]);

      if (!ref.mounted) return;

      final loansResult = results[0];
      final reservationsResult = results[1];

      List<Loan> loans = [];
      List<Reserve> reservations = [];

      loansResult.fold(
        (failure) => state = state.copyWith(error: failure.message),
        (l) => loans = l as List<Loan>,
      );

      reservationsResult.fold(
        (failure) {}, // Reservations may be empty, don't treat as error
        (r) => reservations = r as List<Reserve>,
      );

      if (!ref.mounted) return;
      state = state.copyWith(
        loans: loans,
        reservations: reservations,
        borrowedBookIds: loans.map((l) => l.bookId).toSet(),
        reservedBookIds: reservations.map((r) => r.bookId).toSet(),
        isLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> borrowBook(String bookId, String memberId) async {
    try {
      final repository = ref.read(loanRepositoryProvider);
      final result = await repository.borrowBook(bookId, memberId);

      return result.fold((failure) => false, (loan) {
        if (!ref.mounted) return true;
        // Update local state
        final updatedLoans = [...state.loans, loan];
        final updatedIds = {...state.borrowedBookIds, bookId};
        state = state.copyWith(
          loans: updatedLoans,
          borrowedBookIds: updatedIds,
        );
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<bool> returnBook(String loanId) async {
    try {
      final repository = ref.read(loanRepositoryProvider);
      final result = await repository.returnBook(loanId);

      return result.fold((failure) => false, (message) {
        if (!ref.mounted) return true;
        // Find and remove the loan
        final loan = state.loans.firstWhere(
          (l) => l.id == loanId,
          orElse: () => state.loans.first,
        );
        final updatedLoans = state.loans.where((l) => l.id != loanId).toList();
        final updatedIds = state.borrowedBookIds
            .where((id) => id != loan.bookId)
            .toSet();
        state = state.copyWith(
          loans: updatedLoans,
          borrowedBookIds: updatedIds,
        );
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

      return result.fold((failure) => false, (updatedLoan) {
        if (!ref.mounted) return true;
        // Update the loan in state
        final updatedLoans = state.loans
            .map((l) => l.id == loanId ? updatedLoan : l)
            .toList();
        state = state.copyWith(loans: updatedLoans);
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<bool> reserveBook(Reserve reserve) async {
    try {
      final repository = ref.read(reserveRepositoryProvider);
      final result = await repository.addReserve(reserve);

      return result.fold((failure) => false, (newReserve) {
        if (!ref.mounted) return true;
        // Update local state
        final updatedReservations = [...state.reservations, newReserve];
        final updatedIds = {...state.reservedBookIds, reserve.bookId};
        state = state.copyWith(
          reservations: updatedReservations,
          reservedBookIds: updatedIds,
        );
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelReservation(String reserveId) async {
    // Cancel reservation by removing from local state
    // (API for delete may not exist, so we just update local state)
    if (!ref.mounted) return false;
    try {
      final reserve = state.reservations.firstWhere(
        (r) => r.id == reserveId,
        orElse: () => state.reservations.first,
      );
      final updatedReservations = state.reservations
          .where((r) => r.id != reserveId)
          .toList();
      final updatedIds = state.reservedBookIds
          .where((id) => id != reserve.bookId)
          .toSet();
      state = state.copyWith(
        reservations: updatedReservations,
        reservedBookIds: updatedIds,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  void setMemberId(String memberId) {
    if (state.memberId != memberId) {
      state = state.copyWith(memberId: memberId);
      loadLoansAndReservations();
    }
  }
}
