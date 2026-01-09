import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/book_view/book_view_app_bar.dart';
import 'package:libraryapp/core/widgets/book_view/book_cover_section.dart';
import 'package:libraryapp/core/widgets/book_view/book_info_section.dart';
import 'package:libraryapp/core/widgets/book_view/category_chips.dart';
import 'package:libraryapp/core/widgets/book_view/action_buttons.dart';
import 'package:libraryapp/core/widgets/book_view/summary_section.dart';
import 'package:libraryapp/core/widgets/book_view/borrow_confirmation_sheet.dart';
import 'package:libraryapp/data/repository/favorites_repository.dart';
import 'package:libraryapp/models/book.dart';

/// Displays detailed information about a book.
class BookView extends ConsumerStatefulWidget {
  final Book book;

  const BookView({super.key, required this.book});

  @override
  ConsumerState<BookView> createState() => _BookViewState();
}

class _BookViewState extends ConsumerState<BookView> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final repo = ref.read(favoritesRepositoryProvider);
      final result = await repo.checkFavorite('m1', widget.book.id);
      if (mounted) {
        result.fold(
          (failure) => setState(() => _isLoadingFavorite = false),
          (isFav) => setState(() {
            _isFavorite = isFav;
            _isLoadingFavorite = false;
          }),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isLoadingFavorite = true);
    try {
      final repo = ref.read(favoritesRepositoryProvider);
      final result = await repo.toggleFavorite(
        'm1',
        widget.book.id,
        _isFavorite,
      );
      if (mounted) {
        result.fold(
          (failure) {
            setState(() => _isLoadingFavorite = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update favorite: ${failure.message}'),
                backgroundColor: Pallete.warning,
              ),
            );
          },
          (newStatus) {
            setState(() {
              _isFavorite = newStatus;
              _isLoadingFavorite = false;
            });
            // Invalidate the favorites list so it refreshes
            ref.invalidate(fetchFavoritesProvider('m1'));
            ref.invalidate(fetchFavoriteIdsProvider('m1'));

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  newStatus
                      ? 'Added "${widget.book.title}" to favorites'
                      : 'Removed "${widget.book.title}" from favorites',
                ),
                backgroundColor: Pallete.cardBackground,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
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
    final isAvailable = widget.book.copiesOwned > 0;

    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: BookViewAppBar(
        title: widget.book.title,
        isFavorite: _isFavorite,
        isLoadingFavorite: _isLoadingFavorite,
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
            ),
            const SizedBox(height: 20),
            CategoryChips(category: widget.book.category),
            const SizedBox(height: 20),
            const ActionButtons(),
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
