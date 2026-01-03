import 'package:flutter/material.dart';
import 'package:libraryapp/core/widgets/book_view.dart';
import 'package:libraryapp/core/widgets/borrowed_card.dart';
import 'package:libraryapp/data/mock_books.dart';

class Borrowed extends StatefulWidget {
  const Borrowed({super.key});

  @override
  State<Borrowed> createState() => _BorrowedState();
}

class _BorrowedState extends State<Borrowed> {
  @override
  Widget build(BuildContext context) {
    // Mocking borrowed books by taking a subset
    final borrowedBooks = mockBooks.sublist(0, 5);

    return Scaffold(
      appBar: AppBar(title: const Text("Borrowed Books")),
      body: ListView.builder(
        itemCount: borrowedBooks.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final book = borrowedBooks[index];
          return BorrowedCard(
            book: book,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookView(id: mockBooks.indexOf(book)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
