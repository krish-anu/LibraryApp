import 'package:flutter/material.dart';
import 'package:libraryapp/models/book.dart';
import 'book_card.dart';

class BookSection extends StatelessWidget {
  final List<Book> booksDetail;
  final String heading;

  const BookSection({
    super.key,
    required this.booksDetail,
    required this.heading,
  });

  @override
  Widget build(BuildContext context) {
    final books = booksDetail.take(6).toList(); // 🔑 exactly 6

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                heading,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all trending
                },
                child: const Text('See all'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Horizontal list
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final book = books[index];
              return BookCard(
                book: book,
                onTap: () {
                  // Go to book details (full screen)
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
