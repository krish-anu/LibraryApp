import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/book_card.dart';
import 'package:libraryapp/core/widgets/book_view.dart';
import 'package:libraryapp/models/book.dart';

/// A grid displaying filtered book search results.
class SearchResultsGrid extends StatelessWidget {
  final List<Book> books;

  const SearchResultsGrid({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        return BookCard(
          book: books[index],
          onTap: () => _navigateToBookView(context, books[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Pallete.textSecondary),
          const SizedBox(height: 16),
          Text(
            "No books found",
            style: TextStyle(color: Pallete.textSecondary, fontSize: 18),
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
}
