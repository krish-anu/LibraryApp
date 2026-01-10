import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/data/repository/book_repository.dart';
import 'package:libraryapp/home/widgets/search/filter_chip_button.dart';
import 'package:libraryapp/home/widgets/search/sort_dropdown.dart';
import 'package:libraryapp/home/widgets/search/search_text_field.dart';
import 'package:libraryapp/home/widgets/search/genre_grid.dart';
import 'package:libraryapp/home/widgets/search/search_results_grid.dart';
import 'package:libraryapp/models/book.dart';

/// Search page for browsing and filtering books.
class Search extends ConsumerStatefulWidget {
  final String? currentCategory;
  const Search({super.key, this.currentCategory});

  @override
  ConsumerState<Search> createState() => _SearchState();
}

class _SearchState extends ConsumerState<Search> {
  final TextEditingController searchController = TextEditingController();
  String? selectedAuthor;
  String? selectedCategory;
  String sortBy = 'Popular';
  bool showSearchResults = false;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.currentCategory;
    if (widget.currentCategory != null) {
      showSearchResults = true;
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(fetchAllBooksProvider);

    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: _buildAppBar(),
      body: booksAsync.when(
        data: (books) => _buildContent(books),
        error: (err, stack) => _buildError(err.toString()),
        loading: () => _buildLoading(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Pallete.scaffoldBackground,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: const Text(
        "Browse",
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () =>
              setState(() => showSearchResults = !showSearchResults),
        ),
      ],
    );
  }

  Widget _buildContent(List<Book> books) {
    final categories = books.map((e) => e.category).toSet().toList();
    final authors = books.map((e) => e.author).toSet().toList();
    final genres = _computeGenres(books);
    final filteredBooks = _filterAndSortBooks(books);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSearchResults)
          SearchTextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
          ),
        _buildFilterChipsRow(categories),
        if (showSearchResults) _buildAuthorFilterRow(authors),
        Expanded(
          child: showSearchResults
              ? SearchResultsGrid(books: filteredBooks)
              : GenreGrid(
                  genres: genres,
                  onGenreSelected: (name) => setState(() {
                    selectedCategory = name;
                    showSearchResults = true;
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChipsRow(List<String> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SortDropdown(
              sortBy: sortBy,
              onChanged: (value) => setState(() => sortBy = value!),
            ),
            const SizedBox(width: 8),
            FilterChipButton(
              label: "All Categories",
              isSelected: selectedCategory == null,
              onTap: () => setState(() {
                selectedCategory = null;
                showSearchResults = true;
              }),
            ),
            const SizedBox(width: 8),
            ...categories
                .take(3)
                .map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChipButton(
                      label: category,
                      isSelected: selectedCategory == category,
                      onTap: () => setState(() {
                        selectedCategory = category;
                        showSearchResults = true;
                      }),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorFilterRow(List<String> authors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChipButton(
              label: "All Authors",
              isSelected: selectedAuthor == null,
              onTap: () => setState(() => selectedAuthor = null),
            ),
            const SizedBox(width: 8),
            ...authors
                .take(5)
                .map(
                  (author) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChipButton(
                      label: author,
                      isSelected: selectedAuthor == author,
                      onTap: () => setState(() => selectedAuthor = author),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _computeGenres(List<Book> books) {
    final Map<String, Map<String, dynamic>> genreMap = {};
    for (final b in books) {
      final name = b.category;
      if (genreMap.containsKey(name)) {
        genreMap[name]!['count'] = (genreMap[name]!['count'] as int) + 1;
      } else {
        genreMap[name] = {
          'name': name,
          'count': 1,
          'image': b.image.isNotEmpty
              ? b.image
              : 'https://via.placeholder.com/400',
        };
      }
    }
    return genreMap.values.toList();
  }

  List<Book> _filterAndSortBooks(List<Book> books) {
    final query = searchController.text.toLowerCase().trim();

    final filtered = books.where((b) {
      final matchText =
          query.isEmpty ||
          b.title.toLowerCase().contains(query) ||
          b.author.toLowerCase().contains(query);
      final matchAuthor = selectedAuthor == null || b.author == selectedAuthor;
      final matchCategory =
          selectedCategory == null || b.category == selectedCategory;
      return matchText && matchAuthor && matchCategory;
    }).toList();

    switch (sortBy) {
      case 'Popular':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Newest':
        filtered.sort((a, b) => b.publicationYear.compareTo(a.publicationYear));
        break;
      case 'Title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    return filtered;
  }

  Widget _buildError(String message) {
    return Center(
      child: Text(
        'Error: $message',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Pallete.primaryLight),
    );
  }
}
