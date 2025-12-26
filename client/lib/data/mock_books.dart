import 'package:libraryapp/models/book.dart';

final mockBooks = <Book>[
  Book(
    id: 'b1',
    title: 'Clean Code',
    category: 'Programming',
    publicationYear: 2008,
    copiesOwned: 3,
    image: 'client/assets/book/book_cover.webp',
  ),
  Book(
    id: 'b2',
    title: 'Flutter in Action',
    category: 'Programming',
    publicationYear: 2019,
    copiesOwned: 2,
    image: 'client/assets/book/book_cover.webp',
  ),
  Book(
    id: 'b3',
    title: 'Sapiens',
    category: 'History',
    publicationYear: 2011,
    copiesOwned: 4,
    image: 'client/assets/book/book_cover.webp',
  ),
  Book(
    id: 'b4',
    title: 'A Brief History of Time',
    category: 'Science',
    publicationYear: 1988,
    copiesOwned: 1,
    image: 'client/assets/book/book_cover.webp',
  ),
  Book(
    id: 'b5',
    title: 'The Alchemist',
    category: 'Fiction',
    publicationYear: 1988,
    copiesOwned: 5,
    image: 'client/assets/book/book_cover.webp',
  ),
];
