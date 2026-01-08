import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/widgets/book_card.dart';
import 'package:libraryapp/core/widgets/book_view.dart';
import 'package:libraryapp/data/repository/book_repository.dart';

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
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(fetchAllBooksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1F0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1F0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Browse",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                showSearchResults = !showSearchResults;
              });
            },
          ),
        ],
      ),
      body: booksAsync.when(
        data: (books) {
          final categories = books.map((e) => e.category).toSet().toList();
          final authors = books.map((e) => e.author).toSet().toList();

          // Compute genres from fetched books: name, count and a representative image
          final Map<String, Map<String, dynamic>> genreMap = {};
          for (final b in books) {
            final name = b.category;
            if (genreMap.containsKey(name)) {
              genreMap[name]!['count'] =
                  (genreMap[name]!['count'] as int) + 1;
            } else {
              genreMap[name] = {
                'name': name,
                'count': 1,
                'image': (b.image.isNotEmpty)
                    ? b.image
                    : 'https://via.placeholder.com/400',
              };
            }
          }
          final genres = genreMap.values.toList();

          final filteredBooks = books.where((b) {
            final query = searchController.text.toLowerCase().trim();

            final matchText =
                query.isEmpty ||
                b.title.toLowerCase().contains(query) ||
                b.author.toLowerCase().contains(query);

            final matchAuthor =
                selectedAuthor == null || b.author == selectedAuthor;
            final matchCategory =
                selectedCategory == null || b.category == selectedCategory;

            return matchText && matchAuthor && matchCategory;
          }).toList();

          // Sort books
          if (sortBy == 'Popular') {
            filteredBooks.sort((a, b) => b.rating.compareTo(a.rating));
          } else if (sortBy == 'Newest') {
            filteredBooks.sort(
              (a, b) => b.publicationYear.compareTo(a.publicationYear),
            );
          } else if (sortBy == 'Title') {
            filteredBooks.sort((a, b) => a.title.compareTo(b.title));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search field (shown when search is active)
              if (showSearchResults)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) => setState(() {}),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF142814),
                      hintText: "Search books...",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              // Filter Chips Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Sort By Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF142814),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButton<String>(
                          value: sortBy,
                          dropdownColor: const Color(0xFF1B3D1B),
                          underline: const SizedBox(),
                          isDense: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 18,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          items: ['Popular', 'Newest', 'Title'].map((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text('Sort by: $value'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              sortBy = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // All Categories Chip
                      _buildFilterChip(
                        "All Categories",
                        selectedCategory == null,
                        () => setState(() {
                          selectedCategory = null;
                          showSearchResults = true;
                        }),
                      ),
                      const SizedBox(width: 8),
                      // Category Chips
                      ...categories
                          .take(3)
                          .map(
                            (category) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildFilterChip(
                                category,
                                selectedCategory == category,
                                () => setState(() {
                                  selectedCategory = category;
                                  showSearchResults = true;
                                }),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              // Author Filter (shown when search results are visible)
              if (showSearchResults)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          "All Authors",
                          selectedAuthor == null,
                          () => setState(() => selectedAuthor = null),
                        ),
                        const SizedBox(width: 8),
                        ...authors
                            .take(5)
                            .map(
                              (author) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildFilterChip(
                                  author,
                                  selectedAuthor == author,
                                  () => setState(() => selectedAuthor = author),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              // Main Content
              Expanded(
                child: showSearchResults
                    ? _buildSearchResults(filteredBooks)
                    : _buildGenreGrid(genres),
              ),
            ],
          );
        },
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFF142814),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFF2D4D2D)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildGenreGrid(List<Map<String, dynamic>> genres) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Genres Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Top Genres",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  "View All",
                  style: TextStyle(color: Color(0xFF4CAF50)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Genre Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: genres.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final genre = genres[index];
              return _buildGenreCard(
                genre['name'],
                genre['count'],
                genre['image'],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGenreCard(String name, int count, String imageUrl) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = name;
          showSearchResults = true;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              // ignore: deprecated_member_use
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  // ignore: deprecated_member_use
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$count books",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
            // Green circle icon
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List filteredBooks) {
    if (filteredBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              "No books found",
              style: TextStyle(color: Colors.grey[400], fontSize: 18),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredBooks.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        return BookCard(
          book: filteredBooks[index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookView(book: filteredBooks[index]),
              ),
            );
          },
        );
      },
    );
  }
}
