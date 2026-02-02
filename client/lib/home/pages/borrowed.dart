import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/book_view.dart';
import 'package:libraryapp/data/repository/book_repository.dart';
import 'package:libraryapp/data/repository/loan_repository.dart';
import 'package:libraryapp/data/repository/reserve_repository.dart';
import 'package:libraryapp/home/widgets/borrowed/borrowed_book_card.dart';
import 'package:libraryapp/home/widgets/borrowed/borrowed_stats.dart';
import 'package:libraryapp/home/widgets/borrowed/borrowed_empty_state.dart';
import 'package:libraryapp/home/widgets/borrowed/reserved_book_card.dart';
import 'package:libraryapp/core/widgets/common/common_app_bar.dart';
import 'package:libraryapp/models/book.dart';
import 'package:libraryapp/models/loan.dart';
import 'package:libraryapp/models/reserve.dart';

/// Page displaying user's borrowed books with loan information.
class Borrowed extends ConsumerStatefulWidget {
  const Borrowed({super.key});

  @override
  ConsumerState<Borrowed> createState() => _BorrowedState();
}

class _BorrowedState extends ConsumerState<Borrowed>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: CommonAppBar(
        title: 'My Books',
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Pallete.iconColor),
            onPressed: () {
              ref.invalidate(fetchAllLoansProvider);
              ref.invalidate(fetchReservationsByMemberProvider('m1'));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Pallete.primaryLight,
          labelColor: Pallete.primaryLight,
          unselectedLabelColor: Pallete.textSecondary,
          tabs: const [
            Tab(text: 'Borrowed'),
            Tab(text: 'Reserved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildBorrowedTab(), _buildReservedTab()],
      ),
    );
  }

  Widget _buildBorrowedTab() {
    final loansAsync = ref.watch(fetchAllLoansProvider);
    final booksAsync = ref.watch(fetchAllBooksProvider);

    return loansAsync.when(
      data: (loans) => booksAsync.when(
        data: (books) => _buildBorrowedContent(context, loans, books),
        error: (err, _) => _buildError('Error loading books: $err'),
        loading: () => _buildLoading(),
      ),
      error: (err, _) => _buildError('Error loading loans: $err'),
      loading: () => _buildLoading(),
    );
  }

  Widget _buildReservedTab() {
    final reservationsAsync = ref.watch(
      fetchReservationsByMemberProvider('m1'),
    );
    final booksAsync = ref.watch(fetchAllBooksProvider);

    return reservationsAsync.when(
      data: (reservations) => booksAsync.when(
        data: (books) => _buildReservedContent(context, reservations, books),
        error: (err, _) => _buildError('Error loading books: $err'),
        loading: () => _buildLoading(),
      ),
      error: (err, _) => _buildError('Error loading reservations: $err'),
      loading: () => _buildLoading(),
    );
  }

  Widget _buildBorrowedContent(
    BuildContext context,
    List<Loan> loans,
    List<Book> books,
  ) {
    if (loans.isEmpty) {
      return BorrowedEmptyState(onBrowseBooks: () => Navigator.pop(context));
    }

    // Calculate stats
    final now = DateTime.now();
    int dueSoon = 0;
    int overdue = 0;

    final borrowedItems = loans.map((loan) {
      final book = books.firstWhere(
        (b) => b.id == loan.bookId,
        orElse: () => books.first,
      );
      // Use returnedDate as the due date (it's the expected return date)
      final dueDate = loan.returnedDate;
      final remainingDays = dueDate.difference(now).inDays;

      if (remainingDays < 0) {
        overdue++;
      } else if (remainingDays <= 3) {
        dueSoon++;
      }

      return _BorrowedItem(book: book, loan: loan, dueDate: dueDate);
    }).toList();

    // Sort: overdue first, then due soon, then by due date
    borrowedItems.sort((a, b) {
      final aDays = a.dueDate.difference(now).inDays;
      final bDays = b.dueDate.difference(now).inDays;

      if (aDays < 0 && bDays >= 0) return -1;
      if (bDays < 0 && aDays >= 0) return 1;
      return a.dueDate.compareTo(b.dueDate);
    });

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: BorrowedStats(
            totalBorrowed: loans.length,
            dueSoon: dueSoon,
            overdue: overdue,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Currently Borrowed',
                  style: TextStyle(
                    color: Pallete.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Pallete.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sort,
                        size: 14,
                        color: Pallete.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due Date',
                        style: TextStyle(
                          color: Pallete.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = borrowedItems[index];
              return BorrowedBookCard(
                book: item.book,
                dueDate: item.dueDate,
                onTap: () => _navigateToBookView(context, item.book),
                onRenew: () => _showRenewDialog(context, item),
                onReturn: () => _showReturnDialog(context, item),
              );
            }, childCount: borrowedItems.length),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildReservedContent(
    BuildContext context,
    List<Reserve> reservations,
    List<Book> books,
  ) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: Pallete.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Reserved Books',
              style: TextStyle(
                color: Pallete.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Books you reserve will appear here',
              style: TextStyle(
                color: Pallete.textSecondary.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        final reservation = reservations[index];
        final book = books.firstWhere(
          (b) => b.id == reservation.bookId,
          orElse: () => books.first,
        );
        return ReservedBookCard(
          book: book,
          reservationDate: reservation.reservationDate,
          status: reservation.status,
          onTap: () => _navigateToBookView(context, book),
          onCancel: () => _showCancelReservationDialog(context, reservation),
        );
      },
    );
  }

  void _showCancelReservationDialog(BuildContext context, Reserve reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Pallete.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Reservation',
          style: TextStyle(color: Pallete.textPrimary),
        ),
        content: Text(
          'Are you sure you want to cancel this reservation?',
          style: TextStyle(color: Pallete.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep', style: TextStyle(color: Pallete.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reservation cancelled'),
                  backgroundColor: Pallete.primaryLight,
                ),
              );
              ref.invalidate(fetchReservationsByMemberProvider('m1'));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Pallete.error),
            child: const Text(
              'Cancel Reservation',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToBookView(BuildContext context, Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookView(book: book)),
    );
  }

  void _showRenewDialog(BuildContext context, _BorrowedItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Pallete.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Renew Book', style: TextStyle(color: Pallete.textPrimary)),
        content: Text(
          'Would you like to renew "${item.book.title}" for another 14 days?',
          style: TextStyle(color: Pallete.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Pallete.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _renewBook(item.loan.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Pallete.primaryLight,
            ),
            child: const Text('Renew', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReturnDialog(BuildContext context, _BorrowedItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Pallete.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Return Book', style: TextStyle(color: Pallete.textPrimary)),
        content: Text(
          'Are you sure you want to return "${item.book.title}"?',
          style: TextStyle(color: Pallete.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Pallete.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _returnBook(item.loan.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Pallete.primaryLight,
            ),
            child: const Text('Return', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _renewBook(String loanId) async {
    final repository = ref.read(loanRepositoryProvider);
    final result = await repository.renewLoan(loanId);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to renew: ${failure.message}'),
            backgroundColor: Pallete.error,
          ),
        );
      },
      (loan) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book renewed successfully!'),
            backgroundColor: Pallete.primaryLight,
          ),
        );
        // Refresh the loans list
        ref.invalidate(fetchAllLoansProvider);
      },
    );
  }

  Future<void> _returnBook(String loanId) async {
    final repository = ref.read(loanRepositoryProvider);
    final result = await repository.returnBook(loanId);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to return: ${failure.message}'),
            backgroundColor: Pallete.error,
          ),
        );
      },
      (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book returned successfully!'),
            backgroundColor: Pallete.primaryLight,
          ),
        );
        // Refresh the loans and books list
        ref.invalidate(fetchAllLoansProvider);
        ref.invalidate(fetchAllBooksProvider);
      },
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Pallete.error),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Pallete.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(fetchAllLoansProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Pallete.primaryLight,
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Pallete.primaryLight),
    );
  }
}

/// Helper class to store borrowed item data.
class _BorrowedItem {
  final Book book;
  final Loan loan;
  final DateTime dueDate;

  _BorrowedItem({
    required this.book,
    required this.loan,
    required this.dueDate,
  });
}
