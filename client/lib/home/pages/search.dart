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

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.currentCategory;
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(fetchAllBooksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Search")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: booksAsync.when(
          data: (books) {
            final authors = books.map((e) => e.author).toSet().toList();
            final categories = books.map((e) => e.category).toSet().toList();

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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    hintText: "Search a book",
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                DropdownButtonFormField(
                  initialValue: selectedAuthor,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text("All Authors")),
                    ...authors.map((author) {
                      return DropdownMenuItem(
                          value: author, child: Text(author));
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedAuthor = value;
                    });
                  },
                ),
                DropdownButtonFormField(
                  initialValue: selectedCategory,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text("All Categories"),
                    ),
                    ...categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                Expanded(
                  child: GridView.builder(
                    itemCount: filteredBooks.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 0.7,
                    ),
                    itemBuilder: (context, index) {
                      return BookCard(
                        book: filteredBooks[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BookView(book: filteredBooks[index]),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
          error: (err, stack) => Center(child: Text('Error: $err')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
