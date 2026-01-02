import 'package:libraryapp/models/book.dart';

final mockBooks = <Book>[
  Book(
    id: 'b1',
    title: 'Clean Code',
    author: 'Robert C. Martin',
    category: 'Programming',
    description:
        'Even bad code can function. But if code isn\'t clean, it can bring a development organization to its knees. Every year, countless hours and significant resources are lost because of poorly written code. But it doesn\'t have to be that way.',
    rating: 4.8,
    publicationYear: 2008,
    copiesOwned: 0,
    image: 'client/assets/book/book_cover.webp',
  ),
  Book(
    id: 'b2',
    title: 'Flutter in Action',
    author: 'Eric Windmill',
    category: 'Programming',
    description:
        'Flutter in Action teaches you to build professional-quality mobile applications using the Flutter SDK and the Dart programming language. You\'ll begin with a quick tour of Dart essentials and then dive into engaging, well-described techniques for building beautiful user interfaces using Flutter\'s huge collection of built-in widgets.',
    rating: 4.5,
    publicationYear: 2019,
    copiesOwned: 0,
    image: 'client/assets/book/book_cover.webp',
  ),
  Book(
    id: 'b3',
    title: 'Sapiens',
    author: 'Yuval Noah Harari',
    category: 'History',
    description:
        'From a renowned historian comes a groundbreaking narrative of humanity’s creation and evolution—a #1 international bestseller—that explores the ways in which biology and history have defined us and enhanced our understanding of what it means to be "human."',
    rating: 4.7,
    publicationYear: 2011,
    copiesOwned: 4,
    image: 'client/assets/book/book_cover.webp',
  ),
  Book(
    id: 'b4',
    title: 'A Brief History of Time',
    author: 'Stephen Hawking',
    category: 'Science',
    description:
        'A landmark volume in science writing by one of the great minds of our time, Stephen Hawking’s book explores such profound questions as: How did the universe begin—and what made its start possible? Does time always flow forward? Is the universe unending—or are there boundaries?',
    rating: 4.6,
    publicationYear: 1988,
    copiesOwned: 1,
    image: 'client/assets/book/book_cover.webp',
  ),
  Book(
    id: 'b5',
    title: 'The Alchemist',
    author: 'Paulo Coelho',
    category: 'Fiction',
    description:
        'Combining magic, mysticism, wisdom and wonder into an inspiring tale of self-discovery, The Alchemist has become a modern classic, selling millions of copies around the world and transforming the lives of countless readers across generations.',
    rating: 4.9,
    publicationYear: 1988,
    copiesOwned: 5,
    image: 'client/assets/book/book_cover.webp',
  ),
];
