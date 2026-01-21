import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/book_view/book_view_app_bar.dart';
import 'package:libraryapp/core/widgets/book_view/book_cover_section.dart';
import 'package:libraryapp/core/widgets/book_view/book_info_section.dart';
import 'package:libraryapp/core/widgets/book_view/category_chips.dart';
// import 'package:libraryapp/core/widgets/book_view/action_buttons.dart';
import 'package:libraryapp/core/widgets/book_view/summary_section.dart';
import 'package:libraryapp/core/widgets/book_view/borrow_confirmation_sheet.dart';
import 'package:libraryapp/core/providers/favorites_notifier.dart';
import 'package:libraryapp/models/book.dart';

/// Displays detailed information about a book.
class BookView extends ConsumerStatefulWidget {
  final Book book;

  const BookView({super.key, required this.book});

  @override
  ConsumerState<BookView> createState() => _BookViewState();
}

class _BookViewState extends ConsumerState<BookView> {
  bool _isLoadingFavorite = false;

  Future<void> _toggleFavorite() async {
    setState(() => _isLoadingFavorite = true);
    try {
      final favoritesNotifier = ref.read(favoritesProvider.notifier);
      final success = await favoritesNotifier.toggleFavorite(widget.book);

      if (mounted) {
        setState(() => _isLoadingFavorite = false);

        if (success) {
          final isFavorite = ref
              .read(favoritesProvider)
              .isFavorite(widget.book.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFavorite
                    ? 'Added "${widget.book.title}" to favorites'
                    : 'Removed "${widget.book.title}" from favorites',
              ),
              backgroundColor: Pallete.cardBackground,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to update favorites'),
              backgroundColor: Pallete.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite: $e'),
            backgroundColor: Pallete.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the global favorites state for reactive updates
    final favoritesState = ref.watch(favoritesProvider);
    final isFavorite = favoritesState.isFavorite(widget.book.id);
    final isAvailable = widget.book.copiesOwned > 0;

    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: BookViewAppBar(
        title: widget.book.title,
        isFavorite: isFavorite,
        isLoadingFavorite: _isLoadingFavorite || favoritesState.isLoading,
        onFavoritePressed: _toggleFavorite,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCoverSection(
              imageUrl: widget.book.image,
              isAvailable: isAvailable,
            ),
            BookInfoSection(
              title: widget.book.title,
              author: widget.book.author,
              rating: widget.book.rating,
              ratingCount: widget.book.ratingCount,
              pages: widget.book.pages,
              language: widget.book.language,
            ),
            const SizedBox(height: 20),
            CategoryChips(category: widget.book.category),
            const SizedBox(height: 20),
            // const ActionButtons(),
            const SizedBox(height: 24),
            SummarySection(
              description: widget.book.description,
              isAvailable: isAvailable,
              onBorrowPressed: () => _showBorrowConfirmation(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showBorrowConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BorrowConfirmationSheet(book: widget.book),
    );
  }
}
