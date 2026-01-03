import 'package:flutter/material.dart';
import 'package:libraryapp/core/widgets/book_view.dart';
import 'package:libraryapp/core/widgets/borrowed_card.dart';
import 'package:libraryapp/data/mock_books.dart';
import 'package:libraryapp/data/mock_loans.dart';

class Borrowed extends StatefulWidget {
  const Borrowed({super.key});

  @override
  State<Borrowed> createState() => _BorrowedState();
}

class _BorrowedState extends State<Borrowed> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Borrowed Books")),
      body: ListView.builder(
        itemCount: mockLoans.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final loan = mockLoans[index];
          final book = mockBooks.firstWhere((b) => b.id == loan.bookId);
          final dueDate = loan.loanDate.add(const Duration(days: 14));

          return BorrowedCard(
            book: book,
            dueDate: dueDate,
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
