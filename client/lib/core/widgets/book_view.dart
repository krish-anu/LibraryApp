import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/book_view/book_view_app_bar.dart';
import 'package:libraryapp/core/widgets/book_view/book_cover_section.dart';
import 'package:libraryapp/core/widgets/book_view/book_info_section.dart';
import 'package:libraryapp/core/widgets/book_view/category_chips.dart';
import 'package:libraryapp/core/widgets/book_view/action_buttons.dart';
import 'package:libraryapp/core/widgets/book_view/summary_section.dart';
import 'package:libraryapp/core/widgets/book_view/borrow_confirmation_sheet.dart';
import 'package:libraryapp/models/book.dart';

/// Displays detailed information about a book.
class BookView extends StatelessWidget {
  final Book book;

  const BookView({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final isAvailable = book.copiesOwned > 0;

    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: BookViewAppBar(title: book.title),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCoverSection(imageUrl: book.image, isAvailable: isAvailable),
            BookInfoSection(
              title: book.title,
              author: book.author,
              rating: book.rating,
            ),
            const SizedBox(height: 20),
            CategoryChips(category: book.category),
            const SizedBox(height: 20),
            const ActionButtons(),
            const SizedBox(height: 24),
            SummarySection(
              description: book.description,
              isAvailable: isAvailable,
              onBorrowPressed: () => _showBorrowConfirmation(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showBorrowConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BorrowConfirmationSheet(book: book),
    );
  }
}
