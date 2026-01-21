import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/book_view/book_view.dart';
import 'package:libraryapp/features/book_details/viewmodels/book_details_viewmodel.dart';
import 'package:libraryapp/models/book.dart';

/// Book details view using MVVM pattern.
class BookDetailsView extends ConsumerWidget {
  final Book book;

  const BookDetailsView({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookDetailsViewModelProvider(book));
    final viewModel = ref.read(bookDetailsViewModelProvider(book).notifier);
    final currentBook = state.book;

    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: BookViewAppBar(
        title: 'Book Details',
        isFavorite: state.isFavorite,
        isLoadingFavorite: state.isLoadingFavorite,
        onFavoritePressed: () => viewModel.toggleFavorite(),
      ),
      body: state.isLoadingFavorite && state.error != null
          ? _buildErrorState(context, viewModel, state.error!)
          : SingleChildScrollView(
              child: Column(
                children: [
                  BookCoverSection(
                    imageUrl: currentBook.image,
                    isAvailable: currentBook.copiesOwned > 0,
                  ),
                  BookInfoSection(
                    title: currentBook.title,
                    author: currentBook.author,
                    rating: currentBook.rating,
                    ratingCount: currentBook.ratingCount,
                    pages: currentBook.pages,
                    language: currentBook.language,
                  ),
                  const SizedBox(height: 16),
                  CategoryChips(category: currentBook.category),
                  const SizedBox(height: 16),
                  ActionButtons(
                    onAddToList: () => viewModel.toggleFavorite(),
                    onWriteReview: () =>
                        _showComingSoon(context, 'Write Review'),
                  ),
                  const SizedBox(height: 24),
                  SummarySection(
                    description: currentBook.description,
                    isAvailable: currentBook.copiesOwned > 0,
                    onBorrowPressed: () =>
                        _showBorrowSheet(context, currentBook),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    BookDetailsViewModel viewModel,
    String error,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Pallete.textSecondary, size: 64),
          const SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(color: Pallete.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => viewModel.clearError(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Pallete.primaryLight,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showBorrowSheet(BuildContext context, Book book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BorrowConfirmationSheet(book: book),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: Pallete.primaryLight,
      ),
    );
  }
}
