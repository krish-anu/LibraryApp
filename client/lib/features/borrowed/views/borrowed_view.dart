// ignore_for_file: deprecated_member_use, strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/book_view.dart';
import 'package:libraryapp/core/widgets/common/common_app_bar.dart';
import 'package:libraryapp/features/borrowed/viewmodels/borrowed_viewmodel.dart';
import 'package:libraryapp/features/borrowed/widgets/borrowed_book_card.dart';
import 'package:libraryapp/features/borrowed/widgets/borrowed_stats.dart';
import 'package:libraryapp/features/borrowed/widgets/borrowed_empty_state.dart';
import 'package:libraryapp/features/borrowed/widgets/reserved_book_card.dart';

/// Page displaying user's borrowed books with loan information.
class BorrowedView extends ConsumerStatefulWidget {
  const BorrowedView({super.key});

  @override
  ConsumerState<BorrowedView> createState() => _BorrowedViewState();
}

class _BorrowedViewState extends ConsumerState<BorrowedView>
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
    final borrowedState = ref.watch(borrowedViewModelProvider);

    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: CommonAppBar(
        title: 'My Books',
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Pallete.iconColor),
            onPressed: () =>
                ref.read(borrowedViewModelProvider.notifier).refresh(),
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
      body: borrowedState.isLoading
          ? _buildLoading()
          : borrowedState.error != null
          ? _buildError(borrowedState.error!)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBorrowedTab(borrowedState),
                _buildReservedTab(borrowedState),
              ],
            ),
    );
  }

  Widget _buildBorrowedTab(BorrowedState state) {
    if (state.borrowedItems.isEmpty) {
      return BorrowedEmptyState(onBrowseBooks: () => Navigator.pop(context));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(borrowedViewModelProvider.notifier).refresh(),
      color: Pallete.primaryLight,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: BorrowedStats(
              totalBorrowed: state.totalBorrowed,
              dueSoon: state.dueSoonCount,
              overdue: state.overdueCount,
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
                final item = state.borrowedItems[index];
                return BorrowedBookCard(
                  book: item.book,
                  dueDate: item.dueDate,
                  onTap: () => _navigateToBookView(item.book),
                  onRenew: () => _renewLoan(item.loan.id),
                  onReturn: () => _returnBook(item.loan.id),
                );
              }, childCount: state.borrowedItems.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservedTab(BorrowedState state) {
    if (state.reservedItems.isEmpty) {
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
              style: TextStyle(color: Pallete.textSecondary, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(borrowedViewModelProvider.notifier).refresh(),
      color: Pallete.primaryLight,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.reservedItems.length,
        itemBuilder: (context, index) {
          final item = state.reservedItems[index];
          return ReservedBookCard(
            book: item.book,
            reservationDate: item.reservation.reservationDate,
            status: item.reservation.status,
            onTap: () => _navigateToBookView(item.book),
          );
        },
      ),
    );
  }

  void _navigateToBookView(book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookView(book: book)),
    );
  }

  Future<void> _renewLoan(String loanId) async {
    final success = await ref
        .read(borrowedViewModelProvider.notifier)
        .renewLoan(loanId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Loan renewed successfully' : 'Failed to renew loan',
          ),
          backgroundColor: success ? Pallete.success : Pallete.error,
        ),
      );
    }
  }

  Future<void> _returnBook(String loanId) async {
    final success = await ref
        .read(borrowedViewModelProvider.notifier)
        .returnBook(loanId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Book returned successfully' : 'Failed to return book',
          ),
          backgroundColor: success ? Pallete.success : Pallete.error,
        ),
      );
    }
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Pallete.primaryLight),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Text(message, style: const TextStyle(color: Pallete.textPrimary)),
    );
  }
}
