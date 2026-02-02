import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/book_view.dart';
import 'package:libraryapp/core/widgets/see_all.dart';
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
    final books = booksDetail.take(6).toList();
    final allBooks = booksDetail;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with See all button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              heading,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Pallete.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeeAll(bookDetail: allBooks),
                  ),
                );
              },
              child: Text(
                'See all',
                style: TextStyle(
                  color: Pallete.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Horizontal list
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final book = books[index];
              return BookCard(
                book: book,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookView(book: book),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
