import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/book_view.dart';
import 'package:libraryapp/features/wishlist/viewmodels/wishlist_viewmodel.dart';
import 'package:libraryapp/features/wishlist/widgets/favorite_book_card.dart';
import 'package:libraryapp/features/wishlist/widgets/favorite_filter_chips.dart';
import 'package:libraryapp/features/wishlist/widgets/favorites_empty_state.dart';
import 'package:libraryapp/models/book.dart';

/// Wishlist page displaying user's favorite books.
class WishlistView extends ConsumerWidget {
  const WishlistView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistViewModelProvider);

    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: _buildAppBar(ref),
      body: Column(
        children: [
          const SizedBox(height: 16),
          FavoriteFilterChips(
            selectedFilter: wishlistState.selectedFilter,
            onFilterChanged: (filter) {
              ref.read(wishlistViewModelProvider.notifier).setFilter(filter);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: wishlistState.isLoading
                ? _buildLoading()
                : wishlistState.error != null
                ? _buildError(wishlistState.error!, ref)
                : _buildContent(context, ref, wishlistState),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(WidgetRef ref) {
    return AppBar(
      backgroundColor: Pallete.scaffoldBackground,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Favorites',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Show filter options
          },
          icon: Icon(Icons.filter_list, color: Pallete.textSecondary),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    WishlistState state,
  ) {
    if (state.isEmpty) {
      return FavoritesEmptyState(
        onBrowseBooks: () => Navigator.of(context).pop(),
      );
    }

    if (state.hasNoResults) {
      return _buildNoResultsState(ref, state.selectedFilter);
    }

    return RefreshIndicator(
      color: Pallete.primaryLight,
      backgroundColor: Pallete.cardBackground,
      onRefresh: () => ref.read(wishlistViewModelProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.filteredFavorites.length,
        itemBuilder: (context, index) {
          final book = state.filteredFavorites[index];
          return FavoriteBookCard(
            book: book,
            isFavorite: true,
            onTap: () => _navigateToBookView(context, book),
            onFavoriteToggle: () => _toggleFavorite(ref, book.id),
          );
        },
      ),
    );
  }

  Widget _buildNoResultsState(WidgetRef ref, String filter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Pallete.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No books match "$filter"',
            style: TextStyle(color: Pallete.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () =>
                ref.read(wishlistViewModelProvider.notifier).clearFilter(),
            child: const Text(
              'Clear filter',
              style: TextStyle(color: Pallete.primaryLight),
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

  Future<void> _toggleFavorite(WidgetRef ref, String bookId) async {
    await ref.read(wishlistViewModelProvider.notifier).removeFavorite(bookId);
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Pallete.primaryLight),
    );
  }

  Widget _buildError(String message, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Pallete.warning),
          const SizedBox(height: 16),
          const Text(
            'Failed to load favorites',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Pallete.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(wishlistViewModelProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              'Try Again',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Pallete.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
