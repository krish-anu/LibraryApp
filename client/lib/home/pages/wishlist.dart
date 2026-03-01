import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/auth/providers/asgardeo_direct_provider.dart';
import 'package:libraryapp/core/providers/current_user_notifier.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/book_view.dart';
import 'package:libraryapp/data/repository/favorites_repository.dart';
import 'package:libraryapp/home/widgets/wishlist/favorite_book_card.dart';
import 'package:libraryapp/home/widgets/wishlist/favorite_filter_chips.dart';
import 'package:libraryapp/home/widgets/wishlist/favorites_empty_state.dart';
import 'package:libraryapp/models/book.dart';

class Wishlist extends ConsumerStatefulWidget {
  const Wishlist({super.key});

  @override
  ConsumerState<Wishlist> createState() => _WishlistState();
}

class _WishlistState extends ConsumerState<Wishlist> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final memberId = _resolveMemberId();
    final favoritesAsync = memberId.isEmpty
        ? const AsyncValue<List<Book>>.data(<Book>[])
        : ref.watch(fetchFavoritesProvider(memberId));

    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: _buildAppBar(),
      body: memberId.isEmpty
          ? _buildErrorState(
              'Unable to identify the current member. Please login again.',
            )
          : Column(
              children: [
                const SizedBox(height: 16),
                FavoriteFilterChips(
                  selectedFilter: _selectedFilter,
                  onFilterChanged: (filter) {
                    setState(() => _selectedFilter = filter);
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: favoritesAsync.when(
                    data: (favorites) => _buildFavoritesList(favorites),
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: Pallete.primaryLight,
                      ),
                    ),
                    error: (err, stack) => _buildErrorState(err.toString()),
                  ),
                ),
              ],
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Pallete.scaffoldBackground,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Favorites',
        style: TextStyle(
          color: Pallete.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _showFilterOptions,
          icon: Icon(Icons.filter_list, color: Pallete.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFavoritesList(List<Book> favorites) {
    final filteredFavorites = _filterBooks(favorites);

    if (filteredFavorites.isEmpty) {
      if (favorites.isEmpty) {
        return FavoritesEmptyState(
          onBrowseBooks: () {
            // Navigate to home/search page
            Navigator.of(context).pop();
          },
        );
      }
      return _buildNoResultsState();
    }

    return RefreshIndicator(
      color: Pallete.primaryLight,
      backgroundColor: Pallete.cardBackground,
      onRefresh: _refreshFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredFavorites.length,
        itemBuilder: (context, index) {
          final book = filteredFavorites[index];
          return FavoriteBookCard(
            book: book,
            isFavorite: true,
            onTap: () => _navigateToBookView(book),
            onFavoriteToggle: () => _toggleFavorite(book),
          );
        },
      ),
    );
  }

  List<Book> _filterBooks(List<Book> books) {
    switch (_selectedFilter) {
      case 'Available Now':
        return books.where((book) => book.copiesOwned > 0).toList();
      case 'Fiction':
        return books
            .where(
              (book) =>
                  book.category.toLowerCase() == 'fiction' ||
                  book.category.toLowerCase() == 'science fiction' ||
                  book.category.toLowerCase() == 'fantasy',
            )
            .toList();
      case 'Non-Fiction':
        return books
            .where(
              (book) =>
                  book.category.toLowerCase() != 'fiction' &&
                  book.category.toLowerCase() != 'science fiction' &&
                  book.category.toLowerCase() != 'fantasy',
            )
            .toList();
      default:
        return books;
    }
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Pallete.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No books match "$_selectedFilter"',
            style: TextStyle(color: Pallete.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _selectedFilter = 'All'),
            child: const Text(
              'Clear filter',
              style: TextStyle(color: Pallete.primaryLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Pallete.warning),
            const SizedBox(height: 16),
            const Text(
              'Failed to load favorites',
              style: TextStyle(
                color: Pallete.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Pallete.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final memberId = _resolveMemberId();
                if (memberId.isNotEmpty) {
                  ref.refresh(fetchFavoritesProvider(memberId));
                }
              },
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
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Pallete.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort & Filter',
              style: TextStyle(
                color: Pallete.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ...[
              ('All', Icons.list),
              ('Available Now', Icons.check_circle),
              ('Fiction', Icons.auto_stories),
              ('Non-Fiction', Icons.school),
            ].map(
              (item) => ListTile(
                leading: Icon(item.$2, color: Pallete.primaryLight),
                title: Text(
                  item.$1,
                  style: TextStyle(
                    color: _selectedFilter == item.$1
                        ? Pallete.primaryLight
                        : Pallete.textPrimary,
                    fontWeight: _selectedFilter == item.$1
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: _selectedFilter == item.$1
                    ? Icon(Icons.check, color: Pallete.primaryLight)
                    : null,
                onTap: () {
                  setState(() => _selectedFilter = item.$1);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshFavorites() async {
    final memberId = _resolveMemberId();
    if (memberId.isEmpty) return;
    ref.invalidate(fetchFavoritesProvider(memberId));
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _navigateToBookView(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookView(book: book)),
    );
  }

  Future<void> _toggleFavorite(Book book) async {
    final memberId = _resolveMemberId();
    if (memberId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to identify the current member. Please login again.',
            ),
            backgroundColor: Pallete.warning,
          ),
        );
      }
      return;
    }

    try {
      final repo = ref.read(favoritesRepositoryProvider);
      final result = await repo.removeFavorite(memberId, book.id);

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to remove: ${failure.message}'),
                backgroundColor: Pallete.warning,
              ),
            );
          }
        },
        (_) {
          ref.invalidate(fetchFavoritesProvider(memberId));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Removed "${book.title}" from favorites'),
                backgroundColor: Pallete.cardBackground,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'UNDO',
                  textColor: Pallete.primaryLight,
                  onPressed: () async {
                    await repo.addFavorite(memberId, book.id);
                    ref.invalidate(fetchFavoritesProvider(memberId));
                  },
                ),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove: $e'),
            backgroundColor: Pallete.warning,
          ),
        );
      }
    }
  }

  String _resolveMemberId() {
    final authMemberId = ref.read(asgardeoDirectAuthProvider).user?.sub?.trim();
    if (authMemberId != null && authMemberId.isNotEmpty) {
      return authMemberId;
    }

    final currentUserId = ref.read(currentUserProvider)?.id.trim();
    if (currentUserId != null && currentUserId.isNotEmpty) {
      return currentUserId;
    }

    return '';
  }
}
