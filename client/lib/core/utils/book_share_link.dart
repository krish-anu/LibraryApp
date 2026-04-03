import 'package:libraryapp/models/book.dart';

class BookShareLink {
  static const String scheme = 'libraryapp';
  static const String host = 'book';

  static Uri buildUri(Book book) {
    return Uri(
      scheme: scheme,
      host: host,
      queryParameters: {
        'id': book.id,
        'title': book.title,
        'author': book.author,
        'category': book.category,
        'description': book.description,
        'rating': book.rating.toString(),
        'publicationYear': book.publicationYear.toString(),
        'copiesOwned': book.copiesOwned.toString(),
        'image': book.image,
        'language': book.language,
        'pages': book.pages.toString(),
        'ratingCount': book.ratingCount.toString(),
      },
    );
  }

  static Book? parse(Uri uri) {
    if (uri.scheme != scheme || uri.host != host) {
      return null;
    }

    final params = uri.queryParameters;
    final title = params['title']?.trim() ?? '';
    if (title.isEmpty) {
      return null;
    }

    return Book(
      id: params['id']?.trim() ?? '',
      title: title,
      author: params['author']?.trim() ?? 'Unknown Author',
      category: params['category']?.trim() ?? '',
      description: params['description']?.trim() ?? 'No description available.',
      rating: double.tryParse(params['rating'] ?? '') ?? 0.0,
      publicationYear: int.tryParse(params['publicationYear'] ?? '') ?? 0,
      copiesOwned: int.tryParse(params['copiesOwned'] ?? '') ?? 0,
      image: params['image']?.trim() ?? '',
      language: params['language']?.trim() ?? 'English',
      pages: int.tryParse(params['pages'] ?? '') ?? 200,
      ratingCount: int.tryParse(params['ratingCount'] ?? '') ?? 0,
    );
  }

  static String buildShareText(Book book) {
    final link = buildUri(book).toString();
    return <String>[
      'Check out this book from XYZ Library!',
      '',
      'Title: ${book.title}',
      'Author: ${book.author}',
      'Category: ${book.category}',
      '',
      'Open in LibraryApp:',
      link,
    ].join('\n');
  }
}
