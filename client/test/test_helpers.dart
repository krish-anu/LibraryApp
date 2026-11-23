import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/models/book.dart';

Book sampleBook({
  String id = 'book-1',
  String title = 'Clean Code',
  String author = 'Robert C. Martin',
  String category = 'Technology',
  String description = 'A guide to writing maintainable software.',
  double rating = 4.8,
  int publicationYear = 2008,
  int copiesOwned = 2,
  int ratingCount = 120,
}) {
  return Book(
    id: id,
    title: title,
    author: author,
    category: category,
    description: description,
    rating: rating,
    publicationYear: publicationYear,
    copiesOwned: copiesOwned,
    image: 'assets/book/book_cover.webp',
    language: 'English',
    pages: 464,
    ratingCount: ratingCount,
  );
}

Widget testApp(Widget child) {
  return ProviderScope(child: MaterialApp(home: child));
}
