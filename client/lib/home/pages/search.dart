import 'package:flutter/material.dart';
import 'package:libraryapp/core/widgets/book_card.dart';
import 'package:libraryapp/core/widgets/book_view.dart';
import 'package:libraryapp/data/mock_books.dart';
import 'package:libraryapp/models/book.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController searchController = TextEditingController();
  String? selectedAuthor;
  String? selectedCategory;
  final List<Book> books = mockBooks;

  @override
  Widget build(BuildContext context) {
    final authors = mockBooks.map((e) => e.author).toSet().toList();
    final categories = mockBooks.map((e) => e.category).toSet().toList();

    final filteredBooks = books.where((b) {
      final query = searchController.text.toLowerCase().trim();

      final matchText =
          query.isEmpty ||
          b.title.toLowerCase().contains(query) ||
          b.author.toLowerCase().contains(query);

      final matchAuthor = selectedAuthor == null || b.author == selectedAuthor;
      final matchCategory =
          selectedCategory == null || b.category == selectedCategory;

      return matchText && matchAuthor && matchCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Search")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
              value: selectedAuthor,
              items: [
                const DropdownMenuItem(value: null, child: Text("All Authors")),
                ...authors.map((author) {
                  return DropdownMenuItem(value: author, child: Text(author));
                }),
              ],
              onChanged: (value) {
                setState(() {
                  selectedAuthor = value;
                });
              },
            ),
            DropdownButtonFormField(
              value: selectedCategory,
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
              child: ListView.builder(
                itemCount: filteredBooks.length,
                itemBuilder: (context, index) {
                  return BookCard(
                    book: filteredBooks[index],
                    onTap: () {
                      final originalIndex = mockBooks.indexOf(
                        filteredBooks[index],
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookView(id: originalIndex),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
