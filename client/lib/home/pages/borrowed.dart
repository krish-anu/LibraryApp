import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/book_view.dart';
import 'package:libraryapp/data/repository/book_repository.dart';
import 'package:libraryapp/data/repository/loan_repository.dart';
import 'package:libraryapp/home/widgets/borrowed/borrowed_book_card.dart';
import 'package:libraryapp/home/widgets/borrowed/borrowed_stats.dart';
import 'package:libraryapp/home/widgets/borrowed/borrowed_empty_state.dart';
import 'package:libraryapp/models/book.dart';
import 'package:libraryapp/models/loan.dart';

/// Page displaying user's borrowed books with loan information.
class Borrowed extends ConsumerStatefulWidget {
  const Borrowed({super.key});

  @override
  ConsumerState<Borrowed> createState() => _BorrowedState();
}

class _BorrowedState extends ConsumerState<Borrowed> {
  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(fetchAllLoansProvider);
    final booksAsync = ref.watch(fetchAllBooksProvider);

    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: _buildAppBar(context),
      body: loansAsync.when(
        data: (loans) => booksAsync.when(
          data: (books) => _buildContent(context, loans, books),
          error: (err, _) => _buildError('Error loading books: $err'),
          loading: () => _buildLoading(),
        ),
        error: (err, _) => _buildError('Error loading loans: $err'),
        loading: () => _buildLoading(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Pallete.scaffoldBackground,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "My Books",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            ref.invalidate(fetchAllLoansProvider);
          },
        ),
      ],
    );
  }

  Widget _buildContent(
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
                    color: Colors.white,
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
        title: const Text('Renew Book', style: TextStyle(color: Colors.white)),
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
        title: const Text('Return Book', style: TextStyle(color: Colors.white)),
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
            style: const TextStyle(color: Colors.white),
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
