import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/common/common_app_bar.dart';
import 'package:libraryapp/core/widgets/BottomNavigator/bottom_nav_provider.dart';
import 'package:libraryapp/features/search/viewmodels/search_viewmodel.dart';
import 'package:libraryapp/features/search/widgets/filter_chip_button.dart';
import 'package:libraryapp/features/search/widgets/sort_dropdown.dart';
import 'package:libraryapp/features/search/widgets/search_text_field.dart';
import 'package:libraryapp/features/search/widgets/genre_grid.dart';
import 'package:libraryapp/features/search/widgets/search_results_grid.dart';

/// Search page for browsing and filtering books.
class SearchView extends ConsumerStatefulWidget {
  final String? currentCategory;
  const SearchView({super.key, this.currentCategory});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _didAutoFocusForCurrentTabVisit = false;

  @override
  void dispose() {
    _searchFocusNode.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSearchTabActive = ref.watch(bottomNavIndexProvider) == 1;
    _handleSearchTabActivation(isSearchTabActive);

    final searchState = ref.watch(
      searchViewModelProvider(initialCategory: widget.currentCategory),
    );

    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: CommonAppBar(
        title: 'Browse',
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Pallete.iconColor),
            onPressed: () {
              ref
                  .read(
                    searchViewModelProvider(
                      initialCategory: widget.currentCategory,
                    ).notifier,
                  )
                  .toggleSearchResults();
            },
          ),
        ],
      ),
      body: searchState.isLoading
          ? _buildLoading()
          : searchState.error != null
          ? _buildError(searchState.error!)
          : _buildContent(searchState),
    );
  }

  Widget _buildContent(SearchState state) {
    final viewModel = ref.read(
      searchViewModelProvider(initialCategory: widget.currentCategory).notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.showSearchResults)
          SearchTextField(
            controller: searchController,
            onChanged: (value) => viewModel.setSearchQuery(value),
            focusNode: _searchFocusNode,
          ),
        _buildFilterChipsRow(state, viewModel),
        if (state.showSearchResults) _buildAuthorFilterRow(state, viewModel),
        Expanded(
          child: state.showSearchResults
              ? SearchResultsGrid(books: state.filteredBooks)
              : GenreGrid(
                  genres: state.genres,
                  onGenreSelected: (name) => viewModel.setCategory(name),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChipsRow(SearchState state, SearchViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SortDropdown(
              sortBy: state.sortBy,
              onChanged: (value) => viewModel.setSortBy(value!),
            ),
            const SizedBox(width: 8),
            FilterChipButton(
              label: "All Categories",
              isSelected: state.selectedCategory == null,
              onTap: () => viewModel.setCategory(null),
            ),
            const SizedBox(width: 8),
            ...state.categories
                .take(3)
                .map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChipButton(
                      label: category,
                      isSelected: state.selectedCategory == category,
                      onTap: () => viewModel.setCategory(category),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorFilterRow(SearchState state, SearchViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChipButton(
              label: "All Authors",
              isSelected: state.selectedAuthor == null,
              onTap: () => viewModel.setAuthor(null),
            ),
            const SizedBox(width: 8),
            ...state.authors
                .take(5)
                .map(
                  (author) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChipButton(
                      label: author,
                      isSelected: state.selectedAuthor == author,
                      onTap: () => viewModel.setAuthor(author),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Pallete.primaryLight),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Pallete.textPrimary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(
                    searchViewModelProvider(
                      initialCategory: widget.currentCategory,
                    ).notifier,
                  )
                  .refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSearchTabActivation(bool isSearchTabActive) {
    if (!isSearchTabActive) {
      _didAutoFocusForCurrentTabVisit = false;
      if (_searchFocusNode.hasFocus) {
        _searchFocusNode.unfocus();
      }
      return;
    }

    if (_didAutoFocusForCurrentTabVisit) {
      return;
    }

    _didAutoFocusForCurrentTabVisit = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final provider = searchViewModelProvider(
        initialCategory: widget.currentCategory,
      );
      final searchState = ref.read(provider);
      if (searchState.error != null) {
        ref.read(provider.notifier).refresh();
        return;
      }
      if (!searchState.showSearchResults) {
        ref.read(provider.notifier).openSearch();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _searchFocusNode.requestFocus();
      });
    });
  }
}
