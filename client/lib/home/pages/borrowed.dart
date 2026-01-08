import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/widgets/book_view.dart';
import 'package:libraryapp/core/widgets/borrowed_card.dart';
import 'package:libraryapp/data/repository/book_repository.dart';
import 'package:libraryapp/data/repository/loan_repository.dart';

class Borrowed extends ConsumerWidget {
  const Borrowed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both providers
    final loansAsync = ref.watch(fetchAllLoansProvider);
    final booksAsync = ref.watch(fetchAllBooksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Borrowed Books")),
      body: loansAsync.when(
        data: (loans) {
          // If loans are loaded, we check if books are loaded
          return booksAsync.when(
            data: (books) {
              // Join loans with books
              return ListView.builder(
                itemCount: loans.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final loan = loans[index];
                  // Find the book, if it exists
                  final book = books.firstWhere(
                    (b) => b.id == loan.bookId,
                    orElse: () => books.first, // Fallback if not found
                  );
                  final dueDate = loan.loanDate.add(const Duration(days: 14));

                  return BorrowedCard(
                    book: book,
                    dueDate: dueDate,
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
              );
            },
            error: (err, stack) =>
                Center(child: Text('Error loading books: $err')),
            loading: () => const Center(child: CircularProgressIndicator()),
          );
        },
        error: (err, stack) => Center(child: Text('Error loading loans: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
