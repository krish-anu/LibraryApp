import 'package:flutter_test/flutter_test.dart';
import 'package:libraryapp/models/book.dart';

void main() {
  test('Book copyWith preserves unchanged fields', () {
    final book = Book(
      id: 'b1',
      title: 'Original',
      author: 'Author',
      category: 'Tech',
      description: 'Description',
      rating: 4,
      publicationYear: 2024,
      copiesOwned: 2,
      image: '',
    );

    final updated = book.copyWith(title: 'Updated');

    expect(updated.title, 'Updated');
    expect(updated.author, 'Author');
    expect(updated.copiesOwned, 2);
  });
}
